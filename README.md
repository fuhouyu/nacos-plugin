# nacos-plugin
A collection of Nacos plug-ins that provide pluggable plug-in capabilities for Nacos and support user customization and high scalability

---
# 简介
该仓库从[nacos-plugin](https://github.com/nacos-group/nacos-plugin) fork，主要为了处理数据源的适配。
### 版本
2.5.1

### 镜像地址
已构建好的docker镜像：[nacos-server-multiple-datasource](https://hub.docker.com/r/fuhouyu/nacos-server)
#### 部署方式
##### docker
```docker
docker run -it --name nacos-quick \
-e MODE=standalone \
-e NACOS_AUTH_IDENTITY_KEY="d90ee0d2ef5e452f80c00514c7f30c3e" \
-e NACOS_AUTH_IDENTITY_VALUE="4a7397d7085945d3adcdcaec264abf90" \
-e NACOS_AUTH_TOKEN="N2YyYWZiODJkNWE1NDllNzljODNjYmQ5ZDBlODE3M2Q=" \
-e SPRING_DATASOURCE_PLATFORM="postgres" \
-e DB_URL="jdbc:postgresql://${ip}:${port}/${database}" \
-e DB_USER="${database_username}" \
-e DB_PASSWORD="${database_password}" \
-e NACOS_AUTH_ENABLE="true" \
-e DRIVER_CLASS_NAME="org.postgresql.Driver" \
-p 8848:8848 \
-p 9848:9848 \
-p 9999:9999 \
-d fuhouyu/nacos-server:2.5.1-postgresql
```
##### docker-compose
```yaml
services:
  nacos:
    image: ${NACOS_TAG}
    container_name: nacos-quick
    environment:
      NACOS_AUTH_IDENTITY_KEY: "d90ee0d2ef5e452f80c00514c7f30c3e"
      NACOS_AUTH_IDENTITY_VALUE: "4a7397d7085945d3adcdcaec264abf90"
      NACOS_AUTH_TOKEN: "N2YyYWZiODJkNWE1NDllNzljODNjYmQ5ZDBlODE3M2Q="
      SPRING_DATASOURCE_PLATFORM: postgresql
      DB_URL: "jdbc:postgresql://${ip}:${port}/${database}"
      DB_USER: ${database_username}
      DB_PASSWORD: ${database_password}
      NACOS_AUTH_ENABLE: "true"
      DRIVER_CLASS_NAME: "org.postgresql.Driver"
    ports:
      - "8848:8848"
      - "9848:9848"
      - "9999:9999"
    deploy:
      mode: replicated
      replicas: 1
```
##### kubernetes

```yaml
# 提供外部使用
apiVersion: v1
kind: Service
metadata:
  name: nacos-nodeport
  namespace: default
  labels:
    app: nacos-headless
spec:
  type: NodePort
  # 根据需要暴露port
  ports:
    - port: 8848
      name: server
      targetPort: 8848
      nodePort: 30048
    - port: 9848
      name: client-rpc
      targetPort: 9848
      nodePort: 31048
  selector:
    app: nacos
---
# 无头服务，提供容器内部使用
apiVersion: v1
kind: Service
metadata:
  name: nacos-headless
  namespace: default
  labels:
    app: nacos-headless
spec:
  type: ClusterIP
  clusterIP: None
  ports:
    - port: 8848
      name: server
      targetPort: 8848
    - port: 9848
      name: client-rpc
      targetPort: 9848
    - port: 9849
      name: raft-grpc
      targetPort: 9849
    - port: 7848
      name: raft-rpc
      targetPort: 7848
  selector:
    app: nacos
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nacos-cm
  namespace: default
data:
  # 这里修改jdbc数据源配置
  db.url: "jdbc:postgresql://ip/port"
  db.username: "nacos"
  db.password: "nacos"
  db.driver.name: "org.postgresql.Driver"

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nacos
  namespace: default
spec:
  serviceName: nacos-headless
  # Nacos 集群，默认3节点
  replicas: 3
  template:
    metadata:
      labels:
        app: nacos
      annotations:
        pod.alpha.kubernetes.io/initialized: "true"
    spec:
      containers:
        - name: nacos
          imagePullPolicy: Always
          image: fuhouyu/nacos-server-multiple-datasource:2.5.1-postgresql
          # 根据需要修改
          resources:
            requests:
              memory: "2048Mi"
              cpu: "1024m"
            limits:
              memory: "2048Mi"
              cpu: "1024m"
          env:
            # Nacos 副本数
            - name: NACOS_REPLICAS
              value: "3"
            - name: DB_URL
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: db.url
            - name: DB_USER
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: db.username
            - name: DB_PASSWORD
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: db.password
            - name: DRIVER_CLASS_NAME
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: db.driver.name
            - name: MODE
              value: "cluster"
            - name: NACOS_SERVER_PORT
              value: "8848"
            - name: PREFER_HOST_MODE
              value: "hostname"
            - name: nacos.naming.data.warmup
              value: "false"
            - name: NACOS_SERVERS
              value: "nacos-0.nacos-headless.default.svc.cluster.local:8848,nacos-1.nacos-headless.default.svc.cluster.local:8848,nacos-2.nacos-headless.default.svc.cluster.local:8848"
            - name: NACOS_AUTH_TOKEN
              value: NkQzNUUwMjlCOTdGNDk4Mjg2QTJEN0E4RDYzM0EyMzE=
            - name: NACOS_AUTH_IDENTITY_KEY
              value: AE84C5193B6C44728C76AEB73D1A3037
            - name: NACOS_AUTH_IDENTITY_VALUE
              value: D3D2F9F96E58435E802FC34017722057
            - name: SPRING_DATASOURCE_PLATFORM
              value: "postgresql"
            - name: NACOS_AUTH_ENABLE
              value: "true"
  selector:
    matchLabels:
      app: nacos
```
### 构建方式
自dockerfile中进行构建：
```shell
mvn clean install -DskipTests
export DATASOURCE_TYPE=postgresql
export TAG=test:2.5.1
docker buildx build  --platform linux/amd64,linux/arm64 --build-arg DATASOURCE_PLUGIN=nacos-${DATASOURCE_TYPE}-datasource-plugin-ext -t ${TAG} -f build/datasource/datasource-plugin-ext.Dockerfile . --push
```



