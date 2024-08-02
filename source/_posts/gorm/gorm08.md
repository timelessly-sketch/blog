---
title: 多对多关系表
date: 2023-02-26 21:05:58
tags: gorm
banner_img: /img/index.png
index_img: /img/gorm.png
show_category: true # 表示强制开启
categories:
  - Go系列
  - 二. 数据库操作 
---
多对多关系，需要用第三张表来存储两张表的关系

## 1. 表结构的搭建

此处采用文章与标签的关系进行演示。

```go
type Tag struct {
	ID       uint
	Name     string
	Articles []Article `gorm:"many2many:article_tags;"` // 用于反向引用
}
type Article struct {
	ID    uint
	Title string
	Tags  []Tag `gorm:"many2many:article_tags;"`
}

DB.AutoMigrate(&Tag{}, &Article{}). // 此时会自动创建3张表，tb_article,tb_tag,tb_article_tags  前面lai'n两张为数据表，后面一张为
```

## 2. 多对多添加

```go
//  创建文章的同时，创建tag；如果创建文章的时候关联tag，需要先查询出该tag通过切片方式传入
    DB.Debug().Create(&Article{
		Title: "golang学习",
		Tags: []Tag{
			{
				Name: "go",
			},
			{
				Name: "goo",
			},
		},
	})
	//	执行sql如下
	// INSERT INTO `tb_tag` (`name`) VALUES ('go'),('goo') ON DUPLICATE KEY UPDATE `id`=`id`
	// INSERT INTO `tb_article_tags` (`article_id`,`tag_id`) VALUES (1,1),(1,2) ON DUPLICATE KEY UPDATE `article_id`=`article_id`
	// INSERT INTO `tb_article` (`title`) VALUES ('golang学习')
```

```go
var tag Tag
	DB.Take(&tag, "name = ?", "goo")
	tags := []Tag{tag, Tag{Name: "xxxx"}}
	DB.Create(&Article{Title: "python基础", Tags: tags})
    // 同时添加新的tag和已经存在的tag 已经存在的tag需要先查询出来
```

## 3. 多对多的查询

```go
var a Article
	DB.Debug().Preload("Tags").Take(&a)
	// SELECT * FROM `tb_article_tags` WHERE `tb_article_tags`.`article_id` = 1
	// SELECT * FROM `tb_tag` WHERE `tb_tag`.`id` IN (1,2)
	// SELECT * FROM `tb_article` LIMIT 1
```

## 4. 多对多的更新

```go
// 先删除原有的标签
	var article Article
	DB.Preload("Tags").Take(&article, 1)
	DB.Model(&article).Association("Tags").Delete(article.Tags)

	// 在添加新的标签
	var tag Tag
	DB.Take(&tag, "1")
	DB.Model(&article).Association("Tags").Append(&tag)
```

```go
// 直接替换标签 需要同时查询出w文章表和
	var article Article
	DB.Preload("Tags").Take(&article, 1)
	var tag Tag
	DB.Take(&tag, "3")
	DB.Model(&article).Association("Tags").Replace(&tag)
```

## 5. 自定义连接表

```go
type Tag struct {
	ID   uint
	Name string
	//Articles []Article `gorm:"many2many:article_tags;"` // 用于反向引用
}
type Article struct {
	ID    uint
	Title string
	Tags  []Tag `gorm:"many2many:article_tags;"`
}

type ArticleTag struct {
	ArticleID uint `gorm:"primaryKey"`
	TagID     uint `gorm:"primaryKey"`
	CreateAt  time.Time
}

// 设置Article的Tag表为ArticleTag
DB.SetupJoinTable(&Article{}, "Tags", &ArticleTag{})
// 如果Tag要反向引用Articles，也需要加上
//DB.SetupJoinTable(&Tag{}, "Articles", &ArticleTag{})
if err := DB.AutoMigrate(&Article{}, &Tag{}, &ArticleTag{}); err != nil {
    log.Panic(err)
}
```

## 6. 自定义连接表主键

在进行表关联时，主键的字段都是自动生成，且是固定的 可以通过以下案例进行修改。

```go
joinForeignKey: 连接的主键ID
JoinReferences: 关联的主键

type ArticleModel struct {
	ID    uint
	Title string
	Tags  []TagModel `gorm:"many2many:article_tags;joinForeignKey:ArticleID;JoinReferences:TagID"`
}

type TagModel struct {
	ID       uint
	Name     string
	Articles []ArticleModel `gorm:"many2many:article_tags;joinForeignKey:TagID;JoinReferences:ArticleID"` // 用于反向引用
}

type ArticleTagModel struct {
	ArticleID uint `gorm:"primaryKey"`
	TagID     uint `gorm:"primaryKey"`
	CreateAt  time.Time
}

// 设置Article的Tag表为ArticleTag
DB.SetupJoinTable(&ArticleModel{}, "Tags", &ArticleTagModel{})
// 如果Tag要反向引用Articles，也需要加上
DB.SetupJoinTable(&TagModel{}, "Articles", &ArticleTagModel{})
if err := DB.AutoMigrate(&ArticleModel{}, &TagModel{}, &ArticleTagModel{}); err != nil {
    log.Panic(err)
}
// 最终数据库里面也只会创建三张表
```