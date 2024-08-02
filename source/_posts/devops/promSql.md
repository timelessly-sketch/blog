---
title: Promethus监控系统(二)
date: 2023-02-19 15:16:27
tags: [Promethus, DevOps]
banner_img: /img/index.png
index_img: /img/promethus_index.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - DevOps
---

通过`Promethus`监控`kubernetes`集群资源信息，`PromQL`、`alertmanager`、`grafana`基本使用等

## 1. 监控kuerntes集群

当部署了`metrics-server`、`cadvisor`(集成在`kubelet`内)监控指标基本都已经能拿到，但是这些都是在应用内部，需要在应用提供or开启/`metrics`接口，或者部署`exports`来暴漏对应的指标，但是对于`deployment`，`Pod`、`daemonset`、 `cronjob`等k8s资源对象并没有监控，因此就需引用新的`exports`来暴漏监控指标，`kube-state-metrics`。

### 1.1 部署kube-state-metrics

首先需要准备一个完整的`kubernetes`集群，并且能够对外提供服务，在安装`kube-state-metrics`服务。

```yaml
# 1. 创建rbac, 让kube-state-metrics能够去读集群相关信息
[root@xwhs ~]# cat kube-state-metrics-rbac.yaml  # 创建在default命名空间，可以安需修改
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/name: kube-state-metrics
    app.kubernetes.io/version: 1.9.7
  name: kube-state-metrics
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    app.kubernetes.io/name: kube-state-metrics
    app.kubernetes.io/version: 1.9.7
  name: kube-state-metrics
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - secrets
  - nodes
  - pods
  - services
  - resourcequotas
  - replicationcontrollers
  - limitranges
  - persistentvolumeclaims
  - persistentvolumes
  - namespaces
  - endpoints
  verbs:
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  - ingresses
  verbs:
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - statefulsets
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - cronjobs
  - jobs
  verbs:
  - list
  - watch
- apiGroups:
  - autoscaling
  resources:
  - horizontalpodautoscalers
  verbs:
  - list
  - watch
- apiGroups:
  - authentication.k8s.io
  resources:
  - tokenreviews
  verbs:
  - create
- apiGroups:
  - authorization.k8s.io
  resources:
  - subjectaccessreviews
  verbs:
  - create
- apiGroups:
  - policy
  resources:
  - poddisruptionbudgets
  verbs:
  - list
  - watch
- apiGroups:
  - certificates.k8s.io
  resources:
  - certificatesigningrequests
  verbs:
  - list
  - watch
- apiGroups:
  - storage.k8s.io
  resources:
  - storageclasses
  - volumeattachments
  verbs:
  - list
  - watch
- apiGroups:
  - admissionregistration.k8s.io
  resources:
  - mutatingwebhookconfigurations
  - validatingwebhookconfigurations
  verbs:
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - networkpolicies
  verbs:
  - list
  - watch
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app.kubernetes.io/name: kube-state-metrics
    app.kubernetes.io/version: 1.9.7
  name: kube-state-metrics
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kube-state-metrics
  namespace: default
```

```yaml
# 2. 配置kube-state-metric的deployment文件
[root@xwhs ~]# cat kube-state-metrics-dep.yaml  # 由于网络原因镜像可能无法拉起按需修改为镜像即可,确保容器正常运行
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: kube-state-metrics
    app.kubernetes.io/version: 1.9.7
  name: kube-state-metrics
  namespace: default
spec:
  #progressDeadlineSeconds: 600
  replicas: 1
  #revisionHistoryLimit: 10
  selector:
    matchLabels:
      app.kubernetes.io/name: kube-state-metrics
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app.kubernetes.io/name: kube-state-metrics
        app.kubernetes.io/version: 1.9.7
    spec:
      #affinity:
      #  nodeAffinity:
      #    requiredDuringSchedulingIgnoredDuringExecution:
      #      nodeSelectorTerms:
      #      - matchExpressions:
      #        - key: node-role.kubernetes.io/worker-addons
      #          operator: Exists
      containers:
      - image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.6.0
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 5
        name: kube-state-metrics
        ports:
        - containerPort: 8080
          name: http-metrics
          protocol: TCP
        - containerPort: 8081
          name: telemetry
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /
            port: 8081
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 5
        resources: {}
        securityContext:
          runAsUser: 65534
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: kube-state-metrics
      serviceAccountName: kube-state-metrics
      terminationGracePeriodSeconds: 30
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
```

```yaml
# 3. 配置kube-state-metric的svc
[root@xwhs ~]# cat kube-state-metrics-svc.yaml # 暴露 80 - > 8080 / 8081 - > 8081
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: kube-state-metrics
    app.kubernetes.io/version: 1.9.7
  name: kube-state-metrics
  namespace: default
spec:
  #clusterIP: None
  ports:
  - name: http-metrics
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: telemetry
    port: 8081
    protocol: TCP
    targetPort: 8081
  selector:
    app.kubernetes.io/name: kube-state-metrics
  sessionAffinity: None
  type: ClusterIP
```

```yaml
# 4. 配置ingress  
[root@xwhs ~]# cat kube-state-metrics-ingress.yaml 
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: 50m
  generation: 1
  name: kube-state-metrics
  namespace: default
spec:
  rules:
  - host: kube-state-metrics.k8s.io
    http:
      paths:
      - backend:
          serviceName: kube-state-metrics
          servicePort: 80
        path: /
status:
  loadBalancer:
    ingress:
```

如上操作时，需要注意自己的`kubrnetes`集群环境里面的服务版本是否与案例一致，按需修改调整即可，主要目的就是将`kube-state-metric`服务的8080和8081端口暴露给集群外访问。

```shell
# 手动调用/metrics接口 能返回数据参数即正常
[root@xwhs ~]# curl http://kube-state-metrics.k8s.io/metrics
# HELP default_http_backend_http_request_count_total Counter of HTTP requests made.
# TYPE default_http_backend_http_request_count_total counter
default_http_backend_http_request_count_total{proto="1.1"} 119461
# HELP default_http_backend_http_request_duration_milliseconds Histogram of the time (in milliseconds) each request took.
# TYPE default_http_backend_http_request_duration_milliseconds histogram
default_http_backend_http_request_duration_milliseconds_bucket{proto="1.1",le="0.001"} 28
default_http_backend_http_request_duration_milliseconds_bucket{proto="1.1",le="0.003"} 3823
```

### 1.2 配置Token与证书

在`promethus`通过`api_server`连接集群时需要配置`token`认证，步骤如下：

```shell
# 1. 创建sa，获取token
[root@xwhs ~]# kubectl  get sa kube-state-metrics-sa
NAME                    SECRETS   AGE
kube-state-metrics-sa   1         13s
[root@xwhs ~]# kubectl  get secrets  # 在创建sa之后自动生成secrets 在1.25之后不会自动生成需要自己创建
NAME                                TYPE                                  DATA   AGE
kube-state-metrics-sa-token-nvv2f   kubernetes.io/service-account-token   3      3m12s
[root@xwhs ~]# kubectl  describe secrets kube-state-metrics-sa-token-nvv2f 
Name:         kube-state-metrics-sa-token-nvv2f
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: kube-state-metrics-sa
              kubernetes.io/service-account.uid: 074c7edb-8605-4ed7-b8a7-0f6e33914f3a

Type:  kubernetes.io/service-account-token

Data
====
namespace:  7 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IjA1WFdtekowUXV3ZHJMRmY0TkdYVTcwQVJvN3UwRTBhMjNXbHBNRHpOUzAifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6Imt1YmUtc3RhdGUtbWV0cmljcy1zYS10b2tlbi1udnYyZiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJrdWJlLXN0YXRlLW1ldHJpY3Mtc2EiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiIwNzRjN2VkYi04NjA1LTRlZDctYjhhNy0wZjZlMzM5MTRmM2EiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6ZGVmYXVsdDprdWJlLXN0YXRlLW1ldHJpY3Mtc2EifQ.aMh1NjpGD-WdaVoqqtLMpyBZB8eYHRnYFWFmRdNuz4mQ2OWXuD4hFc49qYi2jADi0_NksmHVc5QYKzBOeYMs3T7Y1woXo94bH0licoFK4Knhvjl-CVw1mvKwbUEMD7HK3y7PtJ5mkf5q2WRum8fOVs0apexr2lqkkpY9rAPMwwY9Hu9DpzMcV_Q55TAChqc3i-sJfGAnaTZKLaoYAm7Sen0YUhxQThAhMCTdE5-PowaLZ0G9x1YiJ88vrIh_Cn7sWuWg3zcEfoNTNdkz5mgYTBKJbe13U_Gpe3HkxhGRiRT2IzS3jK_kUzkP14WvmktfI3rnOlvqijpQnXiLUDq4fQ
ca.crt:     1025 bytes

# 2. 为sa授权给于足够的权限 其实与上面kube-state-mertic操作类似
[root@xwhs ~]# kubectl  create clusterrolebinding kube-state-metrics-sa --clusterrole cluster-admin --serviceaccount default:kube-state-metrics-sa

# 3. 将token存放在prometheus目录中
[root@xwhs prometheus]# ll /opt/prometheus/token 
-rw-r--r--. 1 root root 957 23:52:20 2022-12-06 /opt/prometheus/token

# 3. 将/etc/kubernetes/pki/ca.crt下面的证书也放到prometheus目录中  token与ca要在同一个地方
[root@xwhs prometheus]# ll /opt/prometheus/ca.crt 
-rw-r--r--. 1 root root 1025 23:54:42 2022-12-06 /opt/prometheus/ca.crt
```

### 1.3 配置Prometheus文件

```yaml
# 修改如下prometheus文件，重启前通过promtools检测文件是否正确
 - job_name: kube-state-metrics-start
    kubernetes_sd_configs:
    - role: endpoints
      api_server: https://kube-shcs.cls-9gg4vvtg.ix:6443
      bearer_token_file: /home/worker/prometheus/token
      tls_config:
        insecure_skip_verify: true
    bearer_token_file: /home/worker/prometheus/token
    scheme: http
    relabel_configs:
    - source_labels: [__meta_kubernetes_service_label_k8s_app]
      separator: ;
      regex: kube-state-metrics-start
      replacement: $1
      action: keep
    - source_labels: [__meta_kubernetes_endpoint_port_name]
      separator: ;
      regex: http-metrics
      replacement: $1
      action: keep
    - source_labels: [__meta_kubernetes_namespace]
      separator: ;
      regex: (.*)
      target_label: namespace
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_pod_name]
      separator: ;
      regex: (.*)
      target_label: pod
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_service_name]
      separator: ;
      regex: (.*)
      target_label: service
      replacement: $1
      action: replace
    - source_labels: [__meta_kubernetes_service_name]
      separator: ;
      regex: (.*)
      target_label: job
      replacement: ${1}
      action: replace
    - source_labels: [__meta_kubernetes_service_label_k8s_app]
      separator: ;
      regex: (.+)
      target_label: job
      replacement: ${1}
      action: replace
    - separator: ;
      regex: (.*)
      target_label: endpoint
      replacement: http-metrics
      action: replace


  - job_name: 'kube-state-metrics-after'
    static_configs:
      - targets: ["kube-state-metrics.k8s.io"]
    metric_relabel_configs:
      - action: labelmap
      
# 注意： 
1. prometheus必须要和api_sever能够网络通信，端口可达
2. 如果在promethus web上无法看到该targets 多看日志
3. 如果无法查出指标 多半是网络代理错了
```

## 2. Relabel_config详解

在`kubernetes`集群中存在很多默认的指标，在采集推送到`prometheus`中时可以将指标进行替换和过滤，进而得到符合预期的指标。

`Relabeling`(重定义标签)，是在拉取(`scraping`)阶段前，修改`target`和它的`labels`；在每个`scrape_configs`可以定义多个重定义标签的步骤；重定义标签完成后，`__`开头的标签会被删除；重定义标签阶段,如果要临时存储值用于下一阶段的处理,使用`__tmp`开头的标签名,这种标签不会被Prometheus使用。

### 2.1 Relabel_action

```other
replace: 正则匹配源标签的值用来替换目标标签;如果有replacement,使用replacement替换目标标签;
keep: 如果正则没有匹配到源标签,删除targets 
drop: 正则匹配到源标签,删除targets
hashmod: 设置目标标签值为源标签值的hash值
labelmap: 正则匹配所有标签名; 将匹配的标签的值复制到由replacement提供的标签名
labeldrop: 正则匹配所有标签名;匹配则移除标签;
labelkeep: 正则匹配所有标签名;不匹配的标签会被移除;
```

### 2.2 标签替换演示

替换：

```json
# 配置文件
------------------------------------------------------------------------------------
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels: 
          userLabel1: value1
          userLabel2: value2
    relabel_configs:
    - source_labels: [userLabel1]  # //用userLabel1的值替换了userLabel2
      target_label:  userLabel2
      #默认action 是 'replace'  
------------------------------------------------------------------------------------
# 替换前
			"labels": {
				"instance": "localhost:9090",
				"job": "prometheus",
				"userLabel1": "value1",  //新增
				"userLabel2": "value2"  //新增
			},
------------------------------------------------------------------------------------
# 替换后
			"labels": {
				"instance": "localhost:9090",
				"job": "prometheus",
				"userLabel1": "value1",
				"userLabel2": "value1"  //用userLabel1的值替换了userLabel2
			},
```

```json
# 用userLabel1的部分值替换userLabel2
scrape_configs:
    ...
    relabel_configs:
    - source_labels: [userLabel1]
      regex: 'value([0-9]+)'
      target_label:  userLabel2
      replacement: '$1'
      action: replace
------------------------------------------------------------------------------------
# 替换后
			"labels": {
				"instance": "localhost:9090",
				"job": "prometheus",
				"userLabel1": "value1",
				"userLabel2": "1"
			},
```

删除匹配的标签：

```json
# 配置文件
scrape_configs:
    ...
    relabel_configs:
    - regex: userLabel1
      action: labeldrop
------------------------------------------------------------------------------------
# 删除后
			"labels": {
				"instance": "localhost:9090",
				"job": "prometheus",
				"userLabel2": "value2" //删除了userLabel1
			},
```

删除匹配的`Target`

```other
# 配置文件
scrape_configs:
    ...
    relabel_configs:
    - source_labels: [userLabel1] 
      action: drop
 ------------------------------------------------------------------------------------
```

去匹配的标签名生成新的标签：

```json
# 配置文件
scrape_configs:
    ...
    relabel_configs:
    - regex: user(.*)1
      action: labelmap
 ------------------------------------------------------------------------------------
 			"labels": {
				"Label": "value1", //新生成的标签
				"instance": "localhost:9090",
				"job": "prometheus",
				"userLabel1": "value1",
				"userLabel2": "value2"
			},
```

## 3. PromQL

### 3.1 指标

指标格式：指标名称{ 标签1='值1', 标签2='值2'} 采样值 @时间戳

```shell
# 查找 kube_pod_container_status_running 指标下， container = "yy" pod
kube_pod_container_status_running{container="yy"}
```

```shell
# 获取一段时间的值 区间向量
mongodb_memory{instance="10.x.6.24:9216"}[1m]
# 获取某一个时刻的值 瞬时向量  
# date -d  @1670170818.154 解码时间戳
mongodb_memory{instance="10.x.6.24:9216"}@1670257218.154
```

```shell
# 查看昨天一分钟的 区间向量 - 偏移量
mongodb_memory{instance="10.163.6.24:9216"}[1m]offset 1d
```

匹配器：

```shell
=~ 等于 !~ 不等于  后面接正则表达式
# 支持正则表达式
mongodb_memory{name =~ "xx.*"} # . 表示任意字符 * 表示出现出现0次或者多次 这里匹配xx开头的
```

```shell
# 系统存在很多的指标 但是这些指标共分为四类：
1. counter  只增加不降低 - > 系统运行时间、网卡接受数据包  一但重启 就清零了
2. gauge  仪表类数据 可增可减  多由于CPU、内存
```

### 3.2 函数

聚合函数：

```yaml
# sum 总和 /  min 最小值 / max 最大值 / avg 平均值		针对瞬时向量进行统计

sum(prometheus_http_requests_total{code !="200"})  # prometheus http 请求 code != 200

sum(node_network_receive_packets_total) by (device) # 统计相同device网卡的流量 不通网卡会依次列出来 without取by的相反值

count(mongodb_connections{state = "current"}) # count 汇总 当前 mongodb_connections 指标且符合标签的

topk(3,mongodb_connections{state = "current"}) # 取前三

bottomk(3,mongodb_connections {state = "current"}) # 倒数三

count_values("xx",mongodb_connections {state = "current"}) # 会将统计的数值 赋值给xx

node_filesystem_free_bytes{mountpoint ="/data1"} /1024/1024/1024 > 100  # 空闲磁盘 > 100G
```

标签函数：

```shell
# 原来的
prometheus_http_request_duration_seconds_sum{handler = "/metrics"}
# 查询结果
prometheus_http_request_duration_seconds_sum{handler="/metrics", instance="10.167.6.33:9090", job="prometheus"}

# 添加一个标签
label_join(prometheus_http_request_duration_seconds_sum{handler = "/metrics"},"url","-","instance","handler")
# 查询结果 新添加了一个标签
prometheus_http_request_duration_seconds_sum{handler="/metrics", instance="10.167.6.33:9090", job="prometheus", url="10.167.6.33:9090-/metrics"}

# 标签替换
prometheus_http_requests_total{handler="/metrics"}
# 查询结果
prometheus_http_requests_total{code="200", handler="/metrics", instance="10.167.6.33:9090", job="prometheus"}
# 开始替换  替换code  用instance对应的值 通过正则匹配 - > 用第一个 替换code $0取全部
label_replace(prometheus_http_requests_total{handler="/metrics"}, "code", "$1", "instance", "(.*):(.*)")
# 替换结果
prometheus_http_requests_total{code="10.167.6.33", handler="/metrics", instance="10.167.6.33:9090", job="prometheus"}
```

排序：

```shell
sort(prometheus_http_requests_total) # 升序
sort_desc(prometheus_http_requests_total)  # 降序
```

### 3.3 常用记录

```shell
# 一分钟的prometheus_http_requests_total指标的增长率
rate(prometheus_http_requests_total{code="200"}[1m]) 
rate(node_network_receive_bytes_total[1m])
```

## 4. 告警

当某个指标的采样值超过或者不满足某个阈值的时候，`prometheus`作为`alertmanager`的客户端在满足特定的条件后触发告警，`alertmanager`通过路由发送给不同的接收器(不同的告警方式：电话、邮件等)。

各种匹配条件定义在`prometheus`文件中的`rule`里面，通过`labels`的方式进行分发。

### 4.1 安装

```shell
# 1. 下载 解压 https://prometheus.io/download/#alertmanager
[root@xwhs alertmanager]# pwd
/opt/alertmanager
[root@xwhs alertmanager]# ll
total 55744
-rwxr-xr-x 1 3434 3434 31988661 Mar 25  2022 alertmanager   # 启动文件
-rw-r--r-- 1 3434 3434      356 Mar 25  2022 alertmanager.yml   # 配置文件
-rwxr-xr-x 1 3434 3434 25067944 Mar 25  2022 amtool
-rw-r--r-- 1 3434 3434    11357 Mar 25  2022 LICENSE
-rw-r--r-- 1 3434 3434      457 Mar 25  2022 NOTICE

# 2. 配置启动方式
[root@ylinyang alertmanager]# cat /usr/lib/systemd/system/alertmanager.service
[Unit]
Description=Daemon alertmanager
After=syslog.target systemd-sysctl.service network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/opt/alertmanager/alertmanager \
    --config.file=/opt/alertmanager/alertmanager.yml \
    --storage.path=/opt/alertmanager/data \
    --data.retention=120h \
    --web.external-url=http://192.168.0.115:9093 \
    --web.listen-address=0.0.0.0:9093
Restart=on-failure

# 3. 登录
http://192.168.0.115:9093/#/alerts

# 4. 整合prometheus与alertmanager, 修改prometheus配置文件，重启服务
# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
           - 192.168.0.115:9093
# 加载./rules/*.yml文件，默认读取间隔15s 全局定义evaluation_interval
rule_files:
    - "rules/*.yml"
```

### 4.2 配置rule规则

`prometheus`产生告警，而`alertmanager`发送告警

```shell
# 1. 配置规则
[root@xwhs prometheus]# cat rules/node.yml 
groups:
  - name: node                  # 名字任意
    rules:
    - alert: node               # 会产生一个alertmanagername的labels为node
      expr: up{instance=~".*:9100"} == 0   # 什么条件下产生告警  表达式
      for: 15s                          # 持续多长时间 才触发
      labels:
        Exporter: DOWN  # 为告警产生一条标签, 还内置一个标签为instance = "ip"  触发告警的IP
      annotations:      # 如下都可以使用变量 {{labels.变量}}
        description: "{{$labels.instance}} has been down for more than 5 minutes."
        summary: "Node down"
[root@ylinyang xwhs]# ./promtool check rules rules/*.yml

# 2. alerts状态
nactive -- 没有满足触发条件，告警为激活状态
pending -- 已经满足触发条件，但为满足持续的时间(for决定) 
firing -- 满足条件了，即出问题了，时长也达到了for决定的时间
```

### 4.3 告警信息

```shell
# 1. 各种接收器的配置方式
https://prometheus.io/docs/alerting/latest/configuration/#receiver

# 2. 分组
group_wait: 30s # 在组内等待所配置的时间，如果同组内，30秒内出现相同报警，在一个组内 出现。
group_interval: 5m # 相同的group发送告警通知的时间间隔
repeat_interval: 24h # 如果一个报警信息已经发送成功了，等待 repeat_interval 时间来重新发送

# 3. alertmanager.yml 
global:
  resolve_timeout: 5m
  http_config: {}
  smtp_hello: localhost
  smtp_require_tls: true
  pagerduty_url: https://events.pagerduty.com/v2/enqueue
  hipchat_api_url: https://api.hipchat.com/
  opsgenie_api_url: https://api.opsgenie.com/
  wechat_api_url: https://qyapi.weixin.qq.com/cgi-bin/
  victorops_api_url: https://alert.victorops.com/integrations/generic/20131114/alert/
route:
  receiver: xxx-alertmanager
  group_by:
  - job
  - severity
  - instance
  group_wait: 3m
  group_interval: 5m
  repeat_interval: 12h
  routes:
  - receiver: xxx-alertmanager
receivers:
- name: xxx-alertmanager
  webhook_configs:		# 自定义告警平台接口
  - send_resolved: true
    http_config: {}
    url: http://10.67.7.28/api/v1/pro_message1
templates: []
```

## 5. grafana

```shell
# 1. 下载 安装  https://grafana.com/grafana/download
[root@xwhs opt]# yum localinstall ./grafana-enterprise-9.3.1-1.x86_64.rpm # 可能设计部分依赖

# 2. 启动 
[root@xwhs opt]# systemctl start grafana-server  # 默认端口 3000 admin/admin

# 3. 配置数据源 grafana从哪里获取数据
齿轮 -> Data sources  —> Add data source

# 4. 创建dashboard
四个框 -> Dashboards -> New Folder 新建分类文件夹 -> 新建bashboards

# 5. 导入模版 可以选择ID或者下载在导入
下载之后，直接在Dashboards里面，选择右边New -> imports 导入即可

# 6. grafana的variables变量设置下拉框表格
```