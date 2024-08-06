---
title: MongoDB诊断(二)
date: 2024-08-02 11:36:50
tags: [MongoDB, DevOps]
banner_img: /img/index.png
index_img: /img/mongodb_index.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - 运维系列
  - 二. 日常数据
---

## 1 db.CurrentOP

db.currentOp是个好东西，顾名思义，就是当前的操作。在mongodb中可以查看当前数据库上此刻的操作语句信息，包括insert/query/update/remove/getmore/command等多种操作。

db.currentOp()一般返回一个空的数组，我们可以指定一个参数true，这样就返回用户connections与系统cmmand相关的操作。

**重点关注以下几个字段：**

| 字段                           | 说明                                                         |
| ------------------------------ | ------------------------------------------------------------ |
| client                         | 请求是由哪个客户端发起的。                                   |
| opid                           | 操作的opid，有需要的话，可以通过db.killOp(opid) 直接终止该操作。 |
| secs_running/microsecs_running | 这个值重点关注，代表请求运行的时间，如果这个值特别大，请看看请求是否合理。 |
| query/ns                       | 这个字段能看出是对哪个集合正在执行什么操作。                 |
| lock*                          | - 还有一些跟锁相关的参数，需要了解可以看官网文档，本文不做详细介绍。 |

**返回信息：**

```json
{
  "inprog": [
       {
         "host" : <string>,
         "desc" : <string>,
         "connectionId" : <number>,
         "client" : <string>,
         "appName" : <string>,
         "clientMetadata" : <document>,
         "active" : <boolean>,
         "currentOpTime" : <string>,
         "opid" : <number>,
         "secs_running" : <NumberLong()>,
         "microsecs_running" : <number>,
         "op" : <string>,
         "ns" : <string>,
         "command" : <document>,
         "originatingCommand" : <document>,
         "planSummary": <string>,
         "msg": <string>,
         "progress" : {
             "done" : <number>,
             "total" : <number>
         },
         "killPending" : <boolean>,
         "numYields" : <number>,
         "locks" : {
             "Global" : <string>,
             "MMAPV1Journal" : <string>,
             "Database" : <string>,
             "Collection" : <string>,
             "Metadata" : <string>,
             "oplog" : <string>
         },
         "waitingForLock" : <boolean>,
         "lockStats" : {
             "Global": {
                "acquireCount": {
                   "r": <NumberLong>,
                   "w": <NumberLong>,
                   "R": <NumberLong>,
                   "W": <NumberLong>
                },
                "acquireWaitCount": {
                   "r": <NumberLong>,
                   "w": <NumberLong>,
                   "R": <NumberLong>,
                   "W": <NumberLong>
                },
                "timeAcquiringMicros" : {
                   "r" : NumberLong(0),
                   "w" : NumberLong(0),
                   "R" : NumberLong(0),
                   "W" : NumberLong(0)
                },
                "deadlockCount" : {
                   "r" : NumberLong(0),
                   "w" : NumberLong(0),
                   "R" : NumberLong(0),
                   "W" : NumberLong(0)
                }
             },
             "MMAPV1Journal": {
                ...
             },
             "Database" : {
                ...
             },
             ...
         }
       },
       ...
   ],
   "fsyncLock": <boolean>,
   "info": <string>,
   "ok": 1
}
```

**返回字段说明：**

```
currentOp.host：运行该操作的主机的名称。
currentOp.desc：客户端的描述。这个字符串包括connectionId。
currentOp.connectionId：操作起源的连接的标识符。
currentOp.client：包含有关操作起源的信息的字符串。
对于多文档事务，客户机存储要在事务中运行操作的最新客户机的信息。
currentOp.appName：包含发出请求的客户机类型信息的字符串。
currentOp.clientMetadata：关于客户端的附加信息。
对于多文档事务，客户机存储要在事务中运行操作的最新客户机的信息。
currentOp.currentOpTime：操作的开始时间。新版本3.6。
currentOp.lsid：会话标识符。仅当操作与会话关联时才显示。新版本3.6
```

```
currentOp.transaction：包含多文档事务信息的文档。仅当操作是事务的一部分时才出现。新版本4.0。
currentOp.transaction.parameters：包含多文档事务信息的文档。仅当操作是事务的一部分时才出现。新版本4.0。
currentOp.transaction.parameters.txnNumber：事务数量。仅当操作是事务的一部分时才出现。新版本4.0。
currentOp.transaction.parameters.autocommit：一个布尔标志，指示事务的自动提交是否打开。仅当操作是事务的一部分时才出现。新版本4.0.2。
currentOp.transaction.parameters.readConcern：事务的read关注点。多文档事务支持读取关注点“快照”、“本地”和“多数”。仅当操作是事务的一部分时才出现。新版本4.0.2。
currentOp.transaction.readTimestamp：事务中的操作正在读取快照的时间戳。仅当操作是事务的一部分时才出现。新版本4.0.2。
currentOp.transaction.startWallClockTime：事务开始的日期和时间(带有时区)。仅当操作是事务的一部分时才出现。新版本4.0.2。
currentOp.transaction.timeOpenMicros事务的持续时间(以微秒为单位)。添加到timeInactiveMicros的timeActiveMicros值应该等于timeOpenMicros。仅当操作是事务的一部分时才出现。新版本4.0.2。
currentOp.transaction.timeActiveMicros：交易活动的总时间;例如，当事务运行操作时。添加到timeInactiveMicros的timeActiveMicros值应该等于timeOpenMicros。仅当操作是事务的一部分时才出现。新版本4.0.2。
currentOp.transaction.timeInactiveMicros：该事务处于非活动状态的总时间;例如，当事务没有运行任何操作时。添加到timeActiveMicros的timeInactiveMicros值应该等于timeOpenMicros。仅当操作是事务的一部分时才出现。
currentOp.transaction.expiryTime：事务超时并中止的日期和时间(带有时区)。
currentOp.transaction：呼气时间等于current .transaction。startWallClockTime + transactionLifetimeLimitSeconds
```

```
currentOp.opid：操作的标识符。您可以将此值传递给mongo shell中的db.killOp()来终止操作。只使用db.killOp()终止客户机发起的操作，而不终止内部数据库操作。
```

**操作时间：**

```
currentOp.secs_running：操作持续时间(以秒为单位)。MongoDB通过从操作开始时减去当前时间来计算这个值。
currentOp.microsecs_running：操作持续时间(以微秒为单位)。MongoDB通过从操作开始时减去当前时间来计算这个值。
```

**操作类型：**

```
currentOp.op：标识操作类型的字符串。
可能的值是:"none"、"update"、"insert"、"query"、"command"、"getmore"、"remove"、"killcursors"
currentOp.ns：操作目标的命名空间。名称空间由数据库名和集合名组成 DB_collection
currentOp.command：在3.6版中进行了更改。包含与此操作关联的完整命令对象的文档。
currentOp.planSummary：包含查询计划的字符串，用于帮助调试慢查询。
currentOp.client：IP地址(或主机名)和发起操作的客户机连接的临时端口。如果您的inprog数组有来自许多不同客户端的操作，请使用此字符串将操作与客户端关联起来。
currentOp.appName：新版本3.4。运行该操作的客户机应用程序的标识符。使用appName连接字符串选项为appName字段设置自定义值。
```

**锁:**

```
currentOp.locks：在3.0版本中进行了更改。locks文档报告操作当前持有的锁的类型和模式。可能的锁类型如下:
1. Global 全局锁
2. Database 数据库锁
3. Collection 集合锁
4. Metadata 元数据锁
5. oplog oplog锁
锁定模式 R 表示共享锁; W　表示排他(X)锁; r　表示共享的意图(IS)锁; w　表示意图独占(IX)锁
currentOp.msg：msg提供一条消息，描述操作的状态和进度。对于索引或mapReduce操作，字段报告完成百分比。
currentOp.progress：报告mapReduce或索引操作的进度。进度字段对应于msg字段中的完成百分比。进度说明了以下信息:
currentOp.progress.done：报告完成的数字。
currentOp.progress.total：报告总数。
currentOp.killPending：如果当前操作被标记为要终止，则返回true。当操作遇到下一个安全终止点时，操作将终止。
currentOp.numYields：numyield是一个计数器，它报告操作已经让步多少次，以允许其他操作完成。
通常，当需要访问MongoDB尚未完全读入内存的数据时，操作会产生收益。这允许其他在内存中有数据的操作在MongoDB为生成操作读入数据时快速完成。
currentOp.fsyncLock：指定当前是否锁定fsync写入/快照的数据库。只有锁定时才会出现;例如，如果fsyncLock为真。
currentOp.info：有关如何从db.fsyncLock()解锁数据库的信息。只有当fsyncLock为真时才会出现。
currentOp.lockStats：对于每种锁类型和模式(参见currentOp)。)，返回以下信息:
currentOp.lockStats.acquireCount：操作以指定模式获取锁的次数。
currentOp.lockStats.acquireWaitCount：操作必须等待acquirecallock获取的次数，因为锁处于冲突模式。acquireWaitCount小于或等于acquirecore。
currentOp.lockStats.timeAcquiringMicros：操作必须等待获取锁的累积时间(以微秒为单位)。时间获取微s除以acquireWaitCount给出了特定锁定模式的平均等待时间。
currentOp.lockStats.deadlockCount：在等待锁获取时，操作遇到死锁的次数。
```

## 2 慢查询日志解析

### 2.1 开启慢查询记录

```bash
db.getProfilingStatus() # 查看慢查询是否开始 记录阈值 如下
{
  "was": 1,  # 开启
  "slowms": 100, # 超过多少算慢查询
  "sampleRate": 1, # 采样率 1 全部
  "ok": 1
}

db.setProfilingLevel(0) # 关闭慢查询记录
db.setProfilingLevel(1, { slowms: 你的阈值, sampleRate: 你的采样率 }) # 开始慢查询
```

### 2.2 查询慢查询

```bash
db.system.profile.find() # 查询慢查询日志 注意是在每一个db下面
# 以js方式查看慢查询日志
db.system.profile.find().forEach(function(item){if (item.millis>1000) printjson(item)})
```

### 2.3 字段解析

```json
{
    "timestamp": "Thu Apr  2 07:51:50.985"  // 日期和时间, ISO8601格式
    "severityLevel": "I"  // 日志级别 I代表info的意思，其他的还有F,E,W,D等
    "components": "COMMAND"  //组件类别，不同组件打印出的日志带不同的标签，便于日志分类
    "namespace": "animal.MongoUser_58"  //查询的命名空间，即<databse.collection>
    "operation": "find" //操作类别，可能是[find,insert,update,remove,getmore,command]
    "command": { find: "MongoUser_58", filter: { $and: [ { lld: { $gte: 18351 } }, { fc: { $lt: 120 } }, { _id: { $nin: [1244093274 ] } }, { $or: [ { rc: { $exists: false } }, { rc: { $lte: 1835400100 } } ] }, { lv: { $gte: 69 } }, { lv: { $lte: 99 } }, { cc: { $in: [ 440512, 440513, 440514, 440500, 440515, 440511, 440523, 440507 ] } } ] }, limit: 30 } //具体的操作命令细节
    "planSummary": "IXSCAN { lv: -1 }", // 命令执行计划的简要说明，当前使用了 lv 这个字段的索引。如果是全表扫描，则是COLLSCAN
    "keysExamined": 20856, // 该项表明为了找出最终结果MongoDB搜索了索引中的多少个key
    "docsExamined": 20856, // 该项表明为了找出最终结果MongoDB搜索了多少个文档
    "cursorExhausted": 1, // 该项表明本次查询中游标耗尽的次数
    "keyUpdates":0,  // 该项表名有多少个index key在该操作中被更改，更改索引键也会有少量的性能消耗，因为数据库不单单要删除旧Key，还要插入新的Key到B-Tree索引中
    "writeConflicts":0, // 写冲突发生的数量，例如update一个正在被别的update操作的文档
    "numYields":6801, // 为了让别的操作完成而屈服的次数，一般发生在需要访问的数据尚未被完全读取到内存中，MongoDB会优先完成在内存中的操作
    "nreturned":0, // 该操作最终返回文档的数量
    "reslen":110, // 结果返回的大小，单位为bytes，该值如果过大，则需考虑limit()等方式减少输出结果
    "locks": { // 在操作中产生的锁，锁的种类有多种，如下
        Global: { acquireCount: { r: 13604 } },   //具体每一种锁请求锁的次数
        Database: { acquireCount: { r: 6802 } }, 
        Collection: { acquireCount: { r: 6802 } } 
    },
    "protocol": "op_command", //  消息的协议
    "millis" : 69132, // 从 MongoDB 操作开始到结束耗费的时间，单位为ms
}
```

```bash
planSummary 执行计划
  COLLSCAN —— 全表扫描
  IXSCAN —— 索引扫描
  IDHACK —— 使用了默认的_id索引
  FETCH —— 根据索引去检索某一个文档
  SHARD_METGE —— 将各个分片的返回数据进行聚合
  SHARDING_FILTER —— 通过mongos对分片数据进行查询
  正常情况下一般都是IXSCAN，如果遇到COLLSCAN导致的慢查询的话，可以考虑新建相应的索引来优化查询了。
  该字段后面会输出具体使用的哪一个索引。有可能一个表有多个索引，当这里的索引不符合预期时，也应该考虑优化索引或者通过hint()来改造查询语句。
```

```bash
writeConflicts 写冲突次数 写是要加写锁的，如果写冲突次数很多，比如多个操作同时更新同一个文档，可能会导致该操作耗时较长，主要就消耗在写冲突这里了。
```





## 3 操作记录

```javascript
db.currentOp() == db.$cmd.sys.inprog.findOne() # 更细一点就db.curretnOp(true)
db.serverStatus().connections # 查看当前链接数

db.currentOp().inprog.forEach(function(item){printjson(item)}); # 已json的格式打印 这里的item就是上面返回信息里面的
db.currentOp().inprog.forEach(function(item){if (item.secs_running > 1 ) print(itme.opid);db.killOp(item.opid)}) # 打印运行时间大于1s的进程的ID并且杀掉他
```

```bash
mongo 连接信息 --eval "db.currentOp().inprog.forEach(function(item){printjson(item)});"
```

