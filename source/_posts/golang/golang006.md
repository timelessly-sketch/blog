---
title: 函数基础的基础
date: 2023-03-07 23:47:04
tags: golang
banner_img: /img/index.png
index_img: /img/golang/golang06_index.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 一. 基础技能
---


## 1. 函数的基本形式

### 1.1 形参与实参

```go
// a,b是形参，函数内部的局部变量，实参的值会拷贝给形参，修改形参不会改变实参的值
// 在形参类型相同时 可以只写一次 如：func add(a,b int) c{}
// 实参 则为调用该函数时传递的参数
func add(a int, b int) int {
	c := a + b
	return c
}
```

```go
// 如果想要通过形参修改实参的值，则需要参入指针类型
func add(a *int, b *int) int {
	*a = *a + *b
	return *a
}
```

### 1.2 可变参数

可变参数是指函数的参数数量不固定。Go语言中的可变参数通过在参数名后加`...`来标识。注意：可变参数通常要作为函数的最后一个参数，如下：

```go
func intSum2(x ...int) int {
	fmt.Println(x) //x是一个切片
	sum := 0
	for _, v := range x {
		sum = sum + v
	}
	return sum
}
```

调用上面的函数：

```go
ret1 := intSum2()
ret2 := intSum2(10)
ret3 := intSum2(10, 20)
ret4 := intSum2(10, 20, 30)
fmt.Println(ret1, ret2, ret3, ret4) //0 10 30 60
```

固定参数搭配可变参数使用时，可变参数要放在固定参数的后面，示例代码如下：

```go
func intSum3(x int, y ...int) int {
	fmt.Println(x, y)
	sum := x
	for _, v := range y {
		sum = sum + v
	}
	return sum
}
```

调用上述函数：

```go
ret5 := intSum3(100)
ret6 := intSum3(100, 10)
ret7 := intSum3(100, 10, 20)
ret8 := intSum3(100, 10, 20, 30)
fmt.Println(ret5, ret6, ret7, ret8) //100 110 130 160
```

本质上，函数的可变参数是通过切片来实现的。

### 1.3 返回值

```go
// 
func calc(x, y int) (int, int) {
	sum := x + y
	sub := x - y
	return sum, sub
}
```

```go
// 返回值
func calc(x, y int) (sum, sub int) {
	sum = x + y
	sub = x - y
	return
}
```

```go
// 当我们的一个函数返回值类型为slice时，nil可以看做是一个有效的slice，没必要显示返回一个长度为0的切片
func someFunc(x string) []int {
	if x == "" {
		return nil // 没必要返回[]int{}
	}
	...
}
```

### 1.4 作为参数与返回值

```go
// 函数可以作为参数
func add(x, y int) int {
	return x + y
}
func calc(x, y int, op func(int, int) int) int {
	return op(x, y)
}
func main() {
	ret2 := calc(10, 20, add)
	fmt.Println(ret2) //30
}
```

```go
// 函数也可以作为返回值
func do(s string) (func(int, int) int, error) {
	switch s {
	case "+":
		return add, nil
	case "-":
		return sub, nil
	default:
		err := errors.New("无法识别的操作符")
		return nil, err
	}
}
```

## 2. 函数类型与变量

可以使用`type`关键字来定义一个函数类型，具体格式如下：

```go
type calculation func(int, int) int
```

上面语句定义了一个`calculation`类型，它是一种函数类型，这种函数接收两个int类型的参数并且返回一个int类型的返回值。简单来说，凡是满足这个条件的函数都是calculation类型的函数，例如下面的add和sub是calculation类型。

```go
func add(x, y int) int {
	return x + y
}

func sub(x, y int) int {
	return x - y
}
```

add和sub都能赋值给calculation类型的变量。

```go
var c calculation
c = add
```

可以声明函数类型的变量并且为该变量赋值：

```go
func main() {
	var c calculation               // 声明一个calculation类型的变量c
	c = add                         // 把add赋值给c
	fmt.Printf("type of c:%T", c) // type of c:main.calculation
	fmt.Println(c(1, 2))            // 像调用add一样调用c

	f := add                        // 将函数add赋值给变量f
	fmt.Printf("type of f:%T", f) // type of f:func(int, int) int
	fmt.Println(f(10, 20))          // 像调用add一样调用f
}
```

## 3. 匿名函数与闭包

### 3.1 匿名函数

函数当然还可以作为返回值，但是在Go语言中函数内部不能再像之前那样定义函数了，只能定义匿名函数。匿名函数就是没有函数名的函数，匿名函数的定义格式如下：

```go
func(参数)(返回值){
    函数体
}
```

匿名函数因为没有函数名，所以没办法像普通函数那样调用，所以匿名函数需要保存到某个变量或者作为立即执行函数:

```go
func main() {
	// 将匿名函数保存到变量
	add := func(x, y int) {
		fmt.Println(x + y)
	}
	add(10, 20) // 通过变量调用匿名函数

	//自执行函数：匿名函数定义完加()直接执行
	func(x, y int) {
		fmt.Println(x + y)
	}(10, 20)
}
```

```go
type user struct {
	name  string
	hello func(name string) string
}

func main() {
	ch := make(chan func(name string) string, 0)

	ch <- func(name string) string {
		return "hello" + name
	}
}
```

匿名函数多用于实现回调函数和闭包。

### 3.2 闭包

闭包是引用了自由变量的函数，自由变量将和函数一起存在，即使离开了创造环境，闭包复制是原对象的指针。

```go
func sub() func() {  // 入参是空，返回值是func()的函数
	i := 10
	fmt.Printf("%p\n",&i)
	b := func() {   // 这个函数将于i一同存在
		fmt.Printf("%p\n",&i)
		i--
		fmt.Println(i)
	}
	return b
}
func main(){
  // _ = sub() // 此时只会执行函数的第一二行代码 输出i的内存地址
    b := sub() // 第一次调用 只会执行函数的第一二行代码 输出i的内存地址，此时的b是一个函数为sub的返回值函数
    b()  // 第一次执行b函数 i = 9
    b()  // 第二次执行b函数 i = 8，所对应的i的内存地址始终没有变过
}
```

```go
func add(base int) func(int)int{
	return func(i int) int {  // 这个返回函数将于base一同存在
		fmt.Printf("%p\n",&base)
		base += i
		return base
	}
}

func main(){
  t := add(10)

  fmt.println(t(1),t(2)) // 11 13 - > 10 + 1 11 + 2

  t2 := add(100)
  fmt.println(t2(1),t2(2)) // 101 103  
}
```


## 4. 延迟处理defer

1. defer用于注册一个延迟调用，在函数返回之前调用，一般用于资源释放场景，如文件句柄释放，数据连接释放等。
2. 如果一个函数里面有多个defer，则后注册先执行
3. defer 后可以跟一个func，如果func内部发生panic，会把panic暂时搁置，当其他defer执行完之后再执行这个
4. defer 后跟的是一条执行语句，则相关变量将在注册defer时被拷贝或计算

```go
func deferExe() (i int) {
	i = 9
	defer func() { // 这里定义了一个匿名函数func(){} + () 这个扩号表示调用该函数 有参数则传参
		fmt.Printf("i=%d\n", i) // i = 5
	}()
	defer fmt.Printf("i=%d\n", i) // i = 9 当执行defer的时候已经将i用了，只是未打印
	return 5                      // 当return 的时候会将 5 赋值给i，会先执行return
}
```

## 5. 异常处理

程序运行期间`funcB`中引发了`panic`导致程序崩溃，异常退出了。这个时候我们就可以通过`recover`将程序恢复回来，继续往后执行。

```go
func funcA() {
	fmt.Println("func A")
}

func funcB() {
	defer func() {
		err := recover()
		//如果程序出出现了panic错误,可以通过recover恢复过来
		if err != nil {
			fmt.Println("recover in B")
		}
	}()
	panic("panic in B")
}

func funcC() {
	fmt.Println("func C")
}
func main() {
	funcA()
	funcB()
	funcC()
}
```