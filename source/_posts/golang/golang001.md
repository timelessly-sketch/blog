---
title: 常量与变量
date: 2023-03-04 14:11:00
tags: golang
banner_img: /img/index.png
index_img: /img/golang/golang01_index.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 一. 基础技能
---
## 1. 变量的声明

```bash
// 标准声明
var 变量名 变量类型


// 批量声明
var (
    a string
    b int
    c bool
    d float32
)
```

## 2. 变量的初始化

Go语言在声明变量的时候，会自动对变量对应的内存区域进行初始化操作。每个变量会被初始化成其类型的默认值，例如： 整型和浮点型变量的默认值为`0`。 字符串变量的默认值为`空字符串`。 布尔型变量默认为`false`。 切片、函数、指针变量的默认为`nil`

```bash
// 声明时初始化
var 变量名 类型 = 表达式
var name, age = "shiyi", 20

// 函数内部初始化 可以使用短符号
m := 200
```

匿名变量不占用命名空间，不会分配内存，所以匿名变量之间不存在重复声明。

```bash
_ = 2 + 4
```

## 3. 常量

常量必须在定义时赋值，且程序运行期间不能修改。

```bash
const pi = 3.1415
const e = 2.7182

// 或者  此时n1、n2、n3的值一样
const (
    n1 = 100
    n2
    n3
)
```

## 4. itoa

`iota`在const关键字出现时将被重置为0。const中每新增一行常量声明将使`iota`计数一次。

```bash
const (
  	a = iota    // 0
	b           // 1           
	c           // 2
)

const (
	d = iota    // 0
	e           // 1
	_
	g.          // 3
)

const (
	h = iota    // 0
	i = 10      // 10
  	j           // 10
	k           // 10
)

const (
	h = iota    // 0
	i = 10      // 10 
	j = iota    // 2
	k           // 3
)

const (
		a, b = iota + 1, iota + 2 //1,2
		c, d                      //2,3
		e, f                      //3,4
	)
```

```bash
const (
		_  = iota
		KB = 1 << (10 * iota)
		MB = 1 << (10 * iota)
		GB = 1 << (10 * iota)
		TB = 1 << (10 * iota)
		PB = 1 << (10 * iota)
	)
```