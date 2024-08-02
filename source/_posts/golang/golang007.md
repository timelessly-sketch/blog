---
title: 面向接口编程
date: 2023-03-08 21:43:25
tags: golang
banner_img: /img/index.png
index_img: /img/golang/golang07_index.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 一. 基础技能
---
## 1. 接口的基本概念

### 1.1 接口的定义

```go
// 接口是一组行为的集合// 接口是一组行为规范的集合
type Transporter interface { // 通常以er结尾
	// 接口里面只定义方法，不定义变量
	move(src string, dst string) (int, error)
	// 参数列表和返回值列表里面的变量名可以省略
	whistle(int) int
}
```

### 1.2 接口的实现

只要结构体拥有接口里声明的所有方法，就称该结构体 实现了接口，代码如下：

```go
// 定义结构体时无需显式声明他实现了什么接口
type Car struct {
	price int
}

// 只要结构体拥有接口里声明的所有方法，就称该结构体 实现了接口
func (c Car) move(src string, dst string) (int, error) {
	return c.price, nil
}

func (c Car) whistle(n int) int {
	return n
}
```

### 1.3 接口的本质

接口值由两部分组成，一个指向该接口的具体类型的指针和另外一个指向该具体类型真实数据的指针。

```go
var tr Transporter
var c Car
tr = c   // 将c赋值给tr
fmt.Println(tr.whistle(10))   // 此时执行就等价于c.whistle 仅限于实现了的接口

// 类似于， 如下函数式使用
func foo(a Transporter) {
	a.whistle(100)
}

foo(c)
```

### 1.4 接口的赋值

在实现方法时，可以是值类型的接收者也可以是指针类型的接收者，这两者区别如下：

```go
// 在car的值实现了这个接口 使用的是值接收者
func (c Car) whistle(n int) int {
	return n
}
// 赋值
car := Car{}
var tr Transporter
tr = car 或者 tr = &car  // 值实现的方法，指针也实现了
```

从上面的代码中我们可以发现，使用值接收者实现接口之后，不管是结构体类型还是对应的结构体指针类型的变量都可以赋值给该接口变量。

```go
// 是car的指针实现了这个接口 使用的是指针接收者时 需要注意
func (c *Car) whistle(n int) int {
	return n
}
// 赋值
car := Car{}
var tr Transporter
tr = car  // 不行
tr = &car  // 只能使用这种赋值
```

## 2. 接口与类型的关系

### 2.1 一个类型实现多个接口

```go
// Sayer 接口
type Sayer interface {
	Say()
}

// Mover 接口
type Mover interface {
	Move()
}
```

`Dog`既可以实现`Sayer`接口，也可以实现`Mover`接口。

```go
type Dog struct {
	Name string
}

// 实现Sayer接口
func (d Dog) Say() {
	fmt.Printf("%s会叫汪汪汪
", d.Name)
}

// 实现Mover接口
func (d Dog) Move() {
	fmt.Printf("%s会动
", d.Name)
}
```

同一个类型实现不同的接口互相不影响使用。

```go
var d = Dog{Name: "旺财"}

var s Sayer = d
var m Mover = d

s.Say()  // 对Sayer类型调用Say方法
m.Move() // 对Mover类型调用Move方法
```

### 2.2 多种类型实现同一个接口

```go
// 实现Mover接口
func (d Dog) Move() {
	fmt.Printf("%s会动", d.Name)
}

// Car 汽车结构体类型
type Car struct {
	Brand string
}

// Move Car类型实现Mover接口
func (c Car) Move() {
	fmt.Printf("%s速度70迈", c.Brand)
}
```

这样我们在代码中就可以把狗和汽车当成一个会动的类型来处理，不必关注它们具体是什么，只需要调用它们的`Move`方法就可以了。

```go
var obj Mover

obj = Dog{Name: "旺财"}
obj.Move()

obj = Car{Brand: "宝马"}
obj.Move()
```

一个接口的所有方法，不一定需要由一个类型完全实现，接口的方法可以通过在类型中嵌入其他类型或者结构体来实现。

```go
// WashingMachine 洗衣机
type WashingMachine interface {
	wash()
	dry()
}

// 甩干器
type dryer struct{}

// 实现WashingMachine接口的dry()方法
func (d dryer) dry() {
	fmt.Println("甩一甩")
}

// 海尔洗衣机
type haier struct {
	dryer //嵌入甩干器
}

// 实现WashingMachine接口的wash()方法
func (h haier) wash() {
	fmt.Println("洗刷刷")
}
```

## 3. 接口嵌套

```go
type Steamer interface {
	Transporter // 嵌套该接口，相当于Transporter是Steamer的字集
	displacement() int
}
```

对于这种由多个接口类型组合形成的新接口类型，同样只需要实现新接口类型中规定的所有方法就算实现了该接口类型。

接口也可以作为结构体的一个字段，我们来看一段Go标准库`sort`源码中的示例。

```go
// src/sort/sort.go

// Interface 定义通过索引对元素排序的接口类型
type Interface interface {
    Len() int
    Less(i, j int) bool
    Swap(i, j int)
}


// reverse 结构体中嵌入了Interface接口
type reverse struct {
    Interface
}
```

通过在结构体中嵌入一个接口类型，从而让该结构体类型实现了该接口类型，并且还可以改写该接口的方法。

```go
// Less 为reverse类型添加Less方法，重写原Interface接口类型的Less方法
func (r reverse) Less(i, j int) bool {
	return r.Interface.Less(j, i)
}
```

`Interface`类型原本的`Less`方法签名为`Less(i, j int) bool`，此处重写为`r.Interface.Less(j, i)`，即通过将索引参数交换位置实现反转。

在这个示例中还有一个需要注意的地方是`reverse`结构体本身是不可导出的（结构体类型名称首字母小写），`sort.go`中通过定义一个可导出的`Reverse`函数来让使用者创建`reverse`结构体实例。

```go
func Reverse(data Interface) Interface {
	return &reverse{data}
}
```

这样做的目的是保证得到的`reverse`结构体中的`Interface`属性一定不为`nil`，否者`r.Interface.Less(j, i)`就会出现空指针panic。

## 4. 空接口

空接口是指没有定义任何方法的接口类型。因此任何类型都可以视为实现了空接口。也正是因为空接口类型的这个特性，空接口类型的变量可以存储任意类型的值。

```go
package main

import "fmt"

// 空接口

// Any 不包含任何方法的空接口类型
type Any interface{}

// Dog 狗结构体
type Dog struct{}

func main() {
	var x Any

	x = "你好" // 字符串型
	fmt.Printf("type:%T value:%v
", x, x)
	x = 100 // int型
	fmt.Printf("type:%T value:%v
", x, x)
	x = true // 布尔型
	fmt.Printf("type:%T value:%v
", x, x)
	x = Dog{} // 结构体类型
	fmt.Printf("type:%T value:%v
", x, x)
}
```

通常我们在使用空接口类型时不必使用`type`关键字声明，可以像下面的代码一样直接使用`interface{}`。

```go
var x interface{}  // 声明一个空接口类型变量x
```

```go
// 空接口作为函数参数
func show(a interface{}) {
	fmt.Printf("type:%T value:%v
", a, a)
}
```

```go
// 空接口作为map值，可以保存任意类型的值
  var studentInfo = make(map[string]interface{})
  studentInfo["name"] = "沙河娜扎"
  studentInfo["age"] = 18
  studentInfo["married"] = false
  fmt.Println(studentInfo)
```

## 5. 类型断言

```go
func check(i interface{}) {
	if v, ok := i.(int); ok {
		fmt.Println("i is int", v)
	} else {
		fmt.Println("i is not int", v)
	}
}
```

```go
// justifyType 对传入的空接口类型变量x进行类型断言
func justifyType(x interface{}) {
	switch v := x.(type) {
	case string:
		fmt.Printf("x is a string，value is %v\n", v)
	case int:
		fmt.Printf("x is a int is %v\n", v)
	case bool:
		fmt.Printf("x is a bool is %v\n", v)
	default:
		fmt.Println("unsupport type！")
	}
}
```

只有当有两个或两个以上的具体类型必须以相同的方式进行处理时才需要定义接口。切记不要为了使用接口类型而增加不必要的抽象，导致不必要的运行时损耗。

请牢记接口是一种类型，一种抽象的类型。区别于我们在之前提到的那些具体类型（整型、数组、结构体类型等），它是一个只要求实现特定方法的抽象类型。

面的代码可以在程序编译阶段验证某一结构体是否满足特定的接口类型。

```go
// 摘自gin框架routergroup.go
type IRouter interface{ ... }

type RouterGroup struct { ... }

var _ IRouter = &RouterGroup{}  // 确保RouterGroup实现了接口IRouter
```

## 6. 面向接口编程

```go
// 定义一个支付的接口 让wc、zf都实现该接口
type payer interface {
	pay(int) error
}

type wc struct{}

func (w *wc) pay(int) error {
	fmt.Println("wc 10")
	return nil
}

type zf struct{}

func (z *zf) pay(int) error {
	fmt.Println("zf 20")
	return nil
}
// 检查付款的方式 是wc、
func CheckOut(obj payer) {
	obj.pay(100)
}

func main() {
	CheckOut(&wc{})
	CheckOut(&zf{})
}
```