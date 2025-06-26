#!/bin/sh
set -x

export CUSTOM_SEARCH_NAMES="application"
export CUSTOM_SEARCH_LOCATIONS=file:${BASE_DIR}/conf/
export MEMBER_LIST="$MEMBER_LIST"
PLUGINS_DIR="/home/nacos/plugins/peer-finder"

print_servers() {
  if [ ! -d "${PLUGINS_DIR}" ]; then
    echo "" >"$CLUSTER_CONF"
    for server in ${NACOS_SERVERS}; do
      echo "$server" >>"$CLUSTER_CONF"
    done
  else
    sh $PLUGINS_DIR/plugin.sh
    sleep 30
  fi
}

join_if_exist() {
  if [ -n "$2" ]; then
    echo "$1$2"
  else
    echo ""
  fi
}

# JVM 配置
Xms=$(join_if_exist "-Xms" "${JVM_XMS}")
Xmx=$(join_if_exist "-Xmx" "${JVM_XMX}")
Xmn=$(join_if_exist "-Xmn" "${JVM_XMN}")
XX_MS=$(join_if_exist "-XX:MetaspaceSize=" "${JVM_MS}")
XX_MMS=$(join_if_exist "-XX:MaxMetaspaceSize=" "${JVM_MMS}")

JAVA_OPT=""

if [ "${MODE}" = "standalone" ]; then
  JAVA_OPT="$JAVA_OPT $Xms $Xmx $Xmn"
  JAVA_OPT="$JAVA_OPT -Dnacos.standalone=true"
else
  if [ "${EMBEDDED_STORAGE}" = "embedded" ]; then
    JAVA_OPT="$JAVA_OPT -DembeddedStorage=true"
  fi
  JAVA_OPT="$JAVA_OPT -server $Xms $Xmx $Xmn $XX_MS $XX_MMS"
  if [ "${NACOS_DEBUG}" = "y" ]; then
    JAVA_OPT="$JAVA_OPT -Xdebug -Xrunjdwp:transport=dt_socket,address=9555,server=y,suspend=n"
  fi
  JAVA_OPT="$JAVA_OPT -XX:-OmitStackTraceInFastThrow -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${BASE_DIR}/logs/java_heapdump.hprof"
  JAVA_OPT="$JAVA_OPT -XX:-UseLargePages"
  print_servers
fi

# 设置系统属性
if [ "${FUNCTION_MODE}" = "config" ]; then
  JAVA_OPT="$JAVA_OPT -Dnacos.functionMode=config"
elif [ "${FUNCTION_MODE}" = "naming" ]; then
  JAVA_OPT="$JAVA_OPT -Dnacos.functionMode=naming"
fi

[ -n "${NACOS_SERVER_IP}" ] && JAVA_OPT="$JAVA_OPT -Dnacos.server.ip=${NACOS_SERVER_IP}"
[ -n "${USE_ONLY_SITE_INTERFACES}" ] && JAVA_OPT="$JAVA_OPT -Dnacos.inetutils.use-only-site-local-interfaces=${USE_ONLY_SITE_INTERFACES}"
[ -n "${PREFERRED_NETWORKS}" ] && JAVA_OPT="$JAVA_OPT -Dnacos.inetutils.preferred-networks=${PREFERRED_NETWORKS}"
[ -n "${IGNORED_INTERFACES}" ] && JAVA_OPT="$JAVA_OPT -Dnacos.inetutils.ignored-interfaces=${IGNORED_INTERFACES}"
[ -n "${NACOS_AUTH_ENABLE}" ] && JAVA_OPT="$JAVA_OPT -Dnacos.core.auth.enabled=${NACOS_AUTH_ENABLE}"
[ -n "${NACOS_AUTH_ADMIN_ENABLE}" ] && JAVA_OPT="$JAVA_OPT -Dnacos.core.auth.admin.enabled=${NACOS_AUTH_ADMIN_ENABLE}"
[ -n "${NACOS_AUTH_CONSOLE_ENABLE}" ] && JAVA_OPT="$JAVA_OPT -Dnacos.core.auth.console.enabled=${NACOS_AUTH_CONSOLE_ENABLE}"

if [ -z "${NACOS_AUTH_TOKEN}" ]; then
  echo "env NACOS_AUTH_TOKEN must be set with Base64 String."
  exit 255
fi

if [ -z "${NACOS_AUTH_IDENTITY_KEY}" ]; then
  echo "env NACOS_AUTH_IDENTITY_KEY must be set."
  exit 255
fi

if [ -z "${NACOS_AUTH_IDENTITY_VALUE}" ]; then
  echo "env NACOS_AUTH_IDENTITY_VALUE must be set."
  exit 255
fi

if [ "${PREFER_HOST_MODE}" = "hostname" ]; then
  JAVA_OPT="$JAVA_OPT -Dnacos.preferHostnameOverIp=true"
fi

JAVA_OPT="$JAVA_OPT -Dnacos.member.list=${MEMBER_LIST}"

[ -n "${NACOS_DEPLOYMENT_TYPE}" ] && JAVA_OPT="$JAVA_OPT -Dnacos.deployment.type=${NACOS_DEPLOYMENT_TYPE}"

JAVA_MAJOR_VERSION=$($JAVA -version 2>&1 | sed -E -n 's/.* version "([0-9]*).*$/\1/p')

if [ "$JAVA_MAJOR_VERSION" -ge "9" ]; then
  JAVA_OPT="$JAVA_OPT -Xlog:gc*:file=${BASE_DIR}/logs/nacos_gc.log:time,tags:filecount=10,filesize=102400"
else
  JAVA_OPT="$JAVA_OPT -XX:+UseConcMarkSweepGC -XX:+UseCMSCompactAtFullCollection -XX:CMSInitiatingOccupancyFraction=70"
  JAVA_OPT="$JAVA_OPT -XX:+CMSParallelRemarkEnabled -XX:SoftRefLRUPolicyMSPerMB=0 -XX:+CMSClassUnloadingEnabled -XX:SurvivorRatio=8"
  JAVA_OPT_EXT_FIX="-Djava.ext.dirs=${JAVA_HOME}/jre/lib/ext:${JAVA_HOME}/lib/ext"
  JAVA_OPT="$JAVA_OPT -Xloggc:${BASE_DIR}/logs/nacos_gc.log -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=100M"
fi

JAVA_OPT="$JAVA_OPT -Dloader.path=${BASE_DIR}/plugins,${BASE_DIR}/plugins/health,${BASE_DIR}/plugins/cmdb,${BASE_DIR}/plugins/selector"
JAVA_OPT="$JAVA_OPT -Dnacos.home=${BASE_DIR}"
JAVA_OPT="$JAVA_OPT -jar ${BASE_DIR}/target/nacos-server.jar"
JAVA_OPT="$JAVA_OPT ${JAVA_OPT_EXT}"
JAVA_OPT="$JAVA_OPT --spring.config.additional-location=${CUSTOM_SEARCH_LOCATIONS}"
JAVA_OPT="$JAVA_OPT --spring.config.name=${CUSTOM_SEARCH_NAMES}"
JAVA_OPT="$JAVA_OPT --logging.config=${BASE_DIR}/conf/nacos-logback.xml"
JAVA_OPT="$JAVA_OPT --server.max-http-header-size=524288"

echo "Nacos is starting, you can docker logs your container"
exec $JAVA $JAVA_OPT
