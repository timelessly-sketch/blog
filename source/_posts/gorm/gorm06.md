---
title: 一对多关系表
date: 2023-02-26 20:56:33
tags: gorm
banner_img: /img/index.png
index_img: /img/gorm.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 二. 数据库操作 
---

在gorm的官方文档中，把一对多的关系分为两类，Belongs To 我属于谁、Has Many 我拥有谁。

## 1. 重写外键关联

```go
// User 用户表
type User struct {
	Id       uint
	Name     string
	Articles []Article
}

// Article 文章列表
type Article struct {
	Id     uint
	Title  string
	UserId uint
	User   User
}

如上， 一个用户可以有多篇文章，一篇文章只属于一个用户
对于文章表而言，在数据库层面他有一个外键就是User_id， 需要注意的是外键的两张表字段类型、大小 都需要完全一致,命名也有规范
```

针对如上复杂情况，可以重写外键进行关联。

```go
// User 用户表
type User struct {
	Id       uint
	Name     string
	Articles []Article `gorm:"foreignKey:ArticleId"`
}

// Article 文章列表
type Article struct {
	Id     uint
	Title  string
	ArticleId uint
	User   User `gorm:"foreignKey:ArticleId"`  用ArticleId这个字段去关联User这个表
}
修改了Article将UserId作为外键，那么User也要讲外键指向ArticleId
```

## 2. 一对多添加

```go
DB.Debug().Create(&User{
	Name: "张三",
	Articles: []Article{
		{
			Title: "golang",
		},
		{
			Title: "python",
		},
	},
})
```

```go
//	 创建关联已有表内容
DB.Debug().Create(&Article{
	Title: "测试001",
	User: User{
		Name: "张三",
	},
})
DB.Debug().Create(&Article{
	Title:  "测试002",
	UserId: 2,
})
```

```go
// 给已有用户绑定文章
var User User
DB.Take(&User, 1)
var article Article
DB.Take(&article, 6)
DB.Model(&User).Association("Articles").Append(&article)
```

## 3. 一对多查询
预加载 预加载使用的名字是外键关联的属性名

```go
//	预加载 如果不适用预加载只能查询到用户的id 查不到具体的信息
var article Article
DB.Preload("User").Take(&article)
fmt.Println(article) // {1 golang 1 {1 张三 []}}
```
```go
// 查询某个用户下面有多少个文章
var user User
// 查询全部用户的
DB.Preload("Articles").Take(&user)
// 查询文章id小于2的
DB.Preload("Articles", "id < ?", 2).Take(&user)

// 等价于 如下
DB.Preload("Articles", func(db *gorm.DB) *gorm.DB {
	return db.Where("id < ?", 2)
}).Take(&user)
```

## 4. 一对多删除
### 4.1 清楚外键关联

```go
// 清楚外键关联，并不会真正删除数据
// 删除用户，删除相关文章的用户ID
var user User
DB.Preload("Articles").Take(&user, 2)  // 用户关联的文章都先查出来
DB.Model(&user).Association("Articles").Delete(&user.Articles)   // 清理用户关联的文章外键
DB.Delete(&user)   // 在删除用户，保留文章
```

### 4.2 直接删除数据

```go
// 删除 先查出来再删除
var u User
DB.Debug().Take(&u) //  SELECT * FROM `tb_user` LIMIT 1
DB.Debug().Select("UserInfo").Delete(&u)
// DELETE FROM `tb_user_info` WHERE `tb_user_info`.`user_id` = 2
// DELETE FROM `tb_user` WHERE `tb_user`.`id` = 2
```