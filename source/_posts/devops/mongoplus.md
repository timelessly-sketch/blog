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
currentOp.ns：操作目标的命名空间。名称空间由数据库名和集合名组成
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

## 2 慢查询



## 3 操作记录

