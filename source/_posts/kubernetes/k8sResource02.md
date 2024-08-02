---
title: Kubernetes基础资源(二)
date: 2023-02-19 15:53:13
tags: [Kubernetes, DevOps]
banner_img: /img/index.png
index_img: /img/kubernetes01.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Kubernets系列
---

## 1. deployment

```shell
[root@k8s-master ~]# kubectl create deploy web1 --image=nginx --dry-run=client  -o yaml  # 创建deploy
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: web1		# deploy通过这边标签去匹配pod 如果上下标签不匹配，老头找不到羊
  name: web1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web1
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: web1		# 这个就是老头的羊
    spec:
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}
```

```shell
[root@k8s-master ~]# kubectl scale deployment web --replicas=2    # 调整副本数
deployment.apps/web scaled
```


## 2. svc

```shell
# 在集群内部是可以直接访问pod svc的IP地址的 不行就检查内核配置
# svc会创建endpoints
~/k8s/yaml » k get po -o wide                                                                                                                                   
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE             NOMINATED NODE   READINESS GATES
nginx-6799fc88d8-j7qbs   1/1     Running   0          14m   10.1.1.107   docker-desktop   <none>           <none>
nginx-6799fc88d8-kf856   1/1     Running   0          14m   10.1.1.106   docker-desktop   <none>           <none>


~ » k get svc -o wide            
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE     SELECTOR
nginx        ClusterIP   10.105.206.197   <none>        80/TCP    2m12s   app=nginx

~/k8s/yaml » k get ep                                                                                                                                           
NAME         ENDPOINTS                     AGE
kubernetes   192.168.100.4:6443            15d
nginx        10.1.1.106:80,10.1.1.107:80   21s
```

```shell
~ » k describe svc nginx                                                                                                                                    1 ↵ yanfeiyang@ylinx
Name:              nginx
Namespace:         default
Labels:            app=nginx    
Annotations:       <none>
Selector:          app=nginx		# svc与pod的对应关系去查找的 根据svc的pod去查找对应的pod k get pod -l app=nginx
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.105.206.197
IPs:               10.105.206.197
Port:              80-80  80/TCP
TargetPort:        80/TCP
Endpoints:         10.1.0.14:80,10.1.0.15:80
Session Affinity:  None
Events:            <none>
```

```shell
# svc定位pod 单纯通过 labels
# deploy 定位 pod 通过 labels 但是他有隐藏的labels

~ » k get pods --show-labels                                                                                                                                    yanfeiyang@ylinx
NAME                    READY   STATUS    RESTARTS      AGE   LABELS
nginx-8f458dc5b-d8jcp   1/1     Running   1 (21m ago)   11h   app=nginx,pod-template-hash=8f458dc5b
nginx-8f458dc5b-psxv6   1/1     Running   1 (21m ago)   11h   app=nginx,pod-template-hash=8f458dc5b
```

```shell
# 跨命名空间访问svc时，需要添加svc.命名空间
```

## 3. 服务发现

```shell
# 服务发现的三种方式
1. cluster ip 
2. 变量的方式  svc服务名_SERVICE_HOST  在pod引用的时候：$(X_SERVICE_HOST)
3. dns方式   一般都是这个只写服务名, dns 查询服务具有ns概念，只能查询当前ns的内容

~ » k get pod -A |grep dns                                                                                                                                  1 ↵ yanfeiyang@ylinx
kube-system   coredns-6d4b75cb6d-cwrn6                 1/1     Running   2 (93m ago)      13h
kube-system   coredns-6d4b75cb6d-zgpnd                 1/1     Running   2 (93m ago)      13h

~ » k get svc -A                                                                                                                                                yanfeiyang@ylinx
NAMESPACE     NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
kube-system   kube-dns     ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   13h
```

## 4. 服务发布

```shell
# Pod和svc的地址，只能在集群内部访问，外部无法访问,要想让集群外部分访问服务，方式如下：
1. NodePort        k expose --name nginx deploy  nginx  --port=80 --type=NodePort 
2. LoadBalances    给svc分配一个lbIP地址，这个由metallb提供，第三方服务 需要提前安装下载 https://metallb.universe.tf
3. ingress         Bare metal clusters
```

```shell
# external-ip

~ » k expose --name nginx deploy  nginx  --port=80 --target-port=9999 --external-ip=192.168.51.46                                                           service/nginx exposed

~ » k get svc       
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP     PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1       <none>          443/TCP   17h
nginx        ClusterIP   10.103.81.222   192.168.51.46   80/TCP    4s

~ » k get svc nginx -oyaml                                                                                                                                      
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: "2022-05-19T06:41:24Z"
  labels:
    app: nginx
  name: nginx
  namespace: default
  resourceVersion: "21466"
  uid: b48cfa13-335a-4645-b328-9c8fbbda3e22
spec:
  clusterIP: 10.104.209.97
  clusterIPs:
  - 10.104.209.97
  externalIPs:
  - 192.168.51.46
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - port: 80
    protocol: TCP
    targetPort: 9999
  selector:
    app: nginx
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```

```shell
# NodePort 映射端口到所有node上 端口 3w + 

~ » k expose --name nginx deploy  nginx  --port=80 --type=NodePort  
service/nginx exposed

~ » k get svc                                                                                                                                                   NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        17h
nginx        NodePort    10.107.154.243   <none>        80:30963/TCP   4s

~ » k get svc -oyaml                                                                                                                                            - apiVersion: v1
  kind: Service
  metadata:
    creationTimestamp: "2022-05-19T06:44:20Z"
    labels:
      app: nginx
    name: nginx
    namespace: default
    resourceVersion: "21700"
    uid: 49fe8e1a-a634-4d8f-a5ad-b0509b4fad2d
  spec:
    clusterIP: 10.107.154.243
    clusterIPs:
    - 10.107.154.243
    externalTrafficPolicy: Cluster
    internalTrafficPolicy: Cluster
    ipFamilies:
    - IPv4
    ipFamilyPolicy: SingleStack
    ports:
    - nodePort: 30963
      port: 80
      protocol: TCP
      targetPort: 80
    selector:
      app: nginx
    sessionAffinity: None
    type: NodePort
  status:
    loadBalancer:
      ingress:
      - hostname: localhost
kind: List
metadata:
  resourceVersion: ""
---------------------
```

## 5. ingress

```shell
# 需要安装控制器,在安装时 是通过deploy部署的，需要将controller定向调度到指定ingress节点 --- 在写域名解析时需要解析到该IP

# 安装遇事不决查官网 Bare metal clusters
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.0/deploy/static/provider/baremetal/deploy.yaml
```

```shell
# 官网链接
https://kubernetes.io/zh/docs/concepts/services-networking/ingress/

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
spec:
  ingressClassName: nginx
  rules:
  - host: xx.yy.com
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```
## 6.  HPA

```shell
HPA: 水平自动伸缩，通过检查pod的cpu负载，解决deployment里某pod负载太重，动态伸缩pod的数量来负载均衡
```

```shell
# 需要提前安装好 metrics-server 在deploy里面定义资源限制
    spec:
      containers:
      - image: nginx
        name: nginx
        resources:
          limits:
            cpu: 200m
            memory: 512Mi

[root@k8s-master ~]# kubectl autoscale deployment web --min=3 --max=5 # 创建HPA
horizontalpodautoscaler.autoscaling/web1 autoscaled
[root@k8s-master ~]# kubectl get hpa
NAME   REFERENCE         TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
web    Deployment/web   <unknown>/80%   3         5         0          5s
```


## 7. helm

```shell
# 安装 将helm复制到path即可, 自动补全与kubectl配置一致  https://helm.sh/ 官网
https://get.helm.sh/helm-v3.9.0-linux-amd64.tar.gz
```

### 7.1 基本使用

```shell
[root@k8s-master ~]# helm ls # 查看部署应用

[root@k8s-master ~]# helm install 名字 包的名字  # 

[root@k8s-master ~]#  helm repo list  # 查看仓库源
NAME	URL
ali 	https://apphub.aliyuncs.com

[root@k8s-master ~]# helm repo add ali https://apphub.aliyuncs.com  # 添加一个仓库
"ali" has been added to your repositories

[root@k8s-master ~]# helm repo remove ali  # 移除一个仓库源

[root@k8s-master ~]# helm search repo nginx  # 搜索

[root@k8s-master ~]# helm pull ali/nginx --version=5.1.5 # 拉取指定版本

[root@k8s-master ~]# helm package nginx    # 打包
Successfully packaged chart and saved it to: /root/nginx-100.100.100.tgz
```

```shell
[root@k8s-master nginx]# tree .
.
├── Chart.yaml
├── ci
│   └── values-with-ingress-metrics-and-serverblock.yaml
├── README.md
├── templates
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── ingress.yaml
│   ├── NOTES.txt
│   ├── server-block-configmap.yaml
│   ├── servicemonitor.yaml
│   ├── svc.yaml
│   └── tls-secrets.yaml
├── values.schema.json
└── values.yaml

# 配置一个charts
通过key-value的方式，注意模板间的套用
```

### 7.2 搭建一个私有仓库

```shell
# 利用nginx搭建
[root@k8s-master ~]# docker run -dti --name=web1 --restart=always -p 8080:80 -v /mycharts:/usr/share/nginx/html/mycharts nginx
```

```shell
[root@k8s-master nginx]# helm repo index . --url http://175.27.134.231:8080/mycharts # 根据package创建索引文件 会生成index.html
[root@k8s-master nginx]# cp nginx-100.100.100.tgz index.yaml /mycharts/   # 将索引文件与包copy到mycharts中

[root@k8s-master ~]# helm repo add myrepo http://175.27.134.231:8080/mycharts
"myrepo" has been added to your repositories
[root@k8s-master ~]# helm repo list    # 然后正常操作即可
NAME  	URL
ali   	https://apphub.aliyuncs.com
myrepo	http://175.27.134.231:8080/mycharts
```

## 8. 用户管理

操作kubernetes集群需要进行授权，主要有两种方式：token、kubeconfig

```shell
# 1. 系统默认不开启token登录
# 2. kubeconfig文件
cluster: master地址
		  集群证书 	
context:
   cluster
   namespace
   user

user:
   用户的私钥
   用户的公钥
# 3. 如果没有kubectl命令，直接下载二进制文件即可
# 4. 系统怎么知道使用的那个kubeconfig文件 可以手动指定、变量指定、默认~/.kube/config
[root@k8s-master ~]# kubectl get nodes --kubeconfig=admin.conf  # 或者存到默认路径

# 5. kubernetes证书存放路径
[root@k8s-master ~]# ll /etc/kubernetes/pki/
```

```shell
# kubernetes集群安装好之后，默认会生成一个admin的认证文件
[root@k8s-master ~]# ll  /etc/kubernetes/admin.conf
[root@k8s-master ~]# kubectl config view     # kubeconfig文件架构
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://10.206.0.15:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
[root@k8s-master ~]#
```

```shell
[root@k8s-master ~]# kubectl config get-contexts # 获取上下文信息
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kubernetes-admin@kubernetes   kubernetes   kubernetes-admin
```

创建一个自己的config文件：[kubeconfig创建](https://res.craft.do/user/full/650c2b8b-9755-d6cc-4b6f-6e8738fcd089/4D43D3E8-83EE-44BD-A457-3B218663C79A_2/PUz5nRgIKyIVRB3k6ogBCTs92Ntw7UyFfq8krrTOgooz/kubeconfig3.pdf)

## 9. RBAC

```shell
# 修改配置文件之后需要重启kubelet才能生效
[root@k8s-master ~]# cat /etc/kubernetes/manifests/kube-apiserver.yaml
    - --authorization-mode=Node,RBAC  # 配置授权
AlwayAllows   # 总是允许
AlwaysDeny    # 拒绝所有
Node          # 各node访问apiserver时使用
RBAC          # role based access control
ABAC          # 基本启用

[root@k8s-master ~]# kubectl describe clusterrole admin  # 查看管理员所具有的的权限
```

`role`和`rolebinding`：

```shell
# rbac
# role,rolebinding 具有ns概念

[root@k8s-master ~]# kubectl  get  role  # 查看role
[root@k8s-master ~]# kubectl create role r1 --resource=pod --verb=get,list --dry-run=client -o yaml  # 创建role
[root@k8s-master ~]# kubectl  get rolebindings.rbac.authorization.k8s.io  # 查看rolebinding
[root@k8s-master ~]# kubectl  create rolebinding rb1 --role=r1 --user=yy  # 创建rb1将r1的权限绑定给yy用户，kubeconfig里面配置的元素
[root@k8s-master ~]# kubectl describe rolebinding rb1
Name:         rb1
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  r1
Subjects:
  Kind  Name  Namespace
  ----  ----  ---------
  User  yy
```

```shell
[root@k8s-master ~]# kubectl api-resources # 查看api资源
api资源的结构两种：父级、父级/子集  而在role里面apiGroups赋权是需要填入父级

[root@k8s-master ~]# cat r1.yaml           # 查看role规则
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: null
  name: r1
rules:
- apiGroups:			# 在这里的api-resources 不同资源的可能不一样，不能在一起赋权 比如deploy为apps/v1 pod/svc为v1
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
```

`clusterrole`和`clusterbinding`:

```shell
# clusterrole、clusterrolebinding 集群概念
[root@k8s-master ~]# kubectl create clusterrole c1 --resource=deploy --verb=get --dry-run=client -oyaml  # 创建
[root@k8s-master ~]# kubectl create rolebinding b1 --clusterrole=c1 --user=yy   # 通过rolebinding绑定 依然有ns限制
[root@k8s-master ~]# kubectl  create clusterrolebinding cb1  --clusterrole=c1 --user=yy # 这样绑定才是集群角色
```

账户管理：

```shell
# 在系统中存在两种账户
1. user account  登录系统的
2. service account 服务账户，给pod里面的进程使用的

当pod需要某种权限时，我们给sa授权，然后pod绑定sa即可。
kubernetes每个ns中都有一个默认的sa，且无法删除；创建pod时不指定sa就是默认的sa

每创建一个sa，系统会自动创建一个secret：saname-token-xxxx,会包含一个token, pod在运行时会将该token写入到指定目录中
[root@k8s-master ~]# kubectl get sa
NAME                 SECRETS   AGE
default              1         15d
[root@k8s-master ~]# kubectl get secrets
NAME                             TYPE                                  DATA   AGE
default-token-74v27              kubernetes.io/service-account-token   3      15d
[root@k8s-master ~]# kubectl describe secrets default-token-74v27

root@web01:/# ls /run/secrets/kubernetes.io/serviceaccount   # token目录 df -Th查看
ca.crt	namespace  token  # 1.20之后token做了加密 之前有describe中一致
```

```shell
# role  sa  rolebinding
[root@k8s-master ~]# kubectl create sa s1   # 创建sa
[root@k8s-master ~]# kubectl  set sa deploy web s1  # 设置delpoy web使用s1这个sa 或者直接修改deploy里面的spec.serviceAccount参数
[root@k8s-master ~]# kubectl create rolebinding rb2 --role=r1 --serviceaccount=default:s1  # 通过rolebinding将role r1与sa s1做绑定
```

## 10. 其他资源
- [密码管理 - secret](https://kubernetes.io/zh/docs/tasks/configmap-secret/managing-secret-using-kubectl/)
- [ConfigMap](https://kubernetes.io/zh/docs/concepts/configuration/configmap/#using-configmaps)
- [Daemonset](https://kubernetes.io/zh/docs/concepts/workloads/controllers/daemonset/)
- [Probe探针](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [网络策略](https://kubernetes.io/zh/docs/concepts/services-networking/network-policies/)
- [资源限制](https://kubernetes.io/zh/docs/concepts/policy/resource-quotas/#requests-vs-limits)
- [StatefulSet](https://kubernetes.io/zh/docs/tutorials/stateful-application/basic-stateful-set/)

## 11. 操作文档
- [devops](https://res.craft.do/user/full/650c2b8b-9755-d6cc-4b6f-6e8738fcd089/7375EB40-88D5-49B4-A06D-91D47D6AF16F_2/N4YYxjurlS0If4aPpN9QzQidYo9A7BIw579fONItvx8z/14.devOps.pdf)
- [CICD](https://res.craft.do/user/full/650c2b8b-9755-d6cc-4b6f-6e8738fcd089/F6C4CCB8-1CA4-49FD-B40E-DC42C9FD1E2D_2/mA3nRx44c63oExenBGhTnxvmDIl1H97slEnHuELQ0xMz/cicd2.pdf)
- [集群安装](https://www.craft.do/s/drBoTKgNgNp8kL)
- [集群的升级](https://www.craft.do/s/POCe0PwEACwebP)