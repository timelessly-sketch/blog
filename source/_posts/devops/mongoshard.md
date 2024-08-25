---
title: MongoDB分片集群
date: 2024-08-09 10:51:50
tags: [MongoDB, DevOps]
banner_img: /img/index.png
index_img: /img/mongodb_3.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - 运维系列
  - 二. 日常数据
---

分片（sharding）是MongoDB用来将大型集合分割到不同服务器（或者说一个集群）上所采用的方法。尽管分片起源于关系型数据库分区，但MongoDB分片完全又是另一回事。

和MySQL分区方案相比，MongoDB的最大区别在于它几乎能自动完成所有事情，只要告诉MongoDB要分配数据，它就能自动维护数据在不同服务器之间的均衡。

## 1 分片的目的

**高数据量和吞吐量的数据库应用会对单机的性能造成较大压力,大的查询量会将单机的CPU耗尽,大的数据量对单机的存储压力较大,最终会耗尽系统的内存而将压力转移到磁盘IO上。**

为了解决这些问题,有两个基本的方法: 垂直扩展和水平扩展。

- 垂直扩展：增加更多的CPU和存储资源来扩展容量。
- 水平扩展：将数据集分布在多个服务器上。水平扩展即分片。

## 2 基本概念

各种概念由小到大；

- 片键shard key：文档中的一个字段
- 文档doc：　   包含shard key的一行数据
- 块chunk：    包含n个文档
- 分片shard：   包含n个chunk
- 集群cluster：  包含n个分片

重点说一下Chunk，在一个shard server内部，MongoDB还是会把数据分为chunks，每个chunk代表这个shard server内部一部分数据。chunk的产生，会有以下两个用途：

​	**Splitting**：当一个chunk的大小超过配置中的chunk size时，MongoDB的后台进程会把这个chunk切分成更小的chunk，从而避免chunk过大的情况

​	**Balancing**：在MongoDB中，balancer是一个后台进程，负责chunk的迁移，从而均衡各个shard server的负载，系统初始1个chunk，chunk size默认值64M,生产库上选择适合业务的chunk size是最好的。MongoDB会自动拆分和迁移chunks。

## 3 分片设计思想

分片为应对高吞吐量与大数据量提供了方法。使用分片减少了每个分片需要处理的请求数，因此，通过水平扩展，集群可以提高自己的存储容量和吞吐量。举例来说，当插入一条数据时，应用只需要访问存储这条数据的分片。使用分片减少了每个分片存储的数据。例如，如果数据库1tb的数据集，并有4个分片，然后每个分片可能仅持有256 GB的数据。如果有40个分片，那么每个切分可能只有25GB的数据。

![分片设计思路](/img/mongo/shard01.png)

分片的基本标准：关于数据 数据量不超过3TB，尽可能保持在2TB一个片, 关于索引 常用索引必须容纳进内存

## 4 分片的优势

### 4.1 集群进行抽象

mongodb中没有failover机制，官方建议是将mongos和应用服务器部署在一起,多个应用服务器就要部署多个mongos实例。mongos作为统一路口的路由器，其会将客户端发来的请求准确无误的路由到集群中的一个或者一组服务器上，同时会把接收到的响应拼装起来发回到客户端。mongos的高可用可以用有几种方法可以使这三个mongos接口都利用起来，减少单个接口的压力。

mongodb 原生提供集群方案，该方案的简要架构如下：

![简要架构](/img/mongo/shard02.png)

MongoDB集群是一个典型的去中心化分布式集群。mongodb集群主要为用户解决了如下问题：

- 元数据的一致性与高可用（Consistency + Partition Torrence）
- 业务数据的多备份容灾(由复制集技术保证)
- 动态自动分片
- 动态自动数据均衡

```bash
下文通过介绍 mongodb 集群中各个组成部分，逐步深入剖析 mongodb 集群原理。
ConfigServer: mongodb 元数据全部存放在configServer中，configServer 是由一组（至少三个）MongoDb实例组成的集群。
ConfigServer 的唯一功能是提供元数据的增删改查。和大多数元数据管理系统（etcd，zookeeper）类似，也是保证一致性与分区容错性。本身不具备中心化的调度功能。
ConfigServer与复制集: ConfigServer的分区容错性(P)和数据一致性(C)是复制集本身的性质。

mongodb 的读写一致性由 WriteConcern 和 ReadConcern 两个参数保证,两者组合可以得到不同的一致性等级。指定writeConcern:majority 可以保证写入数据不丢失，不会因选举新主节点而被回滚掉。

readConcern:majority + writeConcern:majority 可以保证强一致性的读
readConcern:local + writeConcern:majority 可以保证最终一致性的读

mongodb 对configServer全部指定writeConcern:majority 的写入方式，因此元数据可以保证不丢失。
对 configServer 的读指定了 ReadPreference:PrimaryOnly 的方式，在 CAP 中舍弃了A与P得到了元数据的强一致性读。
```

### 4.2 保证集群总是可读写

MongoDB通过多种途径来确保集群的可用性和可靠性。将MongoDB的分片和复制功能结合使用，在确保数据分片到多台服务器的同时，也确保了每分数据都有相应的备份，这样就可以确保有服务器换掉时，其他的从库可以立即接替坏掉的部分继续工作。

### 4.3 使集群易于扩展

当系统需要更多的空间和资源的时候，MongoDB使我们可以按需方便的扩充系统容量。

## 5 分片集群架构

| **组件**          | **说明**                                                     |
| ----------------- | ------------------------------------------------------------ |
| **Config Server** | 存储集群所有节点、分片数据路由信息。默认需要配置3个Config Server节点。 |
| **Mongos**        | 提供对外应用访问，所有操作均通过mongos执行。一般有多个mongos节点。数据迁移和数据自动平衡。 |
| **Mongod**        | 存储应用数据记录。一般有多个Mongod节点，达到数据分片目的。   |

## 6 参考

[分片集群](https://www.cnblogs.com/duanxz/p/10730121.html)