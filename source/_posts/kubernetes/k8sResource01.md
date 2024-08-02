---
title: Kubernetes基础资源(一)
date: 2023-02-19 15:53:10
tags: [Kubernetes, DevOps]
banner_img: /img/index.png
index_img: /img/pods.png
show_category: true # 表示强制开启
categories:
  - Kubernets系列
---
Pod作为`Kubernetes`最基础的资源对象，是可以在`Kubernetes`中创建和管理的、最小的可部署的计算单元。Pod是一组(一个或多个)容器； 这些容器共享存储、网络、以及怎样运行这些容器的声明。 Pod中的内容总是并置(colocated)的并且一同调度，在共享的上下文中运行。 Pod 所建模的是特定于应用的 “逻辑主机”，其中包含一个或多个应用容器， 这些容器相对紧密地耦合在一起。

>  除了Docker之外，Kubernetes支持很多其他容器运行时， 在k8s 1.24版本里面启用docker 采用containerd作为运行时

## 1. 创建Pod

```shell
# 1. 通过命令方式创建  --dry-run 测试运行 client模拟客户端显示信息较少 server显示信息很多, 建议查看官网命令如上
[root@k8s-master ~]# kubectl run podname --image=nginx --image-pull-policy=IfNotPresent --dry-run=client -o yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: podname
  name: podname
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: podname
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

```shell
# 2. 通过yaml文件创建
[root@k8s-master ch03]# cat pod1.yaml		# 一个pod里面两个容器 会共享pod的网络空间 所有在一个pod网络空间里面运行两个nginx一定网络冲突
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: c1
    resources: {}
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: c2
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

```shell
# 3. 创建pod时指定环境变量, 变量的值不能是数字  端口 启动宿主机网络空间
  hostNetwork: true				# 共用宿主机的网络空间，则不在添加下面的hostPort参数
  containers: 
    ... 
    resources: {}
    securityContext:
      privileged: true
    env:
    - name: s1
      value: haha
    ports:
    - name: http
      containerPort: 80
      hostPort: 8088
  dnsPolicy: ClusterFirst
  ....
```

```shell
# 4. 查看帮助 结构体
[root@k8s-master ~]# kubectl explain pod.spec.containers
```

## 2. Pod参数

```shell
# 修改镜像守护进程, 如果修改的command命令容器没法执行也会报错
  ...
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    command: ["sh","-c","sleep 100"]
    name: c1
    resources: {}
  ...
```

```shell
# 镜像拉取策略
1. Always		 		# 总是拉取镜像，默认该策略
2. IfNotPresent		# 优先使用本地镜像，没有在拉取
3. Nerver				# 只使用本地的
```

```shell
# pod重启策略 Pod的spec中包含一个restartPolicy字段，其可能取值包括Always、OnFailure和Never。默认值是Always。
[root@k8s-master ~]# kubectl explain pods.spec.restartPolicy
KIND:     Pod
VERSION:  v1

FIELD:    restartPolicy <string>

DESCRIPTION:
     Restart policy for all containers within the pod. One of Always, OnFailure(失败的时候才重启),
     Never. Default to Always. More info:
```

## 3. Pod网络

```shell
# pod创建完成之后实际上是一个docker container  但是这个container是没有IP地址的， 通过docker inpsect containerid|grep ipAddress查看

# 容器只是共享了pod的网络空间，在访问pod的IP时 会访问到真正的容器

[root@k8s-master ch03]# kubectl  get pods  -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP              NODE        NOMINATED NODE   READINESS GATES
pod1   1/1     Running   0          37s   192.168.10.27   k8s-node2   <none>           <none>

[root@k8s-node2 ~]# docker inspect 63579e2d0a53 |grep -i ipaddress
            "SecondaryIPAddresses": null,
            "IPAddress": "",
```

## 4. 钩子进程

```shell
# 一个容器在运行主进程的时候还想要运行一个次进程，即在一个容器里面同时运行两个进程，使用docker run是无法实现的，可以使用钩子进程pod hook实现
# 1. 钩子进程和主进程同时运行，如果钩子进程没有运行完成，那么容器是不会变成Running状态的    postStart   
# 2. 在主进程关闭之前运行，在删除pod的宽限期内，需要先执行钩子进程在删除主进程，如果在宽限期内没有执行完 就强制删除   preStop
```

```shell
# yaml如下，参数查看 kubectl explain pods.spec.containers.lifecycle
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    command: ["/bin/sh","-c","date > aa.txt; sleep 10000"]
    name: c1
    resources: {}
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh","-c","date > bb.txt; sleep 10"]
      preStop:
        exec:
          command: ["/bin/sh","-c","sleep 10"]
```

## 5. 初始化容器

```shell
# 一般情况下一个pod运行一个容器，但是也可以运行两个，一个主容器一个辅容器(一般叫做sidecar 边车)  这两个会同时运行
```

```shell
# 而初始化容器与上面相反

# 在一个pod中存在一个普通容器和多个初始化容器，只有初始化容器都正常运行后，才能运行普通容器
# 初始化容器执行顺序从上往下

# 用途：某些普通容器在运行时必须有什么条件，而达成这个条件就可以通过初始化容器实现
```

```shell
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: c1
    resources: {}
  initContainers:				# 定义初始化容器
  - image: alpine
    imagePullPolicy: IfNotPresent
    name: a1
    resources: {}
    command: ["sh","-c","sysctl -w vm.swappiness=0"]
    securityContext:
      privileged: true
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

## 6. 静态pod

在kube-system命名空间中的pod都是通过静态pod的方式启动的，然后master才能正常启动；我们通过master操作pod。静态的pod是不受master管理的，完全由kubelet来启动；只要把写好的yaml文件，放在特定的目录中--kubelet会自动的把这个pod创建好。

```Bash
# 查看这个特定的目录
1. 查看vim /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf配置文件，里面的Service配置
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"


2. 配置文件 /var/lib/kubelet/config.yaml 这个在master与worker上都有
查看该文件里面，有个参数：staticPodPath: /etc/kubernetes/manifests，只要把静态pod文件放在里面就可以了,自动创建

[root@k8s-master ~]# ls /etc/kubernetes/manifests   # 在修改基础环境的时候，需要重启kubelet，重新加载
etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml
```

```Bash
1. 如果修改/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf文件，在里面添加
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --pod-manifest-path=/xx/x/x" 
此时就是--pod-manifest-path以这个为准
```

## 7. pod调度

```Bash
# 创建pod的流程
1. 用户准备一个资源文件（记录了业务应用的名称、镜像地址等信息），通过调用APIServer执行创建Pod
2. APIServer收到用户的Pod创建请求之后，先鉴权该用户是否有权限做这个操作，然后进去准入环境，根据规则判断
3. 规则通过后将Pod信息写入到etcd中，同时pod状态为pending
4. 调度器通过list-watch的方式，发现有新的pod数据，但是这个pod还没有绑定到某一个节点中
5. 调度器通过调度算法，计算出最适合该pod运行的节点，并调用APIServer，把信息更新到etcd中
6. kubelet同样通过list-watch方式，发现有新的pod调度到本机的节点了，因此调用容器运行时，去根据pod的描述信息，拉取镜像，启动容器，同时生成事件信息
7. 同时，把容器的信息、事件及状态也通过APIServer写入到etcd中
```

```Bash
1. nodeName
spec.nodeName: k8s-master  # 该name需要与kubectl get nodes匹配, 执行时会忽略nodes污点，或者cordon的
```

```Bash
2. 标签
kubectl get 资源 --show-labels   # 查看标签,特殊标签- /
kubectl label 资源 名称  xx=xx    # 设置标签，删除标签时为xx-

[root@k8s-master ~]# kubectl  label nodes k8s-node1 xx=xx  # 设置标签
[root@k8s-master ~]# kubectl get nodes -l xx=xx  # 匹配标签的nodes    
[root@k8s-master ~]# kubectl  label nodes k8s-node1 xx=yy --overwrite   # 修改标签需要覆盖
node/k8s-node1 labeled

...
spec:
  nodeSelector:
    xx: xx
  containers:
...
```

```Bash
3. 主机亲和性
https://kubernetes.io/zh/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity
```

```Bash
1. coredon
[root@k8s-master ~]# kubectl cordon k8s-node2   # 将节点设置为cordon之后节点将不在被调度（nodeName规则除外），不接受新pod 旧pod无影响
[root@k8s-master ~]# kubectl get no
NAME         STATUS                     ROLES                  AGE   VERSION
k8s-master   Ready                      control-plane,master   11d   v1.23.6
k8s-node1    Ready                      <none>                 11d   v1.23.6
k8s-node2    Ready,SchedulingDisabled   <none>                 11d   v1.23.6
[root@k8s-master ~]# kubectl uncordon k8s-node2  # 恢复
```

```Bash
2. 驱逐
# 通过deploy创建的pod才具有再生性，pod本身是没有再生性的；而驱逐是将node设置为不可调度，在将node上的pod删除，控制器在别的地方在重建

[root@k8s-master ~]# kubectl drain k8s-node2 --ignore-daemonsets  # 根据报错进一步分析，如果有系统资源 驱逐会失败,驱逐完成该node不可调度，如果需要调度需要执行如下命令
[root@k8s-master ~]# kubectl uncordon k8s-node2   # 恢复
```

```Bash
3. 污点 
格式：key=value:effect # 可以不要=value    effect包含：NoSchedule
[root@k8s-master ~]# kubectl taint nodes k8s-node2 xx=xx:NoSchedule  # 设置 取消key-
node/k8s-node2 tainted
[root@k8s-master ~]# kubectl describe no k8s-node2 |grep Taint  # 查看k8s-master上的污点
Taints:             xx=xx:NoSchedule

tolerations:
- key: "key1"
  operator: "Equal"
  value: "value1"
  effect: "NoSchedule"

tolerations:
- key: "key1"
  operator: "Exists"
  effect: "NoSchedule"
```

## 8. 存储

```Bash
1. 在pod里面进行文件操作，最终该文件是写在宿主机的哪里
[root@k8s-node1 ~]# find / -name a.txt
/var/lib/docker/overlay2/7456a23de4035959cf9f218208457615167a832e2e5fe7150fc049b24b109dbd/diff/a.txt
/var/lib/docker/overlay2/7456a23de4035959cf9f218208457615167a832e2e5fe7150fc049b24b109dbd/merged/a.txt

[root@k8s-master ~]# docker inspect 69c515b0bc1f   # 查看Mounts参数可以查看挂载信息
```

```Bash
2. 先定义在使用 查看官网手册
卷的类型：emptyDir、hostPath、NFS、持久性存储、动态卷、secret、configmap、projected
```

```Bash
emptyDir: 在pod销毁之后数据也会消失
hostPath: 将本地磁盘挂载给pod用，本地即使没有该目录也会自动创建，数据针对宿主机存在的，如果该pod调度到别的节点 数据就没有了
nfs: 配置共享存储，pod销毁，调度 数据依然在，所有的worker都需要装nfs客户端
	表现上是pod直接挂载nfs,但是实际上还是宿主机挂载了，然后再把宿主机的目标挂载容器，宿主机在中间做通道
持久性存储：pv（全局性） + pvc   管理关系是唯一的，pv与pvc解关联后pv里面的数据将被删除（会产生清理pod去执行这个操作）
	在定义pvc时 不需要指定与那个pv管理，这是一个自动的过程，通过匹配参数实现，accessModes、容量<=pv
动态卷供应：storageClass 不需要提前创建pv, 根据需求动态创建pv
```

## 9. 常用命令

```shell
# 1. 1s执行一次命令
[root@k8s-master ~]# watch -n 1 'kubectl get pods'
```

```shell
# 2. 在删除pod时候需要先终止容器运行程序，在删除pod, 所有会hang住 30s后在删除，或者强制删除pod
[root@k8s-master ~]# kubectl delete pods pod1 --force

# 可以通过定义yaml文件里面的spec[0]=terminationGracePeriodSeconds参数进行控制
```

```shell
# 3. 在pod里面执行命令
[root@k8s-master ch03]# kubectl exec -ti pod1 -- cat /etc/hosts  # -- + 命令
# Kubernetes-managed hosts file.
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
fe00::0	ip6-mcastprefix
fe00::1	ip6-allnodes
fe00::2	ip6-allrouters
192.168.10.33	pod1

[root@k8s-master ~]# kubectl exec -ti pod1 -c c1 -- cat /etc/hosts   # 当一个pod多个容器时 执行命令需要通过-c指明是那个容器
[root@k8s-master ~]# k exec -ti web01 -- sh -c "echo "111" > /usr/share/nginx/html/index.html"  #
```

```shell
# 4. 拷贝文件到pod里面   反向也行
[root@k8s-master ch03]# kubectl cp ./pod1.yaml pod1:/tmp
[root@k8s-master ch03]# kubectl exec -ti pod1 -- ls /tmp
pod1.yaml
```

```shell
# 5. 定向调度
[root@k8s-master ~]# kubectl label node k8s-node2 disktype=ssd
```

```shell
# 6. 快速创建pod
[root@k8s-master ~]# sed 's/web01/web02/' web01.yaml | kubectl apply -f -
pod/web02 created
```

```shell
# 7. 镜像拉取
如果拉取不下来，可以先去阿里云镜像中心拉取在修改tag
```

## 10. 常见错误

```shell
# 1. 在同一个pod网络空间中 网络端口冲突 导致相同docker container进程只能起来一个
[root@k8s-master ch03]# cat pod1.yaml		# 两个nginx端口肯定冲突，可以修改c2的守护进程
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: c1
    resources: {}
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: c2
    resources: {}
...
```

```shell
# 2. 无法修改pod系统里面的核心参数  --  将pod以特权模式运行
  containers:
  - image: nginx
    imagePullPolicy: IfNotPresent
    name: c2
    resources: {}
    securityContext:
      privileged: true
  dnsPolicy: ClusterFirst
  ...
```

```shell
# 3. pod状态异常
[root@k8s-master ~]# kubectl get event    # 查看pod事件

[root@k8s-master ~]# kubectl logs pod1     # 当状态为CrashLoopBackOff表示容器内容逻辑错误 命令、环境变量、参数等
```

```shell
# 4. 访问
在集群内部是可以访问pod ip的（无论是iptables还是ipvs），如果不对需要检查
iptables -P FORWARD ACCEPT

swapoff -a
# 防止开机自动挂载 swap 分区
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

sed -ri 's#(SELINUX=).*#\1disabled#' /etc/selinux/config
setenforce 0
systemctl disable firewalld && systemctl stop firewalld

还有内存参数：
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
vm.max_map_count=262144
EOF
modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf
```

```shell
# 5. 删除不掉
kubectl delete pod cros-decision-gateway-54c9f4dcd8-nk5p7 -ntimaker --grace-period=0 --force
```

```shell
# 6. 外网访问pod
需要在pod里面添加--external-ip=nodd_ip 参数
```

```shell
# 7. pod的属性是不能直接修改的，通过deploy修改属性也只是把原有的pod删除在新建而已
```
## 11. 参考材料
- [Kubectl-command crate命令集](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#create)
- [Pod](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/)
- [Pod的存储资源](https://kubernetes.io/zh-cn/docs/concepts/storage/)