---
title: Kubernetes基础架构
date: 2023-02-19 15:53:00
tags: [Kubernetes, DevOps]
banner_img: /img/index.png
index_img: /img/kubernetes.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Kubernets系列
---
### 集群信息

1. 显示 Kubernetes 版本：`kubectl version`
2. 显示集群信息：`kubectl cluster-info`
3. 列出集群中的所有节点：`kubectl get nodes`
4. 查看一个具体的节点详情：`kubectl describe node <node-name>`
5. 列出所有命名空间：`kubectl get namespaces`
6. 列出所有命名空间中的所有 pod：`kubectl get pods --all-namespaces`

### Pod 诊断

1. 列出特定命名空间中的 pod：`kubectl get pods -n <namespace>`
2. 查看一个 Pod 详情：`kubectl describe pod <pod-name> -n <namespace>`
3. 查看 Pod 日志：`kubectl logs <pod-name> -n <namespace>`
4. 尾部 Pod 日志：`kubectl logs -f <pod-name> -n <namespace>`
5. 在 pod 中执行命令：`kubectl exec -it <pod-name> -n <namespace> -- <command>`

### Pod 健康

1. 检查 Pod 准备情况：`kubectl get pods <pod-name> -n <namespace> -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'`
2. 检查 Pod 事件：`kubectl get events -n <namespace> --field-selector involvedObject.name=<pod-name>`

### Service诊断

1. 列出命名空间中的所有服务：`kubectl get svc -n <namespace>`
2. 查看一个服务详情：`kubectl describe svc <service-name> -n <namespace>`

### Deployment诊断

1. 列出命名空间中的所有Deployment：`kubectl get deployments -n <namespace>`
2. 查看一个Deployment详情：`kubectl describe deployment <deployment-name> -n <namespace>`
3. 查看滚动发布状态：`kubectl rollout status deployment/<deployment-name> -n <namespace>`
4. 查看滚动发布历史记录：`kubectl rollout history deployment/<deployment-name> -n <namespace>`

### StatefulSet诊断

1. 列出命名空间中的所有 StatefulSet：`kubectl get statefulsets -n <namespace>`
2. 查看一个 StatefulSet详情：`kubectl describe statefulset <statefulset-name> -n <namespace>`

### ConfigMap 和Secret诊断

1. 列出命名空间中的 ConfigMap：`kubectl get configmaps -n <namespace>`
2. 查看一个ConfigMap详情：`kubectl describe configmap <configmap-name> -n <namespace>`
3. 列出命名空间中的 Secret：`kubectl get secrets -n <namespace>`
4. 查看一个Secret详情：`kubectl describe secret <secret-name> -n <namespace>`

### 命名空间诊断

1. 查看一个命名空间详情：`kubectl describe namespace <namespace-name>`

### 资源使用情况

1. 检查 pod 的资源使用情况：`kubectl top pod <pod-name> -n <namespace>`
2. 检查节点资源使用情况：`kubectl top nodes`

### 网络诊断

1. 显示命名空间中 Pod 的 IP 地址：`kubectl get pods -n <namespace> -o custom-columns=POD:metadata.name,IP:status.podIP --no-headers`
2. 列出命名空间中的所有网络策略：`kubectl get networkpolicies -n <namespace>`
3. 查看一个网络策略详情：`kubectl describe networkpolicy <network-policy-name> -n <namespace>`

### 持久卷 (PV) 和持久卷声明 (PVC) 诊断

1. 列出PV：`kubectl get pv`
2. 查看一个PV详情：`kubectl describe pv <pv-name>`
3. 列出命名空间中的 PVC：`kubectl get pvc -n <namespace>`
4. 查看PVC详情：`kubectl describe pvc <pvc-name> -n <namespace>`

### 节点诊断

1. 获取特定节点上运行的 Pod 列表：`kubectl get pods --field-selector spec.nodeName=<node-name> -n <namespace>`

### 资源配额和限制

1. 列出命名空间中的资源配额：`kubectl get resourcequotas -n <namespace>`
2. 查看一个资源配额详情：`kubectl describe resourcequota <resource-quota-name> -n <namespace>`

### 自定义资源定义 (CRD) 诊断

1. 列出命名空间中的自定义资源：`kubectl get <custom-resource-name> -n <namespace>`
2. 查看自定义资源详情：`kubectl describe <custom-resource-name> <custom-resource-instance-name> -n <namespace>`
  使用这些命令时，请记住将`<namespace>, <pod-name>, <service-name>, <deployment-name>, <statefulset-name>, <configmap-name>, <secret-name>, <namespace-name>, <pv-name>, <pvc-name>, <node-name>, <network-policy-name>, <resource-quota-name>, <custom-resource-name>`, 和替换为你的特定值。

`<custom-resource-instance-name>`这些命令应该可以帮助你诊断 Kubernetes 集群以及在其中运行的应用程序。

### 资源伸缩和自动伸缩

1. Deployment伸缩：`kubectl scale deployment <deployment-name> --replicas=<replica-count> -n <namespace>`
2. 设置Deployment的自动伸缩：`kubectl autoscale deployment <deployment-name> --min=<min-pods> --max=<max-pods> --cpu-percent=<cpu-percent> -n <namespace>`
3. 检查水平伸缩器状态：`kubectl get hpa -n <namespace>`


### 作业和 CronJob 诊断

1. 列出命名空间中的所有作业：`kubectl get jobs -n <namespace>`
2. 查看一份工作详情：`kubectl describe job <job-name> -n <namespace>`
3. 列出命名空间中的所有 cron 作业：`kubectl get cronjobs -n <namespace>`
4. 查看一个 cron 作业详情：`kubectl describe cronjob <cronjob-name> -n <namespace>`


### 容量诊断

1. 列出按容量排序的持久卷 (PV)：`kubectl get pv --sort-by=.spec.capacity.storage`
2. 查看PV回收策略：`kubectl get pv <pv-name> -o=jsonpath='{.spec.persistentVolumeReclaimPolicy}'`
3. 列出所有存储类别：`kubectl get storageclasses`


### Ingress和服务网格诊断

1. 列出命名空间中的所有Ingress：`kubectl get ingress -n <namespace>`
2. 查看一个Ingress详情：`kubectl describe ingress <ingress-name> -n <namespace>`
3. 列出命名空间中的所有 VirtualServices (Istio)：`kubectl get virtualservices -n <namespace>`
4. 查看一个 VirtualService (Istio)详情：`kubectl describe virtualservice <virtualservice-name> -n <namespace>`


### Pod 网络故障排除

1. 运行网络诊断 Pod（例如 busybox）进行调试：`kubectl run -it --rm --restart=Never --image=busybox net-debug-pod -- /bin/sh`
2. 测试从 Pod 到特定端点的连接：`kubectl exec -it <pod-name> -n <namespace> -- curl <endpoint-url>`
3. 跟踪从一个 Pod 到另一个 Pod 的网络路径：`kubectl exec -it <source-pod-name> -n <namespace> -- traceroute <destination-pod-ip>`
4. 检查 Pod 的 DNS 解析：`kubectl exec -it <pod-name> -n <namespace> -- nslookup <domain-name>`


### 配置和资源验证

1. 验证 Kubernetes YAML 文件而不应用它：`kubectl apply --dry-run=client -f <yaml-file>`
2. 验证 pod 的安全上下文和功能：`kubectl auth can-i list pods --as=system:serviceaccount:<namespace>:<serviceaccount-name>`


### RBAC 和安全性

1. 列出命名空间中的角色和角色绑定：`kubectl get roles,rolebindings -n <namespace>`
2. 查看角色或角色绑定详情：`kubectl describe role <role-name> -n <namespace>`


### 服务帐户诊断

1. 列出命名空间中的服务帐户：`kubectl get serviceaccounts -n <namespace>`
2. 查看一个服务帐户详情：`kubectl describe serviceaccount <serviceaccount-name> -n <namespace>`


### 清空节点和解除封锁

1. 清空节点以进行维护：`kubectl drain <node-name> --ignore-daemonsets`
2. 解除对节点的封锁：`kubectl uncordon <node-name>`


### 资源清理

1. 强制删除 pod（不推荐）：`kubectl delete pod <pod-name> -n <namespace> --grace-period=0 --force`


### Pod 亲和性和反亲和性

1. 列出 pod 的 pod 亲和性规则：`kubectl get pod <pod-name> -n <namespace> -o=jsonpath='{.spec.affinity}'`
2. 列出 pod 的 pod 反亲和性规则：`kubectl get pod <pod-name> -n <namespace> -o=jsonpath='{.spec.affinity.podAntiAffinity}'`


### Pod 安全策略 (PSP)

1. 列出所有 Pod 安全策略（如果启用）：`kubectl get psp`


### 事件

1. 查看最近的集群事件：`kubectl get events --sort-by=.metadata.creationTimestamp`
2. 按特定命名空间过滤事件：`kubectl get events -n <namespace>`


### 节点故障排除

1. 检查节点情况：`kubectl describe node <node-name> | grep Conditions -A5`
2. 列出节点容量和可分配资源：`kubectl describe node <node-name> | grep -E "Capacity|Allocatable"`


### 临时容器（Kubernetes 1.18+）

1. 运行临时调试容器：`kubectl debug -it <pod-name> -n <namespace> --image=<debug-image> -- /bin/sh`


### 资源指标（需要指标服务器）

1. 获取 Pod 的 CPU 和内存使用情况：`kubectl top pod -n <namespace>`


### kuelet诊断

1. 查看节点上的kubelet日志：`kubectl logs -n kube-system kubelet-<node-name>`

### 节点污点

1. 列出节点污点：kubectl describe node <node-name> | grep Taints

### Pod 网络策略

1. 列出命名空间中的 pod 网络策略：kubectl get networkpolicies -n <namespace>

### 使用Telepresence 进行高级调试

1. 使用 Telepresence 调试 pod：telepresence --namespace <namespace> --swap-deployment <pod-name>
Kubeconfig 和上下文：

1. 列出可用的上下文：kubectl config get-contexts
2. 切换到不同的上下文：kubectl config use-context <context-name>
Pod 安全标准（PodSecurity 准入控制器）：

1. 列出 PodSecurityPolicy (PSP) 违规行为：kubectl get psp -A | grep -vE 'NAME|REVIEWED'
Pod 中断预算 (PDB) 诊断：

1. 列出命名空间中的所有 PDB：kubectl get pdb -n <namespace>
2. 查看一个PDB详情：kubectl describe pdb <pdb-name> -n <namespace>
资源锁诊断（如果使用资源锁）：

1. 列出命名空间中的资源锁：kubectl get resourcelocks -n <namespace>
服务端点和 DNS：

1. 列出服务的服务端点：kubectl get endpoints <service-name> -n <namespace>
2. 检查 Pod 中的 DNS 配置：kubectl exec -it <pod-name> -n <namespace> -- cat /etc/resolv.conf
自定义指标（Prometheus、Grafana）：

1. 查询Prometheus指标：用于kubectl port-forward访问Prometheus和Grafana服务来查询自定义指标。

1. 列出优先级：kubectl get priorityclasses

1. 列出 pod 中的开销：kubectl get pod <pod-name> -n <namespace> -o=jsonpath='{.spec.overhead}'
存储卷快照诊断（如果使用存储卷快照）：

1. 列出存储卷快照：kubectl get volumesnapshot -n <namespace>
2. 查看存储卷快照详情：kubectl describe volumesnapshot <snapshot-name> -n <namespace>
资源反序列化诊断：

15. 反序列化并打印 Kubernetes 资源：kubectl get <resource-type> <resource-name> -n <namespace> -o=json
