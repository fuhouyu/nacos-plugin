# nacos-plugin
A collection of Nacos plug-ins that provide pluggable plug-in capabilities for Nacos and support user customization and high scalability

---
# 简介
该仓库从[nacos-plugin](https://github.com/nacos-group/nacos-plugin) fork，主要为了处理数据源的适配。

已构建好的docker镜像：[nacos-server-multiple-datasource](https://hub.docker.com/r/fuhouyu/nacos-server)

自dockerfile中进行构建：

```shell
mvn clean install -DskipTests
export DATASOURCE_TYPE=postgresql
export TAG=test:0.0.1
docker buildx build  --platform linux/amd64,linux/arm64 --build-arg DATASOURCE_PLUGIN=nacos-${DATASOURCE_TYPE}-datasource-plugin-ext -t ${TAG} -f datasource-plugin-ext.Dockerfile . --push
```



