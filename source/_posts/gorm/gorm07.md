---
title: 一对一关系表
date: 2023-02-26 21:03:31
tags: gorm
banner_img: /img/index.png
index_img: /img/gorm.png
show_category: true # 表示强制开启
categories:
  - Go系列
  - 二. 数据库操作 
---
一对一的关系比较少，一般用于表的扩展；把常用的字段放在主表，不常用的字段放在详细表里面。

创建相关表与数据信息，如下：

```go
type User struct {
	ID       uint
	Name     string
	Age      int
	UserInfo *UserInfo
}

type UserInfo struct {
	UserID uint // 外键
	ID     uint
	Addr   string
	Like   string
}

// 自动创建表
DB.AutoMigrate(&User{}, &UserInfo{})
```

## 1. 添加记录

```go
DB.Create(&User{
		Name: "你不知道",
		Age:  8,
		UserInfo: &UserInfo{
			Addr: "天堂",
			Like: "地狱",
		},
	})
```

## 2. 查询

```go
// 根据用户查询用户详细
var u User
DB.Preload("UserInfo").Take(&u)
s, _ := json.Marshal(u)
fmt.Println(string(s))

{"ID":1,"Name":"你不知道","Age":8,"UserInfo":{"UserID":1,"ID":1,"Addr":"天堂","Like":"地狱"}}
```

## 3. 删除

```go
// 删除 先查出来再删除
	var u User
	DB.Take(&u)
	DB.Select("UserInfo").Delete(&u)
```