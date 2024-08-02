---
title: 模型的定义
excerpt: 定义结构体与数据库字段的之间的关系
date: 2023-02-12 22:51:26
tags: gorm
banner_img: /img/index.png
index_img: /img/gorm.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 二. 数据库操作 
---
# 模型的定义

模型是标准的struct，由Go的基本数据类型组成、实现了Scanner和Valuer接口的自定义类型及其指针或者别名组成；当然GORM 倾向于约定优于配置默认情况下，GORM 使用 `ID` 作为主键，使用结构体名的 `蛇形复数` 作为表名，字段名的 `蛇形` 作为列名，并使用 `CreatedAt`、`UpdatedAt` 字段追踪创建、更新时间；很多字段标签是在定义struct时所必须要了解的部分，本文只列出常用部分，更多请参考[官网-字段标签](https://gorm.io/zh_CN/docs/models.html#%E5%AD%97%E6%AE%B5%E6%A0%87%E7%AD%BE)

## 1. 字段标签

```go
type 			定义字段类型
size 			定义字段大小
column			自定义列名，注意空格 列名将以此为准
primaryKey		将列定义为主键
unique			将列定义为唯一值
default		    定义列的默认值
not null		不可为空
embedded		嵌套字段
enbeddedPrefix嵌套字段前缀  在表嵌套时，所有的嵌套字段都会自动添加该前缀
ocmment		注释
```

举例如下：

```go
type StudentInfo struct {
	Email  *string `gorm:"size:32"` //使用指针是为了存储空值
	Addr   string  `gorm:"column:y_addr;size:16"`
	Gender bool    `gorm:"default:true"`
}

type Student struct {
	Name string      `gorm:"type:varchar(12);not null;comment:用户名"`
	UUID string      `gorm:"primaryKey;unique;comment:主键"`
	Info StudentInfo `gorm:"embedded;embeddedPrefix:_s"`
}
```

执行创建表的SQL语句如下：

```go
CREATE TABLE `tb_students` (
	`name` varchar(12) NOT NULL COMMENT '用户名',
	`uuid` varchar(191) UNIQUE COMMENT '主键',
	`_semail` varchar(32),
	`_sy_addr` varchar(16),
	`_sgender` boolean DE true,
	PRIMARY KEY (`uuid`)
)
```

## 2. 关联标签
GORM 允许通过标签为关联配置外键、约束、many2many 表，详情请参考后续关系表部分。