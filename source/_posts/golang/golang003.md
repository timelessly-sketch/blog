---
title: 基本数据类型
date: 2023-03-04 20:58:49
tags: golang
banner_img: /img/index.png
index_img: /img/golang/golang03_index.png
show_category: true # 表示强制开启
categories:
  - Go系列
  - 一. 基础技能
---

## 1. 基本数据类型

### 1.1 整型

整型分为以下两个大类： 按长度分为：int8、int16、int32、int64 对应的无符号整型：uint8、uint16、uint32、uint64。其中，`uint8`就是我们熟知的`byte`型。

| **类型**  | **描述**                                                 |
| ------- | ------------------------------------------------------ |
| uint8   | 无符号 8位整型 (0 到 255)                                     |
| uint16  | 无符号 16位整型 (0 到 65535)                                  |
| uint32  | 无符号 32位整型 (0 到 4294967295)                             |
| uint64  | 无符号 64位整型 (0 到 18446744073709551615)                   |
| int8    | 有符号 8位整型 (-128 到 127)                                  |
| int16   | 有符号 16位整型 (-32768 到 32767)                             |
| int32   | 有符号 32位整型 (-2147483648 到 2147483647)                   |
| int64   | 有符号 64位整型 (-9223372036854775808 到 9223372036854775807) |
| uint    | 32位操作系统上就是`uint32`，64位操作系统上就是`uint64`                  |
| int     | 32位操作系统上就是`int32`，64位操作系统上就是`int64`                    |
| uintptr | 无符号整型，用于存放一个指针                                         |

```go
var a int = 10
fmt.Printf("%d \n", a)  // 10
fmt.Printf("%b \n", a)  // 1010  占位符%b表示二进制

// 八进制  以0开头
var b int = 077
fmt.Printf("%o \n", b)  // 77

// 十六进制  以0x开头
var c int = 0xff
fmt.Printf("%x \n", c)  // ff
fmt.Printf("%X \n", c)  // FF
```

### 1.2 浮点类型

Go语言支持两种浮点型数：`float32`和`float64`

```go
fmt.Printf("%f\n", math.Pi)   // 3.141593
fmt.Printf("%.2f\n", math.Pi) // 3.14
```

### 1.3 bool类型

Go语言中以`bool`类型进行声明布尔型数据，布尔型数据只有`true（真）`和`false（假）`两个值。

**注意：**

1. 布尔类型变量的默认值为`false`。
2. Go 语言中不允许将整型强制转换为布尔型.
3. 布尔型无法参与数值运算，也无法与其他类型进行转换。

## 2. 类型定义与类型别名
### 2.1 自定义类型

在Go语言中有一些基本的数据类型，如`string`、`整型`、`浮点型`、`布尔`等数据类型， Go语言中可以使用`type`关键字来定义自定义类型。

自定义类型是定义了一个全新的类型。我们可以基于内置的基本类型定义，也可以通过struct定义。例如：

```go
//将MyInt定义为int类型
type MyInt int
```

通过`type`关键字的定义，`MyInt`就是一种新的类型，它具有`int`的特性

### 2.2 类型别名

型别名规定：TypeAlias只是Type的别名，本质上TypeAlias与Type是同一个类型。就像一个孩子小时候有小名、乳名，上学后用学名，英语老师又会给他起英文名，但这些名字都指的是他本人。

```go
type TypeAlias = Type
```

我们之前见过的`rune`和`byte`就是类型别名，他们的定义如下：

```go
type byte = uint8
type rune = int32
```

### 2.3 区别

类型别名与类型定义表面上看只有一个等号的差异，但他们之间存在区别。

```go
//类型定义
type NewInt int

//类型别名
type MyInt = int

func main() {
	var a NewInt
	var b MyInt
	
	fmt.Printf("type of a:%T", a) //type of a:main.NewInt
	fmt.Printf("type of b:%T", b) //type of b:int
}
```

结果显示a的类型是`main.NewInt`，表示main包下定义的`NewInt`类型。b的类型是`int`。`MyInt`类型只会在代码中存在，编译完成时并不会有`MyInt`类型


## 3 字符串

### 3.1 常用方法

| **方法**                              | **介绍**  |
| ----------------------------------- | ------- |
| len(str)                            | 求长度     |
| \+或fmt.Sprintf或 strings.Builder     | 拼接字符串   |
| strings.Split                       | 分割      |
| strings.contains                    | 判断是否包含  |
| strings.HasPrefix,strings.HasSuffix | 前缀/后缀判断 |
| strings.Index(),strings.LastIndex() | 子串出现的位置 |
| strings.Join(a[]string, sep string) | join操作  |

### 3.2 byte和rune

string中每一个元素叫字符，字符有两种：

- byte：1个字节，代表ASCII码的一个字符
- rune：4个字节，代表一个UTF-8字符，一个汉字可用一个rune表示

string底层就是byte数组，string的长度就是该byte数组的长度，UTF-8编码下一个汉字占3个byte，即一个汉字占三个长度

string是常量，不能修改其中的字符，可以将string转为[]byte或者rune类型在修改其值

```go
func changeString() {
	s1 := "big"
	// 强制类型转换
	byteS1 := []byte(s1)
	byteS1[0] = 'p'
	fmt.Println(string(byteS1))

	s2 := "白萝卜"
	runeS2 := []rune(s2)
	runeS2[0] = '红'
	fmt.Println(string(runeS2))
}
```

## 4 类型转换

Go语言中只有强制类型转换，没有隐式类型转换，如下：

```bash
T(表达式)  // T表示要转换的类型
```

1. byte和int可以相互转换
2. float与int可以相互转换，小数位会丢失
3. bool和int不能互相转换
4. string可以转换为[]byte或者[]rune类型，byte或rune可以转为string类型
5. 低精度向高精度转换没有类型，高精度向低精度转换会丢失位数
6. 无符号向有符号转换，最高位是符号位

## 5.  数组

数组是一块连续的内存空间，在声明的时候必须指定长度，且长度不能改变。所以数组在声明的时候就可以把内存空间分配好，并且附上默认值，即完成数组的初始化。

### 5.1 数组定义

```go
var 数组名 [元素数量]T

var a [3]int
var b [4]int
a = b //不可以这样做，因为此时a和b是不同的类型
```

### 5.2 数组的初始化

```go
// 使用初始化列表来设置数组的元素值
var testArray [3]int                        //数组会初始化为int类型的零值
var numArray = [3]int{1, 2}                 //使用指定的初始值完成初始化
var cityArray = [3]string{"北京", "上海", "深圳"} //使用指定的初始值完成初始化
```

```go
// 编译器自行推断个数
var testArray [3]int
var numArray = [...]int{1, 2}
var cityArray = [...]string{"北京", "上海", "深圳"}
fmt.Println(testArray)                          //[0 0 0]
fmt.Println(numArray)                           //[1 2]
fmt.Printf("type of numArray:%T\n", numArray)   //type of numArray:[2]int
fmt.Println(cityArray)                          //[北京 上海 深圳]
fmt.Printf("type of cityArray:%T\n", cityArray) //type of cityArray:[3]string
```

```go
// 指定索引来初始化数组
a := [...]int{1: 1, 3: 5}
fmt.Println(a)                  // [0 1 0 5]
fmt.Printf("type of a:%T\n", a) //type of a:[4]int
```

### 5.3 数组的遍历

```go
func main() {
	var a = [...]string{"北京", "上海", "深圳"}
	// 方法1：for循环遍历
	for i := 0; i < len(a); i++ {
		fmt.Println(a[i])
	}

	// 方法2：for range遍历
	for index, value := range a {
		fmt.Println(index, value)
	}
```

### 5.4 数值是值类型

数组是值类型，赋值和传参会复制整个数组。因此改变副本的值，不会改变本身的值。建议传指针。`[n]*T`表示指针数组，`*[n]T`表示数组指针。

```go
func modifyArray(x [3]int) {
	x[0] = 100
}

func main() {
	a := [3]int{10, 20, 30}
	modifyArray(a) //在modify中修改的是a的副本x
	fmt.Println(a) //[10 20 30]
}
```

## 6. 切片

切片（Slice）是一个拥有相同类型元素的可变长度的序列。它是基于数组类型做的一层封装。它非常灵活，支持自动扩容。切片是一个引用类型，它的内部结构包含`地址`、`长度`和`容量`。切片一般用于快速地操作一块数据集合。

### 6.1 切片的定义

```go
func main() {
	// 声明切片类型
	var a []string              //声明一个字符串切片
	var b = []int{}             //声明一个整型切片并初始化
	var c = []bool{false, true} //声明一个布尔切片并初始化
	var d = []bool{false, true} //声明一个布尔切片并初始化
	fmt.Println(a)              //[]
	fmt.Println(b)              //[]
	fmt.Println(c)              //[false true]
	fmt.Println(a == nil)       //true
	fmt.Println(b == nil)       //false
	fmt.Println(c == nil)       //false
	// fmt.Println(c == d)   //切片是引用类型，不支持直接比较，只能和nil比较
}
```

切片拥有自己的长度和容量，我们可以通过使用内置的`len()`函数求长度，使用内置的`cap()`函数求切片的容量。

切片的底层就是一个数组，所以我们可以基于数组通过切片表达式得到切片。 切片表达式中的`low`和`high`表示一个索引范围（左包含，右不包含），也就是下面代码中从数组a中选出`1<=索引值<4`的元素组成切片s，得到的切片`长度=high-low`，容量等于得到的切片的底层数组的容量，对切片再执行切片表达式时（切片再切片），`high`的上限边界是切片的容量`cap(a)`，而不是长度。

```go
func main() {
	a := [5]int{1, 2, 3, 4, 5}
	s := a[1:3]  // s := a[low:high]
	fmt.Printf("s:%v len(s):%v cap(s):%v", s, len(s), cap(s))
    // s:[2 3] len(s):2 cap(s):4
}
```

### 6.2 make构造切片

如果需要动态的创建一个切片，我们就需要使用内置的`make()`函数，格式如下：

```go
make([]T, size, cap)  // 元素类型 数量 容量

func main() {
	a := make([]int, 2, 10)
	fmt.Println(a)      //[0 0]
	fmt.Println(len(a)) //2
	fmt.Println(cap(a)) //10
}
```

### 6.3 切片的本质

切片的本质就是对底层数组的封装，它包含了三个信息：底层数组的指针、切片的长度（len）和切片的容量（cap）。举个例子，现在有一个数组`a := [8]int{0, 1, 2, 3, 4, 5, 6, 7}`，切片`s1 := a[:5]`，相应示意图如下。

![Image.tiff](/img/slice_01.png)

切片`s2 := a[3:6]`，相应示意图如下：

![Image.tiff](/img/slice_02.png)

### 6.4 切片拷贝复制

下面的代码中演示了拷贝前后两个变量共享底层数组，对一个切片的修改会影响另一个切片的内容，这点需要特别注意。当需要修改元素时，又不想修改原切片本身，可以使用copy函数复制一个新的切片进行操作。

```go
func main() {
	s1 := make([]int, 3) //[0 0 0]
	s2 := s1             //将s1直接赋值给s2，s1和s2共用一个底层数组
	s2[0] = 10
	fmt.Println(s1) //[10 0 0]
	fmt.Println(s2) //[10 0 0]
}
```

```go
// copy()复制切片
a := []int{1, 2, 3, 4, 5}
c := make([]int, 5, 5)
copy(c, a)     //使用copy()函数将切片a中的元素复制到切片c
```

### 6.5 切片添加

每个切片会指向一个底层数组，这个数组的容量够用就添加新增元素。当底层数组不能容纳新增的元素时，切片就会自动按照一定的策略进行“扩容”，此时该切片指向的底层数组就会更换。“扩容”操作往往发生在`append()`函数调用时，所以我们通常都需要用原变量接收append函数的返回值。

```go
func main() {
	//append()添加元素和切片扩容
	var numSlice []int
	for i := 0; i < 10; i++ {
		numSlice = append(numSlice, i)
		fmt.Printf("%v  len:%d  cap:%d  ptr:%p
", numSlice, len(numSlice), cap(numSlice), numSlice)
	}
}

// 输出
[0]  len:1  cap:1  ptr:0xc0000a8000
[0 1]  len:2  cap:2  ptr:0xc0000a8040
[0 1 2]  len:3  cap:4  ptr:0xc0000b2020
[0 1 2 3]  len:4  cap:4  ptr:0xc0000b2020
[0 1 2 3 4]  len:5  cap:8  ptr:0xc0000b6000
[0 1 2 3 4 5]  len:6  cap:8  ptr:0xc0000b6000
[0 1 2 3 4 5 6]  len:7  cap:8  ptr:0xc0000b6000
[0 1 2 3 4 5 6 7]  len:8  cap:8  ptr:0xc0000b6000
[0 1 2 3 4 5 6 7 8]  len:9  cap:16  ptr:0xc0000b8000
[0 1 2 3 4 5 6 7 8 9]  len:10  cap:16  ptr:0xc0000b8000
```

```go
// 一次添加多个元素
var citySlice []string
// 追加一个元素
citySlice = append(citySlice, "北京")
// 追加多个元素
citySlice = append(citySlice, "上海", "广州", "深圳")
// 追加切片
a := []string{"成都", "重庆"}
citySlice = append(citySlice, a...)
fmt.Println(citySlice) //[北京 上海 广州 深圳 成都 重庆]
```

### 6.6 切片扩容策略

可以通过查看`$GOROOT/src/runtime/slice.go`源码，其中扩容相关代码如下：

```go
newcap := old.cap
doublecap := newcap + newcap
if cap > doublecap {
	newcap = cap
} else {
	if old.len < 1024 {
		newcap = doublecap
	} else {
		// Check 0 < newcap to detect overflow
		// and prevent an infinite loop.
		for 0 < newcap && newcap < cap {
			newcap += newcap / 4
		}
		// Set newcap to the requested cap when
		// the newcap calculation overflowed.
		if newcap <= 0 {
			newcap = cap
		}
	}
}
```

从上面的代码可以看出以下内容：

1. 首先判断，如果新申请容量（cap）大于2倍的旧容量（old.cap），最终容量（newcap）就是新申请的容量（cap）。
2. 否则判断，如果旧切片的长度小于1024，则最终容量(newcap)就是旧容量(old.cap)的两倍，即（newcap=doublecap），
3. 否则判断，如果旧切片长度大于等于1024，则最终容量（newcap）从旧容量（old.cap）开始循环增加原来的1/4，即（newcap=old.cap,for {newcap += newcap/4}）直到最终容量（newcap）大于等于新申请的容量(cap)，即（newcap >= cap）。
4. 如果最终容量（cap）计算值溢出，则最终容量（cap）就是新申请容量（cap）。

需要注意的是，切片扩容还会根据切片中元素的类型不同而做不同的处理，比如`int`和`string`类型的处理方式就不一样。

### 6.7 切片元素删除

Go语言中并没有删除切片元素的专用方法，我们可以使用切片本身的特性来删除元素。 代码如下：

```go
// 要从切片a中删除索引为index的元素，操作方法是a = append(a[:index], a[index+1:]...)
func main() {
	// 从切片中删除元素
	a := []int{30, 31, 32, 33, 34, 35, 36, 37}
	// 要删除索引为2的元素
	a = append(a[:2], a[3:]...)
	fmt.Println(a) //[30 31 33 34 35 36 37]
}
```

## 7. map

Go语言中提供的映射关系容器为`map`，其内部使用`散列表（hash）`实现。map是一种无序的基于`key-value`的数据结构，Go语言中的map是引用类型，必须初始化才能使用。

```bash
// 定义语法
map[keyType]valueType

// 初始化
```

map类型的变量默认初始值为nil，需要使用make()函数来分配内存。

### 7.1 基本使用

```go
// 先定义在
func main() {
	scoreMap := make(map[string]int, 8)
	scoreMap["张三"] = 90
	scoreMap["小明"] = 100
	fmt.Println(scoreMap)
	fmt.Println(scoreMap["小明"])
	fmt.Printf("type of a:%T\n", scoreMap)
}
```

```go
// 定义时同时
func main() {
	userInfo := map[string]string{
		"username": "沙河小王子",
		"password": "123456",
	}
	fmt.Println(userInfo) //
}
```

### 7.2 判断某个键是否存在

```go
// 判断某个map中的键是否存在
value, ok := map[key]

func main() {
	scoreMap := make(map[string]int)
	scoreMap["张三"] = 90
	scoreMap["小明"] = 100
	// 如果key存在ok为true,v为对应的值；不存在ok为false,v为值类型的零值
	v, ok := scoreMap["张三"]
	if ok {
		fmt.Println(v)
	} else {
		fmt.Println("查无此人")
	}
}
```

### 7.3 map的遍历

```go
// 遍历key和va
func main() {
	scoreMap := make(map[string]int)
	scoreMap["张三"] = 90
	scoreMap["小明"] = 100
	scoreMap["娜扎"] = 60
	for k, v := range scoreMap {
		fmt.Println(k, v)
	}
}
```

```go
// 只遍历valu
func main() {
	scoreMap := make(map[string]int)
	scoreMap["张三"] = 90
	scoreMap["小明"] = 100
	scoreMap["娜扎"] = 60
	for k := range scoreMap {
		fmt.Println(k)
	}
}
```

遍历map时的元素顺序与添加键值对的顺序无关。

### 7.4 map键值删除

```go
// 通过delete函数进行删除
func main(){
	scoreMap := make(map[string]int)
	scoreMap["张三"] = 90
	scoreMap["小明"] = 100
	scoreMap["娜扎"] = 60
	delete(scoreMap, "小明").   // 将小明:100从map中删除   
	for k,v := range scoreMap{
		fmt.Println(k, v)
	}
}
```

### 7.5 元素为map类型的切片

```go
func main() {
	var mapSlice = make([]map[string]string, 3)
	for index, value := range mapSlice {
		fmt.Printf("index:%d value:%v
", index, value)
	}
	fmt.Println("after init")
	// 对切片中的map元素进行初始化
	mapSlice[0] = make(map[string]string, 10)
	mapSlice[0]["name"] = "小王子"
	mapSlice[0]["password"] = "123456"
	mapSlice[0]["address"] = "沙河"
	for index, value := range mapSlice {
		fmt.Printf("index:%d value:%v
", index, value)
	}
}
```

### 7.6 值为切片类型的map

```go
func main() {
	var sliceMap = make(map[string][]string, 3)
	fmt.Println(sliceMap)
	fmt.Println("after init")
	key := "中国"
	value, ok := sliceMap[key]
	if !ok {
		value = make([]string, 0, 2)
	}
	value = append(value, "北京", "上海")
	sliceMap[key] = value
	fmt.Println(sliceMap)
}
```

## 8. 指针

任何程序数据载入内存后，在内存都有他们的地址，这就是指针。而为了保存一个数据在内存中的地址，我们就需要指针变量。比如，“永远不要高估自己”这句话是我的座右铭，我想把它写入程序中，程序一启动这句话是要加载到内存（假设内存地址0x123456），我在程序中把这段话赋值给变量`A`，把内存地址赋值给变量`B`。这时候变量`B`就是一个指针变量。通过变量`A`和变量`B`都能找到我的座右铭。

Go语言中的指针不能进行偏移和运算，因此Go语言中的指针操作非常简单，我们只需要记住两个符号：`&`（取地址）和`*`（根据地址取值）。

### 8.1 指针地址

每个变量在运行时都拥有一个地址，这个地址代表变量在内存中的位置。Go语言中使用`&`字符放在变量前面对变量进行“取地址”操作。

```bash
ptr := &v    // v的类型为T 
// v:代表被取地址的变量，类型为T
// ptr:用于接收地址的变量，ptr的类型就为*T，称做T的指针类型。*代表指针。
```

### 8.2 指针取值

在对普通变量使用&操作符取地址后会获得这个变量的指针，然后可以对指针使用*操作，也就是指针取值，代码如下。

```go
func main() {
	//指针取值
	a := 10
	b := &a // 取变量a的地址，将指针保存到b中
	fmt.Printf("type of b:%T", b)
	c := *b // 指针取值（根据指针去内存取值）
	fmt.Printf("type of c:%T", c)
	fmt.Printf("value of c:%v", c)
}

/*
type of b:*int
type of c:int
value of c:10
*/
```

取地址操作符`&`和取值操作符`*`是一对互补操作符，`&`取出地址，`*`根据地址取出地址指向的值。

变量、指针地址、指针变量、取地址、取值的相互关系和特性如下：

- 对变量进行取地址（&）操作，可以获得这个变量的指针变量。
- 指针变量的值是指针地址。
- 对指针变量进行取值（*）操作，可以获得指针变量指向的原变量的值。

### 8.3 new

new是一个内置的函数，它的函数签名如下:

```go
func new(Type) *Type
// Type表示类型，new函数只接受一个参数，这个参数是一个类型
// *Type表示类型指针，new函数返回一个指向该类型内存地址的指针。
```

使用new函数得到的是一个类型的指针，并且该指针对应的值为该类型的零值。举个例子:

```go
func main() {
	a := new(int)
	b := new(bool)
	fmt.Printf("%T\n", a) // *int
	fmt.Printf("%T\n", b) // *bool
	fmt.Println(*a)       // 0
	fmt.Println(*b)       // false
}
```

如下示例代码中`var a *int`只是声明了一个指针变量a但是没有初始化，指针作为引用类型需要初始化后才会拥有内存空间，才可以给它赋值。应该按照如下方式使用内置的new函数对a进行初始化之后就可以正常对其赋值了：

```go
func main() {
	var a *int
	a = new(int)
	*a = 10
	fmt.Println(*a)
}
```

### 8.4 make

make也是用于内存分配的，区别于new，它只用于slice、map以及channel的内存创建，而且它返回的类型就是这三个类型本身，而不是他们的指针类型，因为这三种类型就是引用类型，所以就没有必要返回他们的指针了。make函数的函数签名如下：

```go
func make(t Type, size ...IntegerType) Type
```

make函数是无可替代的，我们在使用slice、map以及channel的时候，都需要使用make进行初始化，然后才可以对它们进行操作。

如下的示例中`var b map[string]int`只是声明变量b是一个map类型的变量，需要像下面的示例代码一样使用make函数进行初始化操作之后，才能对其进行键值对赋值：

```go
func main() {
	var b map[string]int
	b = make(map[string]int, 10)
	b["沙河娜扎"] = 100
	fmt.Println(b)
}
```

### 8.5 new与make的区别

1. 二者都是用来做内存分配的。
2. make只用于slice、map以及channel的初始化，返回的还是这三个引用类型本身；
3. 而new用于类型的内存分配，并且内存对应的值为类型零值，返回的是指向类型的指针。

### 8.6 引用类型
1. slice、map、channel是go语言里面的三种引用类型，都可以通过make函数来初始化申请内存分配
2. 因为他们都包含一个指向底层数据结构的指针，所以称之为引用类型。
3. 引用类型未初始化时都是nil，可以对他执行len函数，返回0值
