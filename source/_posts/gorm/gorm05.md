---
title: 高级查询
excerpt: Gorm的高级查询方法
date: 2023-02-19 14:25:31
tags: gorm
banner_img: /img/index.png
index_img: /img/gorm.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 二. 数据库操作 
---

## 1. where语句
### 1.1 精确查询

```go
//	 查询用户名是张三的
var studentList []tudent
DB.Debug().Where("name = ? ", "张三").Find(&studentList) // SELECT * FROM `tb_student` WHERE name = '张三'
fmt.Println(studentList)                               // {1 张三 20 false 0x140002849d0}

// 等价于如下
DB.Debug().Find(&studentList, "name = ?", "张三")
```

```go
// 查询用户名不是张三的
var studentList []Student
DB.Debug().Where("not name = ?", "张三").Find(&studentList) // SELECT * FROM `tb_student` WHERE NOT name = '张三'

fmt.Println(studentList) // [{2 李四 22 false 0x140002849e0} {3 老五 23 false 0x14000284a00} {4 杨七 24 false 0x14000284a20}]

// 等价于
DB.Debug().Not("name = ? ", "张三").Find(&studentList)
```

```go
// 查询用户名是张三、李四的
var studentList []Student
DB.Debug().Where("name in ?", []string{"张三", "李四"}).Find(&studentList) // SELECT * FROM `tb_student` WHERE name in ('张三','李四')
fmt.Println(studentList)                                                 //[{1 张三 20 false 0x140002849e0} {2 李四 22 false 0x14000284a00}]

// 等价于
DB.Find(&studentList, "name in (?)", []string{"张三", "李四"})
```

### 1.2 模糊查询

```go
// 模糊匹配 用户名带杨的
var studentList []Student
DB.Debug().Where("name like ?", "杨%").Find(&studentList) // SELECT * FROM `tb_student` WHERE name like '杨%'
fmt.Println(studentList)                   // [{4 杨七一 24 false 0x14000220b20} {5 杨四 99 true 0x14000220b40}]

// 如下
'杨%'  - > 杨字开头的所有
'杨_'  - > 杨字开头的 两个字的  _代表一个字符
```

```go
// 查找age大于20，且邮箱是qq的
var studentList []Student
DB.Debug().Where("age > ? and email like ?", 22, "%@qq.com").Find(&studentList) // SELECT * FROM `tb_student` WHERE age > 22 and email like '%@qq.com'
fmt.Println(studentList)

// 等价于
DB.Where("age > ?", 22).Where("email like ?", "%@qq.com").Find(&studentList)
```

```go
// 查询gender 为false，且邮箱是qq的
var studentList []Student
DB.Debug().Where("gender = ? or email like ?", false, "%@qq.com").Find(&studentList) // SELECT * FROM `tb_student` WHERE gender = false or email like '%@qq.com'

// 等价于
DB.Where("gender = ?", false).Or("email like ?", "%qq@.com").Find(&studentList)
```

### 1.3 结构体查询

```go
// 使用结构体查询
var studentList []Student
DB.Debug().Where(&Student{Name: "张三"}).Find(&studentList) // SELECT * FROM `tb_student` WHERE `tb_student`.`name` = '张三'

// 注意事项
结构体里面的数据为And关系，如果结构体出现零值，则该字段将不做为查询参数传递
```

```go
// 使用map查询，也会查询零值
DB.Debug().Where(map[string]any{
	"name": "张三",
	"age":  "99",
}).Find(&studentList)
```

## 2 select选中字段

```go
// 使用select 选中字段 可以是多个，只查询当前选中的值，其他的都会赋予零值
var studentList []Student
DB.Debug().Select("name").Find(&studentList) // SELECT `name` FROM `tb_student`
fmt.Println(studentList)                     // [{0 张三 0 false <nil>} {0 李四 0 false <nil>}]
```

## 3. scan语法

```go
// 使用Scan将获取到的指定字段，写入到定义的结构体的 注意大小写
var studentList []Student
type User struct {
	Name string
	Age  int
}
var userList []User

// 此种方法 需要传入表名
DB.Debug().Select("name", "age").Limit(2).Find(&studentList).Scan(&userList)
// SELECT `name`,`age` FROM `tb_student` LIMIT 2
fmt.Println(studentList) //[{0 张三 20 false <nil>} {0 李四 22 false <nil>}]
fmt.Println(userList)    // [{张三 20} {李四 22}]
```

```go
type User struct {
	Name string
	Age  int
}
var userList []User

// 使用model指定表名
DB.Model(Student{}).Select("name", "age").Scan(&userList)
fmt.Println(userList)
```

scan根据column列名进行扫描的，如果结构体字段与表名不一致，需要添加别名如下：

```go
// 此处会将数据库里面的name字段，赋值给Title
type User struct {
	Title string `gorm:"column:name"`
	Age   int
}
```

## 4. 排序

```go
// 按照年龄排序 desc 降序 asc 升序
var studentList []Student
DB.Order("age desc").Find(&studentList)   // SELECT * FROM `tb_student` ORDER BY age desc
fmt.Println(studentList) // [{5 杨四 99 true 0x14000220ac0} {4 杨七一 24 false 0x14000220ae0} {3 老五 23 false 0x14000220b00}]
```

## 5. 分页查询

```go
var studentList []Student
// 每页两条数据  查询第一页
DB.Debug().Limit(2).Offset(0).Find(&studentList) // SELECT * FROM `tb_student` LIMIT 2
// 每页两条数据 查询第二页  offset 为 (页数 - 1) * 查询条数
DB.Debug().Limit(2).Offset(2).Find(&studentList) //  SELECT * FROM `tb_student` LIMIT 2 OFFSET 2
```

## 6. 去重

```go
// 按照年龄去重  Distinct去除重复字段
var ageList []int
DB.Debug().Model(Student{}).Select("age").Distinct("age").Scan(&ageList) // SELECT DISTINCT `age` FROM `tb_student`

// 等价于 将去重字段 手动传入
DB.Debug().Model(Student{}).Select("Distinct age").Scan(&ageList)
```

## 7. 分组查询

```go
// 将 gender 统计分组
type Group struct {
	Count  int `gorm:"column:count(id)"`
	Gender string
}
var groupList []Group
DB.Model(Student{}).Select("count(id)", "gender").Group("gender").Scan(&groupList)
fmt.Println(groupList) // [{4 0} {1 1}]

// 等价于
type Group struct {
	Count  int
	Gender string
}
var groupList []Group
DB.Model(Student{}).Select("count(id) as count", "gender").Group("gender").Scan(&groupList)
```

```go
// 通过group_concat字段可以将查询出的明细列出来
type Group struct {
	Count    int
	Gender   string
	NameList string
}
var groupList []Group
DB.Model(Student{}).Select("group_concat(name) as name_list", "count(id) as count", "gender").Group("gender").Scan(&groupList)
fmt.Println(groupList) // [{4 0 张三,李四,老五,杨七一} {1 1 杨四}]
```

## 8. 执行原生Sql

```go
// 执行原生sql
var studentList []Student
DB.Debug().Raw("select * from tb_student where name =?", "张三").Find(&studentList) // select * from tb_student where name ='张三'
```

## 9. 子查询

使用上次查询的结果作为本次查询的参数。

```go
//	查询大于平均年龄的用户
var studentList []Student
DB.Debug().Where("age > (?)", DB.Model(Student{}).Select("avg(age)")).Find(&studentList) // SELECT * FROM `tb_student` WHERE age > (SELECT avg(age) FROM `tb_student`)
```

## 10. 命名参数

可以使用问号进行传参，但是如果参数太多容易混淆，可以使用匿名参数的方式。

```go
var student Student
DB.Debug().Take(&student, "name = @name and age = @age", sql.Named("name", "杨七一"), sql.Named("age", "24")) // SELECT * FROM `tb_student` WHERE name = '杨七一' and age = '24' LIMIT 1

// 等价如下
DB.Debug().Take(&student, map[string]any{
	"name": "张三",
	"age":  20,
})
```

## 11. find到map

每次都需要定义一个结构体去接受查询的返回结果，可以定义一个通用的map去接收。

```go
var res []map[string]any
DB.Debug().Model(&Student{}).Where("age = 20").Find(&res)
fmt.Println(res) // [map[age:20 email:0x14000220ad0 gender:false id:1 name:张三] map[age:20 email:0x14000220b00 gender:true id:5 name:杨四]]
```

## 12. 查询引用scope

可以在model层写一些通用的查询方式，以后就可以直接调用了

```go
//	查询年龄大于20的
var res []map[string]any
DB.Debug().Model(Student{}).Scopes(age).Find(&res) // SELECT * FROM `tb_student` WHERE age > 20

func age(db *gorm.DB) *gorm.DB {
	return db.Where("age > ?", 20)
}
```