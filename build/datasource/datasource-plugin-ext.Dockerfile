FROM alpine:latest AS datasource-plugin-base
WORKDIR  /home/nacos
ENV PLUGIN_HOME=/home/nacos/plugins
ENV PLUGIN_EXT_BASE_HOME=nacos-datasource-plugin-ext
ARG DATASOURCE_PLUGIN
ADD . .
RUN mkdir $PLUGIN_HOME; \
    cp ./${PLUGIN_EXT_BASE_HOME}/${DATASOURCE_PLUGIN}/target/${DATASOURCE_PLUGIN}*.jar ${PLUGIN_HOME}/${DATASOURCE_PLUGIN}.jar

# build Nacos
FROM alpine:latest
LABEL description="Nacos Datasource Plugin"
RUN apk add --no-cache openjdk17-jre curl iputils ncurses vim libcurl bash libstdc++
ENV PLUGIN_HOME=/home/nacos/plugins
ENV PLUGIN_EXT_BASE_HOME=nacos-datasource-plugin-ext
ARG DATASOURCE_PLUGIN
ARG NACOS_VERSION=3.0.1
ARG DATASOURCE_PLUGIN
ENV DOWNLOAD_URL="https://github.com/alibaba/nacos/releases/download/${NACOS_VERSION}/nacos-server-${NACOS_VERSION}.tar.gz"
# set environment
ENV MODE="cluster" \
    PREFER_HOST_MODE="ip"\
    BASE_DIR="/home/nacos" \
    CLASSPATH=".:/home/nacos/conf:$CLASSPATH" \
    CLUSTER_CONF="/home/nacos/conf/cluster.conf" \
    FUNCTION_MODE="all" \
    JAVA_HOME="/usr/lib/jvm/java-17-openjdk" \
    NACOS_USER="nacos" \
    JAVA="/usr/lib/jvm/java-17-openjdk/bin/java" \
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
    ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone; \
    curl -SL $DOWNLOAD_URL -o nacos-server.tar.gz && tar -xvf nacos-server.tar.gz --strip-components=1 -C ./ && rm -rf *.gz; \
    mkdir -p logs 	&& touch logs/start.out 	&& ln -sf /dev/stdout start.out 	&& ln -sf /dev/stderr start.out
COPY --from=datasource-plugin-base $BASE_DIR/plugins/${DATASOURCE_PLUGIN}.jar $BASE_DIR/plugins/${DATASOURCE_PLUGIN}.jar
COPY build/datasource/conf/application.properties conf/application.properties
COPY build/datasource/bin/docker-startup.sh bin/docker-startup.sh
RUN chmod +x bin/docker-startup.sh
EXPOSE 8848
ENTRYPOINT ["sh","bin/docker-startup.sh"]

