# build plugin jar
FROM maven:3.8.6-openjdk-8 as datasourcePlugin
WORKDIR  /home/nacos
ENV PLUGIN_HOME=/home/nacos/plugins
ENV PLUGIN_EXT_BASE_HOME=nacos-datasource-plugin-ext
ARG DATASOURCE_PLUGIN
ADD . .
RUN mkdir $PLUGIN_HOME; \
    cp ./${PLUGIN_EXT_BASE_HOME}/${DATASOURCE_PLUGIN}/target/${DATASOURCE_PLUGIN}*.jar ${PLUGIN_HOME}/${DATASOURCE_PLUGIN}.jar

# build Nacos
FROM alpine:latest
LABEL maintainer="fuhouyu <fuhouyu@live.cn>"
LABEL version="$NACOS_VERSION"
LABEL description="Nacos Multiple Datasource"
RUN apk add --no-cache openjdk8-jre-base curl iputils ncurses vim libcurl
ARG NACOS_VERSION=2.4.2
ARG DATASOURCE_PLUGIN
COPY --from=datasourcePlugin /home/nacos/plugins/${DATASOURCE_PLUGIN}.jar /home/nacos/plugins/${DATASOURCE_PLUGIN}.jar
ENV DOWNLOAD_URL="https://github.com/alibaba/nacos/releases/download/${NACOS_VERSION}/nacos-server-${NACOS_VERSION}.tar.gz"
# set environment
ENV MODE="cluster" \
    PREFER_HOST_MODE="ip"\
    BASE_DIR="/home/nacos" \
    CLASSPATH=".:/home/nacos/conf:$CLASSPATH" \
    CLUSTER_CONF="/home/nacos/conf/cluster.conf" \
    FUNCTION_MODE="all" \
    JAVA_HOME="/usr/lib/jvm/java-1.8-openjdk" \
    NACOS_USER="nacos" \
    JAVA="/usr/lib/jvm/java-1.8-openjdk/bin/java" \
    JVM_XMS="1g" \
    JVM_XMX="1g" \
    JVM_XMN="512m" \
    JVM_MS="128m" \
    JVM_MMS="320m" \
    NACOS_DEBUG="n" \
    TOMCAT_ACCESSLOG_ENABLED="false" \
    TIME_ZONE="Asia/Shanghai"
WORKDIR $BASE_DIR
RUN \
    # 软件源配置
    sed -i 's#dl-cdn.alpinelinux.org#mirrors.aliyun.com#g' /etc/apk/repositories; \
    apt update -y && apt install -y wget;\
    ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone;
RUN wget $DOWNLOAD_URL -O nacos-server.tar.gz && tar -xvf nacos-server.tar.gz --strip-components=1 -C ./ && rm -rf *.gz;
RUN mkdir -p logs 	&& touch logs/start.out 	&& ln -sf /dev/stdout start.out 	&& ln -sf /dev/stderr start.out

ADD build/datasource/conf/application.properties conf/application.properties
ADD build/datasource/bin/docker-startup.sh bin/docker-startup.sh
RUN chmod +x bin/docker-startup.sh
EXPOSE 8848
ENTRYPOINT ["sh","bin/docker-startup.sh"]

