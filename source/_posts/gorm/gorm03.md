---
title: 单表常用操作
excerpt: 单表常用的CURD操作
date: 2023-02-15 21:32:50
tags: gorm
banner_img: /img/index.png
index_img: /img/gorm.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 二. 数据库操作 
---

在实践`Gorm`相关操作之前，我们需要先创建一个表，基础字段信息如下：
```go
type Student struct {
	ID     uint    `gorm:"size:3;primaryKey"`
	Name   string  `gorm:"type:varchar(12);comment:用户名"`
	Age    int     `gorm:"size:4"`
	Gender bool   
	Email  *string `gorm:"size:32"`
}
```

## 1. 添加单条记录
```go
email := "x@qq.com"
	s := Student{
		Name:   "007-test",
		Age:    32,
		Gender: false,
		Email:  &email,
	}
	if DB.Create(&s).Error != nil {
		log.Println("创建成功")
	}
```
注意：

1. 如果什么都不传，**除了自增主键外其余值为当前类型的零值**；定义时如果为指针，则为null值。
2. 针对bool类型，在数据中fasle标识为0，true标识为1
3. 由于传递的时候是指针，在执行完create之后，s这个对象也能查询到id这个值，有默认值也会带默认值
## 2. 批量插入

批量插入，就需要构建对象的切片，一次全部插入：

```go
var studentList []Student
	for i := 0; i < 3; i++ {
		student := Student{
			Name:  fmt.Sprintf("100%d", i),
			Age:   i,
			Email: nil,
		}
		studentList = append(studentList, student)
	}
	if DB.Create(&studentList).Error != nil {
		return
	}
```

## 3. 查询单条记录
### 3.1 根据主键查询

```go
// 按照主键排序
// 查询第一条
var f Student
DB.Debug().First(&f) // SELECT * FROM `tb_student` ORDER BY `tb_student`.`id` LIMIT 1

// 查询最后一条
var l Student
DB.Debug().Last(&l) //  SELECT * FROM `tb_student` ORDER BY `tb_student`.`id` DESC LIMIT 1

// 根据主键查询 此处主键是id = 6，如果主键不存则会报错，此时报错可以进行捕获
var priKey Student
DB.Debug().Take(&priKey, 6) // SELECT * FROM `tb_student` WHERE `tb_student`.`id` = 6 LIMIT 1
```

```go
// 主键不存在的情况
var priKeyNotFound Student
if DB.Debug().Take(&priKeyNotFound, 100).Error == gorm.ErrRecordNotFound {
	fmt.Println("主键不存在")
}
```

### 3.2 根据其他条件查询

```go
// 按照其他字段进行查询，但是也只查询一条，使用?进行参数传递能有效防止sql注入问题
var otherKey Student
DB.Debug().Take(&otherKey, "name = ?", "008-test") // SELECT * FROM `tb_student` WHERE name = '008-test' LIMIT 1
fmt.Println(otherKey)
```

### 3.3 根据struct查询

```go
// 查询第一条
var s Student
DB.Debug().Take(&s)      // SELECT * FROM `tb_student` LIMIT 1
fmt.Println(s, *s.Email) // {1 008-test 80 false 0x14000220ae0} 8@qq.com 最后一个存储的是指针
```

### 3.4 获取查询条数

```go
fmt.Println(DB.Find(&otherKey).RowsAffected) // 1
```

## 4. 查询多条记录

```go
//查询多条记录 不跟条件默认查询全部
var studentList []Student
DB.Debug().Find(&studentList, "Email = ?", "8@qq.com") // SELECT * FROM `tb_student` WHERE Email = '8@qq.com'
for _, v := range studentList {
	fmt.Println(v)
}
//  {1 008-test 80 false 0x140002210d0}
//  {6 0098-test 11 false 0x140002210f0}

//	由于Email为指针类型，通过序列化，转化JSON可以直接查看
for _, v := range studentList {
	data, _ := json.Marshal(&v)
	fmt.Println(string(data))
}
// {"ID":1,"Name":"008-test","Age":80,"Gender":false,"Email":"8@qq.com"}
// {"ID":6,"Name":"0098-test","Age":11,"Gender":false,"Email":"8@qq.com"}
```

### 4.1 根据主键列表查询

```go
// 根据主键列表去查询
var studentListByPriKey []Student
DB.Debug().Find(&studentListByPriKey, []int{1, 3, 5}) // SELECT * FROM `tb_student` WHERE `tb_student`.`id` IN (1,3,5)
fmt.Println(studentListByPriKey)                      // [{1 008-test 80 false 0x14000221350} {3 0010-test 0 true <nil>} {5 1000 0 false <nil>}]
```

### 4.2 根据其他添加去查询

```go
var studentListByOther []Student
DB.Debug().Find(&studentListByOther, "name in (?)", []string{"0098-test", "0099-test"}) // SELECT * FROM `tb_student` WHERE name in ('0098-test','0099-test')
fmt.Println(studentListByOther)            // [{6 0098-test 11 false 0x14000285360} {7 0099-test 32 true 0x14000285380}]
```

## 5. 更新数据
### 5.1 单个记录的全字段更新

```go
// save 用于保存所有字段，即使是零值也会保存
var studentOne Student
DB.Debug().Take(&studentOne, "name = ?", "007-test") // SELECT * FROM `tb_student` WHERE name = '007-test' LIMIT 1
studentOne.Name = "20259-test"
DB.Debug().Save(&studentOne) // UPDATE `tb_student` SET `name`='20259-test',`age`=32,`gender`=true,`email`='99@qq.com' WHERE `id` = 7
```

### 5.2 更新指定的字段

```go
// 通过Select更新指定字段
var studentOne Student
DB.Debug().Take(&studentOne, "name = ?", "007-test") // SELECT * FROM `tb_student` WHERE name = '007-test' LIMIT 1
studentOne.Name = "20259-test"
DB.Debug().Select("name").Save(&studentOne) // UPDATE `tb_student` SET `name`='20259-test' WHERE `id` = 7
```

### 5.3 批量更新

```go
var studentList Student
DB.Debug().Find(&studentList, []int{1, 2}).Update("gender", true) // UPDATE `tb_student` SET `gender`=true WHERE `tb_student`.`id` IN (1,2) AND `id` IN (1,2)
```

### 5.4 更新多列

```go
// 批量更新多个数据，用结构体的方式零值是不会更改的，需要使用map
DB.Debug().Find(&studentList, []int{2, 3}).Updates(Student{
	Age:    100,
	Gender: true,
}) // UPDATE `tb_student` SET `age`=100,`gender`=true WHERE `tb_student`.`id` IN (2,3) AND `id` IN (2,3)

DB.Debug().Find(&studentList, []int{3, 4}).Updates(map[string]any{
	"name": "007-f",
}) //  UPDATE `tb_student` SET `name`='007-f' WHERE `tb_student`.`id` IN (3,4) AND `id` IN (3,4)
```

## 6. 删除数据

```go
// 根据主键删除
var student Student
DB.Debug().Delete(&student, 3) // DELETE FROM `tb_student` WHERE `tb_student`.`id` = 3
DB.Debug().Delete(&student, []int{2, 5}) // DELETE FROM `tb_student` WHERE `tb_student`.`id` IN (2,5)

// 先查找到该数据在删除
```
## 7. 总结
针对数据库的操作，其实就是增删改查，针对`Gorm`而言涉及操作的关键字如下：
|    | 单个对象                        | 多个对象                  |
| -- | --------------------------- | --------------------- |
| 添加 | Crate                       | Crate + []student     |
| 查询 | First(主键)、last(主键)、Take(条件) | Find + []student + 条件 |
| 修改 | save(全字段)、select(指定字段)      | update(批量某字段)         |
| 删除 | delete(根据主键删除)、先查询在删除       | 条件in                  |