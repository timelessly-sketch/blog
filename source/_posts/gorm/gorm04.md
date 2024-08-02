---
title: 创建HOOK
excerpt: 数据库 钩子
date: 2023-02-15 22:12:56
tags: gorm
banner_img: /img/index.png
index_img: /img/gorm.png
show_category: true # 表示强制开启
categories:
  - Go系列
  - 二. 数据库操作 
---
Hook 是在创建、查询、更新、删除等操作之前、之后调用的函数。
如果您已经为模型定义了指定的方法，它会在创建、更新、查询、删除时自动被调用。如果任何回调返回错误，GORM 将停止后续的操作并回滚事务。
在 GORM 中保存、删除操作会默认运行在事务上， 因此在事务完成之前该事务中所作的更改是不可见的，如果您的钩子返回了任何错误，则修改将被回滚。

```go
// 执行钩子函数在创建的时候如果，不给age赋值则采用钩子函数里面的值
type Student struct {
	ID     uint   `gorm:"size:3;primaryKey"`
	Name   string `gorm:"type:varchar(12);comment:用户名"`
	Age    int    `gorm:"size:4"`
	Gender bool
	Email  *string `gorm:"size:32"`
}

// 钩子方法的函数签名应该是 func(*gorm.DB) error
func (s *Student) BeforeCreate(tx *gorm.DB) (err error) {
	s.Age = 99
	return nil
}
```

```go
// 此时在插入的时候age是99，如果赋值也会不生效
DB.Debug().Create(&Student{
	Name: "1-test",
}) // INSERT INTO `tb_student` (`name`,`age`,`gender`,`email`) VALUES ('1-test',99,false,NULL)
```



































