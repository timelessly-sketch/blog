---
title: MongoDB操作指南(一)
date: 2023-02-25 11:36:50
tags: [MongoDB, DevOps]
banner_img: /img/index.png
index_img: /img/mongodb_index.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - 运维系列
  - 二. 日常数据
---

> mongodb是一种存储文档的非关系数据库

## 1. 初见mongodb

mongodb中拥有很多集合，拥有相似内容的文档被归档于同一个集合之下；同一个集合中的文档可以拥有完全不同的字段；每个文档中包含多个字段和对应的值；针对omongdb而言没有提前规划和设计字段的说法，是非关系型数据库的优势。

### 1.1 启动mongodb

```bash
# 容器安装
docker run -d --name test-mongo  library/mongo

# 以mongo shell方式进入容器
docker exec -ti test-mongo mongo
```

## 2. 数据库与集合操作

### 2.1 选择和创建数据库

```bash
# 查看有哪些DB
> show dbs;  

# 使用test db，db里面只有集合那么当前db才是被真真创建
> use test;  # 此时存在内存中没有写入到磁盘里面

# 查看有哪些集合
> show collections;

# 查看当前在那个db
> db
```

保留的数据库名：

- admin：从权限角度来看，这是root数据库。要是一个用户添加到这个数据库，这个用户自动继承所有数据库的权限。一些特殊的数据库命令也只能在这个库运行。
- lloca：这个数据永远不会被复制，可以用来存储限于本地单台服务器的任意集合，此数据库在副本集情况下数据不会被复制。
- config：当前mongo用于分片设置时，config数据库在内部使用，用于保存分片的相关信息。

### 2.2 数据库的删除

```bash
> use test;
switched to db test
# 删除数据库，需要先进入到删除db才能执行
> db.dropDatabase()
{ "ok" : 1 }
```

### 2.3 集合操作

```bash
# 显示创建集合
db.createCollection("")

# 集合删除
db.集合.drop()
```

## 3. 文档基本CRUD

常见字段讲解：

- 文档主键(_id)：每一篇文档的主键皆不相同具有唯一性；除数组以外，其余数据类型都可以作为文档主键。
- 对象主键：默认的文档主键，可快速生成的12字节ID；前四字节就是创建时间，但需注意客户端时间正确，且同一秒钟创建文档，无法完全区分创建顺序。

### 3.1 创建文档

```bash
# db.collection.insertOne() 
# db.collection.insettMany()
# 想要写入的文档内容如下
{ _id: "account1", name: "alice",balance: 100}
# 写入到accounts集合中，没有集合会自动创建集合
db.accounts.insertOne({_id: "account1",name: "alice",balance: 100})
# 回显 { "acknowledged/安全写级别" : true, "insertedId" : "account1" } 成功
```

```bash
# db.collection.insert() 可以创建单个或者多个文档
# 以数组的方式写入两个文档
> db.accounts.insert([{_id: "account5",name: "alic5",balance: 105},{_id: "account6",name: "alic6",balance: 106}])
BulkWriteResult({
	"writeErrors" : [ ],
	"writeConcernErrors" : [ ],
	"nInserted" : 2,
	"nUpserted" : 0,
	"nMatched" : 0,
	"nModified" : 0,
	"nRemoved" : 0,
	"upserted" : [ ]
})
# 当遇到错误时 会返回一个BulkWriteError类型的文档，包含错误信息主键_id等
```

注意：

1. 插入的文档没有_id，会自动生成主键值
2. mongodb中的数字默认为double类型，如果要存储整型，必须使用函数NumberInt，否则取出来可能有问题。
3. 插入当前日期使用new Date()
4. 在批量插入时，如果某条数据插入失败将会终止插入，且已经插入的成功的数据不会回滚。

### 3.2 查询文档

```bash
# 查询所有 collection为查询文档
db['collection'].find()    # 存在特殊字符时可以使用这种方式
db.collection.find()

# 带条件查询 条件为json格式，没有该数据则啥也不反回
db.collection.find({name:"alic6"})
> db.accounts.find({name:"alic6"})
{ "_id" : "account6", "name" : "alic6", "balance" : 106 }
{ "_id" : ObjectId("63f9c8d91c3cf79dd6ce2814"), "name" : "alic6", "balance" : 106 }

# 当查询有多个相同字段内容时，只返回第一条
db.colletion.findOne({})
> db.accounts.findOne({name:"alic6"})
{ "_id" : "account6", "name" : "alic6", "balance" : 106 }
```

```bash
# 投影查询 只返回结果的部分字段
db.collection.find({条件json},{字段:1/0}). # 1显示 0 不显示

> db.accounts.find({name:"alic6"})   # 显示全部字段
{ "_id" : "account6", "name" : "alic6", "balance" : 106 }
{ "_id" : ObjectId("63f9c8d91c3cf79dd6ce2814"), "name" : "alic6", "balance" : 106 }
> db.accounts.find({name:"alic6"},{balance:1})  # 只显示balance字段，但是_id是默认显示字段
{ "_id" : "account6", "balance" : 106 }
{ "_id" : ObjectId("63f9c8d91c3cf79dd6ce2814"), "balance" : 106 }
> db.accounts.find({name:"alic6"},{balance:1,_id:0}).  # 把_id也
{ "balance" : 106 }
{ "balance" : 106 }
```

### 3.3 更新文档

```bash
# 覆盖的修改
db.collection.update({条件jsn},{更新JSON})   # 部分更新需要添加 $set

> db.accounts.find({_id:"account5"}). # 源数据
{ "_id" : "account5", "name" : "alic5", "balance" : 105 }

> db.accounts.update({_id:"account5"},{banlance:NumberInt(1001)}) # 更新 查询条件 + 更新语句  
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })

> db.accounts.find({_id:"account5"})   # 再次查询发现除了更新的字段，其余都数据都已经被覆盖不见啦
{ "_id" : "account5", "banlance" : 1001 }
```

```bash
# 局部修改，通过$set设置只修改部分数据，如果修改字段不匹配，则会为添加操作
> db.accounts.find({_id:"account6"})  # 源数据
{ "_id" : "account6", "name" : "alic6", "balance" : 106 }
> db.accounts.update({_id:"account6"},{$set:{banlance:NumberInt(1001)}})  # 修改 但是没有该字段
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })
> db.accounts.find({_id:"account6"})   # 变成了添加
{ "_id" : "account6", "name" : "alic6", "balance" : 106, "banlance" : 1001 }
> db.accounts.update({_id:"account6"},{$set:{banlance:NumberInt(1002)}})
WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })
> db.accounts.find({_id:"account6"})
{ "_id" : "account6", "name" : "alic6", "balance" : 106, "banlance" : 1002 }
```

```bash
# 批量修改 查询条件需要有相同参数，匹配修改需要添加multi参数
> db.accounts.find()
{ "_id" : "account6", "name" : "alic6", "balance" : 106, "banlance" : 1002 }
{ "_id" : ObjectId("63f9c8d91c3cf79dd6ce2814"), "name" : "alic6", "balance" : 106 }
> db.accounts.update({name:"alic6"},{$set:{balance:NumberInt(0000)}},{multi:true}).  # 更新 需要添加multi参数，否则只更新第一条数据
WriteResult({ "nMatched" : 2, "nUpserted" : 0, "nModified" : 2 })
> db.accounts.find()
{ "_id" : "account6", "name" : "alic6", "balance" : 0, "banlance" : 1002 }
{ "_id" : ObjectId("63f9c8d91c3cf79dd6ce2814"), "name" : "alic6", "balance" : 0 }
```

### 3.4 删除文档

```bash
# 删除文档
db.collection.remove({条件JSON})

# 全部删除
db.colletcion.remove({})

# 只删除id=1的记录
db.collection.remove({_id:"1"})
```

### 3.5 分页查询
```bash
# 统计
db.collection.count({条件JSON},{其他选项})  

# 统计所有
db.collection.count()
```

```bash
# 分页列表查询
# 查询第一条数据
> db.accounts.find({}).limit(1)
{ "_id" : "account5", "banlance" : 1001 }

# 查询第一条数据，这里spik跳过几条数据
> db.accounts.find({}).limit(1).skip(1)
{ "_id" : "account6", "name" : "alic6", "balance" : 0, "banlance" : 1002 }

# 每页二条数据
db.accounts.find({}).limit(2)   # 第一次查询
db.accounts.find({}).limit(2).skip(2)  # 第二次查询
```

sort()方法对数据进行排序，sort()方法可以通过参数指定排序的字段，并使用1和-1来指定排序的方式，其中1为升序排序，而-1位降序排序。

```bash
# 排序查询
db.collection.find().sort({key:1,key2:-})

# 以名字降序
db.accounts.find({}).sort({name:-1})
```

注意：执行顺序sort - > skip - > limit，和书写顺序无关。

### 3.6 其他查询

```bash
# 正则查询
db.collection.find(字段:/正则表达式/)

# name以什么开头的
db.collection.find(name:/^001/)

# name包含什么的
db.collection.find(name:/001/)
```

```bash
# 比较查询
db.collection.find({"field":{$gt:value}}). # 统计field字段 大于 value
$lt 小于、$gte 大于等于、$lte 小于等于、$ne 不等于

# 点赞数大于100的
db.comment.find({likenum:{$gt:NumberInt(700)}})
```

```bash
# 条件查询
db.collection.find({userid:{$in;["1003","1004"]}}). # $in 包含、$nin 不包含

# or 或者 and
# 查找集合中likenum大于700小于2000的文档
db.collection.find({$and:[{likenum:{$get:NumberInt(700)}},{likenum:{$lt:NumberInt(2000}}]})
```

## 4. 索引

索引支持在mongodb中高效地执行查询，如果没有索引，mongodb必须执行全集合扫描，即扫描集合中的每一个文档，以选择与查询语句匹配的文档。这种扫描全集合的查询效率是非常低的，特别在处理大量的数据时，查询可能需要花费几十秒甚至几分钟，这种对于生产来说是非常致命的。

如果查询存在适当的索引，mongodb可以使用该索引限制必须查询的文档数。

索引是特殊的数据结构，它以易于遍历的形式存储集合数据集的一小部分。索引存储特定字段或者一组字段的值，按字段值排序。索引项的排序支持有效的相等匹配和基于范围的查询操作。以外mongodb还可以使用索引中的排序返回排序结果。mongodb索引使用B树数据结构，所以索引必须是支持排序的

### 4.1 索引的类型

- 单字段索引

mongodb支持在文档的单个字段上创建用户定义的升序或者降序索引，称为单字段索引。对于单字段索引的排序操作，索引键的排序顺序并不重要，因为mongodb可以在任何方向上遍历索引。

- 复合索引

mongodb还支持多个字段的用户定义索引，即复合索引。复合索引中列出的字段顺序具有重要意义。例如：如果复合索引由{userid: 1, score: -1}组成，则索引首先需要按userid进行正序排序，然后在每一个userid的值内，在按score倒序排序。

- 其他索引
   - 地理空间索引   为了支持对地理空间坐标数据的有效查询，mongodb提供了两种特殊的索引：返回结果使用平面几何的二维索引和返回结果使用球面几何的二维球面索引。
   - 文本索引   mongodb提供了一种文本索引类型，支持在集合中搜索字符串内容。
   - 哈希索引   为了支持基于散列的分片，mongodb提供了散列索引类型，它对字段的散列进行索引。

### 4.2 索引的管理

```bash
# 查看 一个集合中所有索引的数组
db.collection.getIndexes()

> db.accounts.getIndexes(). # 默认添加_id是索引
[ { "v" : 2, "key" : { "_id" : 1 }, "name" : "_id_" } ]
```

```bash
# 创建 在集合上创建索引,创建的索引名字默认为keys_升序/降序
db.collection.createIndex(keys,options)

# 按照name创建升序索引 - > 索引名字：name_1
db.accounts.createIndex({name:1}) 

# 创建复合索引 name和balance
db.accounts.createIndex({name:-1,balance:1})
```

```bash
# 删除 删除某一个索引
db.colletcion.dropIndex(index)

# 删除name降序的索引
> db.accounts.dropIndex({name:-1})
{ "nIndexesWas" : 4, "ok" : 1 }

# 删除accounts中所有的索引
db.accounts.dropIndexes()
```

## 5. 索引的使用

### 5.1 执行计划

分析查询性能通常使用执行计划(解释计划、explain plan)来查询查询的情况，如查询的时间，是否基于所有查询等。一般想知道建立的索引是否有效，效果如何，都需要通过执行计划来查看。

```bash
# 单纯执行 db.accounts.find({name:"alic5"}) 只会查询结果 添加.explain()参数 查看查询的执行计划 
> db.accounts.find({name:"alic5"}).explain()
{
... ...
		"winningPlan" : {
			"stage" : "COLLSCAN",  # 这里 COLLSCAN 标识全集合扫描 没有走索引
			"filter" : {
				"name" : {
					"$eq" : "alic5"
				}
			},
			"direction" : "forward"
		},
		"rejectedPlans" : [ ]
	},
... ...
```

```bash
# 创建name的索引
> db.accounts.createIndex({name:1})

# 再次查看
> db.accounts.find({name:"alic5"}).explain()
{
... ...
		"winningPlan" : {
			"stage" : "FETCH",  # 这里 FETCH 标识抓取 通过IXSCAN去查询索引的集合
			"inputStage" : {
				"stage" : "IXSCAN",
				"keyPattern" : {
					"name" : 1
				},
				"indexName" : "name_1",
				"isMultiKey" : false,
				"multiKeyPaths" : {
					"name" : [ ]
				},
				"isUnique" : false,
				"isSparse" : false,
				"isPartial" : false,
				"indexVersion" : 2,
				"direction" : "forward",
				"indexBounds" : {
					"name" : [
						"[\"alic5\", \"alic5\"]"
					]
				}
			}
		},
		"rejectedPlans" : [ ]
	},
... ...
}
```

### 5.2 涵盖的查询

当查询条件和查询投影仅包含索引字段时，mongodb直接从索引返回结果，而不扫描任何文档或者将文档带入内存。这些覆盖的查询时非常有效的。

```bash
# 想要查询的字段结果刚好是索引值，此时不扫描任何文档
> db.accounts.find({name:"alic5"},{name:1,_id:0}).explain()
{
... ....
		"winningPlan" : {
			"stage" : "PROJECTION_COVERED",  # 涵盖查询
			"transformBy" : {
				"name" : 1,
				"_id" : 0
			},
			"inputStage" : {
				"stage" : "IXSCAN",
				"keyPattern" : {
					"name" : 1
				},
				"indexName" : "name_1",
				"isMultiKey" : false,
				"multiKeyPaths" : {
					"name" : [ ]
				},
				"isUnique" : false,
				"isSparse" : false,
				"isPartial" : false,
				"indexVersion" : 2,
				"direction" : "forward",
				"indexBounds" : {
					"name" : [
						"[\"alic5\", \"alic5\"]"
					]
				}
			}
		},
		"rejectedPlans" : [ ]
	},
... ....
}
```