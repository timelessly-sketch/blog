---
title: MongoDB副本集群
date: 2024-08-07 11:15:50
tags: [MongoDB, DevOps]
banner_img: /img/index.png
index_img: /img/mongodb_3.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - 运维系列
  - 二. 日常数据
---

## 1 简单介绍

​	一组Mongodb复制集，就是一组mongod进程，这些进程维护同一个数据集合。复制集提供了数据冗余和高等级的可靠性，这是生产部署的基础。一组复制集就是一组mongod实例掌管同一个数据集，实例可以在不同的机器上面。实例中包含一个主导，接受客户端所有的写入操作，其他都是副本实例，从主服务器上获得数据并保持同步。

​	主服务器很重要，包含了所有的改变操作（写）的日志。但是副本服务器集群包含有所有的主服务器数据，因此当主服务器挂掉了，就会在副本服务器上重新选取一个成为主服务器。

　　每个复制集还有一个仲裁者(可选)，仲裁者不存储数据，只是负责通过心跳包来确认集群中集合的数量，并在主服务器选举的时候作为仲裁决定结果。

## 2 基本架构

基本的架构由3台服务器组成，一个三成员的复制集，由三个有数据，或者两个有数据，一个作为仲裁者。--这是早期的版本，现在不建议有仲裁节点。直接通过设置优先级实现。**集群节点地址的通信不能走NAT**

**通过选举完成故障恢复**

- 具有投票权的节点之间两两互相发送心跳，
- 当5次心跳未收到时判断为节点失联
- 如果失联的是主节点，从节点会发起选举，选出新的主节点
- 如果失联的是从节点则不会产生新的选举，
- 选举基于筏板一致性算法实现，选举成功的必要条件是大多数投票节点存活
- 复制集中最多可以有50个节点，但具有投票权的节点最多7个

**影响选举的因素**

- 整个集群必须有大多数节点存活 N/2 +1 
- 被选举为Primary的节点，必须能够与多数节点建立链接 ；具有较新的oplog 具有较高的优先级(如果有配置的)

### 2.1 三数据节点

一个主库，两个从库组成，主库宕机时，这两个从库都可以被选为主库(也考虑优先级)。

![architecture.png](/img/mongo/set.png)

 当主库宕机后,两个从库都会进行竞选，其中一个变为主库，当原主库恢复后，如果优先级很高则会切主，否则作为从库加入当前的复制集群即可。

![architecture.png](/img/mongo/set02.png)

在三个成员的复制集中，有两个正常的主从，及一台arbiter节点，一个aribiter节点，在选举中，只进行投票，不能成为主库

由于arbiter节点没有复制数据，因此这个架构中仅提供一个完整的数据副本。arbiter节点只需要更少的资源，代价是更有限的冗余和容错。

### 2.2 成员说明

| **成员**      | **说明**                                                     |
| ------------- | ------------------------------------------------------------ |
| **Secondary** | 正常情况下，复制集的Seconary会参与Primary选举（自身也可能会被选为Primary），并从Primary同步最新写入的数据，以保证与Primary存储相同的数据。Secondary可以提供读服务，增加Secondary节点可以提供复制集的读服务能力，同时提升复制集的可用性。另外，Mongodb支持对复制集的Secondary节点进行灵活的配置，以适应多种场景的需求。 |
| **Arbiter**   | Arbiter节点只参与投票，不能被选为Primary，并且不从Primary同步数据。比如你部署了一个2个节点的复制集，1个Primary，1个Secondary，任意节点宕机，复制集将不能提供服务了（无法选出Primary），这时可以给复制集添加一个Arbiter节点，即使有节点宕机，仍能选出Primary。Arbiter本身不存储数据，是非常轻量级的服务，当复制集成员为偶数时，最好加入一个Arbiter节点，以提升复制集可用性。 |
| **Priority0** | Priority0节点的选举优先级为0，不会被选举为Primary比如你跨机房A、B部署了一个复制集，并且想指定Primary必须在A机房，这时可以将B机房的复制集成员Priority设置为0，这样Primary就一定会是A机房的成员。（注意：如果这样部署，最好将『大多数』节点部署在A机房，否则网络分区时可能无法选出Primary） |
| **Vote0**     | Mongodb 3.0里，复制集成员最多50个，参与Primary选举投票的成员最多7个，其他成员（Vote0）的vote属性必须设置为0，即不参与投票。 |
| **Hidden**    | Hidden节点不能被选为主（Priority为0），并且对Driver不可见。因Hidden节点不会接受Driver的请求，可使用Hidden节点做一些数据备份、离线计算的任务，不会影响复制集的服务。 |
| **Delayed**   | Delayed节点必须是Hidden节点，并且其数据落后与Primary一段时间（可配置，比如1个小时）。因Delayed节点的数据比Primary落后一段时间，当错误或者无效的数据写入Primary时，可通过Delayed节点的数据来恢复到之前的时间点。 |

如果一个节点显示为`OTHER`状态，这可能意味着它没有被正确地识别为上述任何一种标准状态。解决这个问题通常需要检查节点的配置、日志文件以及网络连接等，以确定为何节点没有进入预期的状态。可能的原因包括配置错误、网络问题或者节点之间的通信故障。

### 2.3 节点新加入集群

当一个节点新加入到一个集群会发送什么？

```bash
rs.add( { host: "192.168.56.197:27017", priority: 0, votes: 0 } ) # 建议将优先级与投票权设置为0
新节点在没有认证之前是other状态，在认证后是startup2
```



## 3 集群操作

```bash
# 设置隐藏节点 2是编号
cfg=rs.conf()
cfg.member[2].priority=0 
cfg.member[2].hidden=true
rs.reconfig(cfg) # 覆盖配置
rs.rcconfig(cfg,{force:true})  # 强制覆盖 用于操作other状态

rs.add({host:"127.0.0.1:27018",priority:0,hidden:true}) # 添加节点 参数按需入座
rs.remove("ip:port")  # 移除节点
```

```bash
# 初始化集群
use admin;
cfg={_id:"rs01",version:1,member:[{_id:0,host:"ip:port"}]}
rs.initiate(cfg)
```

```bash
role角色管理：
__system：具有服务器所有功能的访问权限，是最高权限的角色。
readAnyDatabase： 允许用户读取所有数据库。
# 创建用户
use admin
db.createUser({user: "myUser", pwd: "myPassword", roles: [ { role: "_system"} ]}); # 管理员
db.createUser({user: "myUser", pwd: "myPassword", roles: [ { role: "readWrite", db:"db01"} ]}); #db01的管理员
```
