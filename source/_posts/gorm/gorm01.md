---
title: 连接数据库
excerpt: 直接点，让我们开始吧
date: 2023-02-12 20:40:11
tags: gorm
banner_img: /img/index.png
index_img: /img/gorm.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 二. 数据库操作 
---
# 连接数据库

Golang的奇妙ORM库，在众多数据库工具中已经赢得很大部分开发者的好评；在此记录相关常用操作，以防[不时之需](https://gorm.io/zh_CN/docs/index.html)😁。

## 1. 安装

```Bash
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

## 2. 连接

```Bash
import (
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var DB *gorm.DB

func InitDB() {
	host := "127.0.0.1"
	port := 3306
	username := "root"
	password := "123456"
	dbname := "db_test"

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local", username, password, host, port, dbname)
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalln("连接数据库失败,", err)
		return
	}
	DB = db
	log.Println("连接数据成功")
}
```
在gorm.Config{}中提供了一些数据库高级配置，比如命名策略、大小写转换、默认字段长度、重命名列等，可以按需修改。

## 3. 命名策略

gorm采用的命名策略是表名是复数，字段名是单数，如下 **但在实际生产中都不会自动创建表，数据库都是又运维统一控制**

```go
//  建议表名和字段都大写，小写不会生成字段
type Dog struct {
	Id   uint
	Name string
}

err := DB.AutoMigrate(&Dog{})

// 自动生成的表结构如下
mysql> desc dogs;
+-------+-----------------+------+-----+---------+----------------+
| Field | Type            | Null | Key | Default | Extra          |
+-------+-----------------+------+-----+---------+----------------+
| id    | bigint unsigned | NO   | PRI | NULL    | auto_increment |
| name  | longtext        | YES  |     | NULL    |                |
+-------+-----------------+------+-----+---------+----------------+
2 rows in set (0.01 sec)
```
也可以修改策略，添加固定的表前缀，大小写转换等，在初始化数据库时采用如下配置：
```go
db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		NamingStrategy: schema.NamingStrategy{
			TablePrefix:   "tb_", //表名前缀
			SingularTable: false, // 单数表名
			NoLowerCase:   true,  //打开大小写转换
		},
	})
```

## 4. 日志

如果要想显示执行的SQL日志，开启日志就能查看数据库中详细执行的SQL语句，不建议全局开启，可以在关键性SQL开启，方法如下配置：

```go
db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),  // 日志级别，为全局配置
	})
```

如果想查询某些语句的日志，可以修改为如下：

```go
DB.Debug().AutoMigrate(&UserName{})
```
