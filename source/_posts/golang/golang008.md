---
title: 语言的反射
date: 2023-03-12 15:26:51
tags: golang
banner_img: /img/index.png
index_img: /img/golang/golang07_index.png
show_category: true # 表示强制开启
categories:
  - Go系列
  - 一. 基础技能
---

## 1. 反射的介绍

反射是指在程序运行期间对程序本身进行访问和修改的能力。程序在编译时，变量被转换为内存地址，变量名不会被编译器写入到可执行部分。在运行程序时，程序无法获取自身的信息。

支持反射的语言可以在程序编译期间将变量的反射信息，如字段名称、类型信息、结构体信息等整合到可执行文件中，并给程序提供接口访问反射信息，这样就可以在程序运行期间获取类型的反射信息，并且有能力修改它们。

反射是一个强大并富有表现力的工具，能让我们写出更灵活的代码。但是反射不应该被滥用，原因有以下三个。

1. 基于反射的代码是极其脆弱的，反射中的类型错误会在真正运行的时候才会引发panic，那很可能是在代码写完的很长时间之后。
2. 大量使用反射的代码通常难以理解。
3. 反射的性能低下，基于反射实现的代码通常比正常代码运行速度慢一到两个数量级。

> 内存对齐：当不满8字节时已满8填充，但是如果两个变量当好合计8字节时，不会开辟新的内存空间。

## 2. TypeOf

在Go语言中，使用`reflect.TypeOf()`函数可以获得任意值的类型对象（reflect.Type），程序通过类型对象可以访问任意值的类型信息。在反射中关于类型还划分为两种：`类型（Type）`和`种类（Kind）`。因为在Go语言中我们可以使用type关键字构造很多自定义类型，而`种类（Kind）`就是指底层的类型，但在反射中，当需要区分指针、结构体等大品种的类型时，就会用到`种类（Kind）`

### 2.1 通过TypeOf()得到Type类型

```go
typeI := reflect.TypeOf(1)
typeS := reflect.TypeOf("hello")
fmt.Println(typeI)               //int
fmt.Println(typeS)               //string

typeUser := reflect.TypeOf(&common.User{})
fmt.Println(typeUser)                     //*common.User
fmt.Println(typeUser.Kind())                 //ptr
fmt.Println(typeUser.Elem().Kind())    //struct
```

### 2.2 指针Type转为非指针Type

```bash
typeUser := reflect.TypeOf(&common.User{})
typeUser2 := reflect.TypeOf(common.User{})
assert.IsEqual(typeUser.Elem(), typeUser2)
```

### 2.3 获取struct成员变量的信息

```bash
typeUser := reflect.TypeOf(common.User{}) //需要用struct的Type，不能用指针的Type
fieldNum := typeUser.NumField()           //成员变量的个数
for i := 0; i < fieldNum; i++ {
	field := typeUser.Field(i)
	fmt.Printf("%d %s offset %d anonymous %t type %s exported %t json tag %s\n", i,
		field.Name,            //变量名称
		field.Offset,          //相对于结构体首地址的内存偏移量，string类型会占据16个字节
		field.Anonymous,       //是否为匿名成员
		field.Type,            //数据类型，reflect.Type类型
		field.IsExported(),    //包外是否可见（即是否以大写字母开头）
		field.Tag.Get("json")) //获取成员变量后面``里面定义的tag
}
fmt.Println()

//可以通过FieldByName获取Field
if nameField, ok := typeUser.FieldByName("Name"); ok {
	fmt.Printf("Name is exported %t\n", nameField.IsExported())
}
//也可以根据FieldByIndex获取Field
thirdField := typeUser.FieldByIndex([]int{2}) //参数是个slice，因为有struct嵌套的情况
fmt.Printf("third field name %s\n", thirdField.Name)
```

### 2.4 获取struct成员方法的信息

```bash
typeUser := reflect.TypeOf(common.User{})
methodNum := typeUser.NumMethod() //成员方法的个数。接收者为指针的方法【不】包含在内
for i := 0; i < methodNum; i++ {
	method := typeUser.Method(i)
	fmt.Printf("method name:%s ,type:%s, exported:%t\n", method.Name, method.Type, method.IsExported())
}
fmt.Println()

typeUser2 := reflect.TypeOf(&common.User{})
methodNum = typeUser2.NumMethod() //成员方法的个数。接收者为指针或值的方法【都】包含在内，也就是说值实现的方法指针也实现了（反之不成立）
for i := 0; i < methodNum; i++ {
	method := typeUser2.Method(i)
	fmt.Printf("method name:%s ,type:%s, exported:%t\n", method.Name, method.Type, method.IsExported())
}
```

### 2.5 获取函数的信息

```bash
func Add(a, b int) int {
	return a + b
}

typeFunc := reflect.TypeOf(Add) //获取函数类型
fmt.Printf("is function type %t\n", typeFunc.Kind() == reflect.Func)
argInNum := typeFunc.NumIn()   //输入参数的个数
argOutNum := typeFunc.NumOut() //输出参数的个数
for i := 0; i < argInNum; i++ {
	argTyp := typeFunc.In(i)
	fmt.Printf("第%d个输入参数的类型%s\n", i, argTyp)
}
for i := 0; i < argOutNum; i++ {
	argTyp := typeFunc.Out(i)
	fmt.Printf("第%d个输出参数的类型%s\n", i, argTyp)
}
```

### 2.6 判断类型是否实现了某接口

```bash
//通过reflect.TypeOf((*<interface>)(nil)).Elem()获得接口类型。因为People是个接口不能创建实例，所以把nil强制转为*common.People类型
typeOfPeople := reflect.TypeOf((*common.People)(nil)).Elem()
fmt.Printf("typeOfPeople kind is interface %t\n", typeOfPeople.Kind() == reflect.Interface)
t1 := reflect.TypeOf(common.User{})
t2 := reflect.TypeOf(&common.User{})
//如果值类型实现了接口，则指针类型也实现了接口；反之不成立
fmt.Printf("t1 implements People interface %t\n", t1.Implements(typeOfPeople))
```

## 3. ValueOf

`reflect.ValueOf()`返回的是`reflect.Value`类型，其中包含了原始值的值信息。`reflect.Value`与原始值之间可以互相转换。

### 3.1 如果获得Value

```bash
iValue := reflect.ValueOf(1)
sValue := reflect.ValueOf("hello")
userPtrValue := reflect.ValueOf(&common.User{
	Id:     7,
	Name:   "杰克逊",
	Weight: 65,
	Height: 1.68,
})
fmt.Println(iValue)       //1
fmt.Println(sValue)       //hello
fmt.Println(userPtrValue) //&{7 杰克逊  65 1.68}
```

### 3.2 Value转为Type

```bash
iType := iValue.Type()
sType := sValue.Type()
userType := userPtrValue.Type()
//在Type和相应Value上调用Kind()结果一样的
fmt.Println(iType.Kind() == reflect.Int, iValue.Kind() == reflect.Int, iType.Kind() == iValue.Kind())  
fmt.Println(sType.Kind() == reflect.String, sValue.Kind() == reflect.String, sType.Kind() == sValue.Kind()) 
fmt.Println(userType.Kind() == reflect.Ptr, userPtrValue.Kind() == reflect.Ptr, userType.Kind() == userPtrValue.Kind())
```

### 3.3 指针Value和非指针Value互相转换

```bash
userValue := userPtrValue.Elem()                    //Elem() 指针Value转为非指针Value
fmt.Println(userValue.Kind(), userPtrValue.Kind())  //struct ptr
userPtrValue3 := userValue.Addr()                   //Addr() 非指针Value转为指针Value
fmt.Println(userValue.Kind(), userPtrValue3.Kind()) //struct ptr
```

### 3.4 得到Value对应的原始数据

通过Interface()函数把Value转为interface{}，再从interface{}强制类型转换，转为原始数据类型。或者在Value上直接调用Int()、String()等一步到位。

```bash
fmt.Printf("origin value iValue is %d %d\n", iValue.Interface().(int), iValue.Int())
fmt.Printf("origin value sValue is %s %s\n", sValue.Interface().(string), sValue.String())
user := userValue.Interface().(common.User)
fmt.Printf("id=%d name=%s weight=%.2f height=%.2f\n", user.Id, user.Name, user.Weight, user.Height)
user2 := userPtrValue.Interface().(*common.User)
fmt.Printf("id=%d name=%s weight=%.2f height=%.2f\n", user2.Id, user2.Name, user2.Weight, user2.Height)
```

### 3.5 空Value的判断

```bash
var i interface{} //接口没有指向具体的值
v := reflect.ValueOf(i)
fmt.Printf("v持有值 %t, type of v is Invalid %t\n", v.IsValid(), v.Kind() == reflect.Invalid)

var user *common.User = nil
v = reflect.ValueOf(user) //Value指向一个nil
if v.IsValid() {
	fmt.Printf("v持有的值是nil %t\n", v.IsNil()) //调用IsNil()前先确保IsValid()，否则会panic
}

var u common.User //只声明，里面的值都是0值
v = reflect.ValueOf(u)
if v.IsValid() {
	fmt.Printf("v持有的值是对应类型的0值 %t\n", v.IsZero()) //调用IsZero()前先确保IsValid()，否则会panic
}
```

### 3.6 通过Value修改原始数据的值

```bash
var i int = 10
var s string = "hello"
user := common.User{
	Id:     7,
	Name:   "杰克逊",
	Weight: 65.5,
	Height: 1.68,
}

valueI := reflect.ValueOf(&i) //由于go语言所有函数传的都是值，所以要想修改原来的值就需要传指针
valueS := reflect.ValueOf(&s)
valueUser := reflect.ValueOf(&user)
valueI.Elem().SetInt(8) //由于valueI对应的原始对象是指针，通过Elem()返回指针指向的对象
valueS.Elem().SetString("golang")
valueUser.Elem().FieldByName("Weight").SetFloat(68.0) //FieldByName()通过Name返回类的成员变量
```

强调一下，要想修改原始数据的值，给ValueOf传的必须是指针，而指针Value不能调用Set和FieldByName方法，所以得先通过Elem()转为非指针Value。未导出成员的值不能通过反射进行修改。

```bash
addrValue := valueUser.Elem().FieldByName("addr")
if addrValue.CanSet() {
	addrValue.SetString("北京")
} else {
	fmt.Println("addr是未导出成员，不可Set") //以小写字母开头的成员相当于是私有成员
}
```

### 3.7 通过Value修改Slice

```bash
users := make([]*common.User, 1, 5) //len=1，cap=5
users[0] = &common.User{
	Id:     7,
	Name:   "杰克逊",
	Weight: 65.5,
	Height: 1.68,
}

sliceValue := reflect.ValueOf(&users) //准备通过Value修改users，所以传users的地址
if sliceValue.Elem().Len() > 0 {      //取得slice的长度
	sliceValue.Elem().Index(0).Elem().FieldByName("Name").SetString("令狐一刀")
	fmt.Printf("1st user name change to %s\n", users[0].Name)
}
```

甚至可以修改slice的cap，新的cap必须位于原始的len到cap之间，即只能把cap改小。

`sliceValue.Elem().SetCap(3)`

通过把len改大，可以实现向slice中追加元素的功能。

```bash
sliceValue.Elem().SetLen(2)
//调用reflect.Value的Set()函数修改其底层指向的原始数据
sliceValue.Elem().Index(1).Set(reflect.ValueOf(&common.User{
	Id:     8,
	Name:   "李达",
	Weight: 80,
	Height: 180,
}))
fmt.Printf("2nd user name %s\n", users[1].Name)
```

### 3.8 修改map

Value.SetMapIndex()函数：往map里添加一个key-value对。Value.MapIndex()函数： 根据Key取出对应的map。

```bash
u1 := &common.User{
	Id:     7,
	Name:   "杰克逊",
	Weight: 65.5,
	Height: 1.68,
}
u2 := &common.User{
	Id:     8,
	Name:   "杰克逊",
	Weight: 65.5,
	Height: 1.68,
}
userMap := make(map[int]*common.User, 5)
userMap[u1.Id] = u1

mapValue := reflect.ValueOf(&userMap)                                                         //准备通过Value修改userMap，所以传userMap的地址
mapValue.Elem().SetMapIndex(reflect.ValueOf(u2.Id), reflect.ValueOf(u2))                      //SetMapIndex 往map里添加一个key-value对
mapValue.Elem().MapIndex(reflect.ValueOf(u1.Id)).Elem().FieldByName("Name").SetString("令狐一刀") //MapIndex 根据Key取出对应的map
for k, user := range userMap {
	fmt.Printf("key %d name %s\n", k, user.Name)
}
```

### 3.9 调用函数

```bash
valueFunc := reflect.ValueOf(Add) //函数也是一种数据类型
typeFunc := reflect.TypeOf(Add)
argNum := typeFunc.NumIn()            //函数输入参数的个数
args := make([]reflect.Value, argNum) //准备函数的输入参数
for i := 0; i < argNum; i++ {
	if typeFunc.In(i).Kind() == reflect.Int {
		args[i] = reflect.ValueOf(3) //给每一个参数都赋3
	}
}
sumValue := valueFunc.Call(args) //返回[]reflect.Value，因为go语言的函数返回可能是一个列表
if typeFunc.Out(0).Kind() == reflect.Int {
	sum := sumValue[0].Interface().(int) //从Value转为原始数据类型
	fmt.Printf("sum=%d\n", sum)
}
```

### 3.10 调用成员方法

```bash
common.User{
	Id:     7,
	Name:   "杰克逊",
	Weight: 65.5,
	Height: 1.68,
}
valueUser := reflect.ValueOf(&user)              //必须传指针，因为BMI()在定义的时候它是指针的方法
bmiMethod := valueUser.MethodByName("BMI")       //MethodByName()通过Name返回类的成员变量
resultValue := bmiMethod.Call([]reflect.Value{}) //无参数时传一个空的切片
result := resultValue[0].Interface().(float32)
fmt.Printf("bmi=%.2f\n", result)

//Think()在定义的时候用的不是指针，valueUser可以用指针也可以不用指针
thinkMethod := valueUser.MethodByName("Think")
thinkMethod.Call([]reflect.Value{})

valueUser2 := reflect.ValueOf(user)
thinkMethod = valueUser2.MethodByName("Think")
thinkMethod.Call([]reflect.Value{})
```

## 4. 创建对象

### 4.1 创建struct

```bash
user :=t := reflect.TypeOf(common.User{})
value := reflect.New(t) //根据reflect.Type创建一个对象，得到该对象的指针，再根据指针提到reflect.Value
value.Elem().FieldByName("Id").SetInt(10)
user := value.Interface().(*common.User) //把反射类型转成go原始数据类型Call([]reflect.Value{})
```

### 4.2 创建slice

```bash
var slice []common.User
sliceType := reflect.TypeOf(slice)
sliceValue := reflect.MakeSlice(sliceType, 1, 3)
sliceValue.Index(0).Set(reflect.ValueOf(common.User{
	Id:     8,
	Name:   "李达",
	Weight: 80,
	Height: 180,
}))
users := sliceValue.Interface().([]common.User)
fmt.Printf("1st user name %s\n", users[0].Name)
```

### 4.3 创建map

```bash
var userMap map[int]*common.User
mapType := reflect.TypeOf(userMap)
// mapValue:=reflect.MakeMap(mapType)
mapValue := reflect.MakeMapWithSize(mapType, 10)

user := &common.User{
	Id:     7,
	Name:   "杰克逊",
	Weight: 65.5,
	Height: 1.68,
}
key := reflect.ValueOf(user.Id)
mapValue.SetMapIndex(key, reflect.ValueOf(user))                    //SetMapIndex 往map里添加一个key-value对
mapValue.MapIndex(key).Elem().FieldByName("Name").SetString("令狐一刀") //MapIndex 根据Key取出对应的map
userMap = mapValue.Interface().(map[int]*common.User)
fmt.Printf("user name %s %s\n", userMap[7].Name, user.Name)
```

## 5. 反射与结构体

通过反射去获取结构体里面的相关信息，如下：

```go
type u struct {
	name string `json:"name"`
	age  int    `json:"age"`
}

func (s u) Study() string {
	msg := "好好学习，天天向上。"
	fmt.Println(msg)
	return msg
}

func (s u) Sleep() string {
	msg := "好好睡觉，快快长大。"
	fmt.Println(msg)
	return msg
}
func printMethod(x interface{}) {
	t := reflect.TypeOf(x)
	v := reflect.ValueOf(x)

	fmt.Println(t.NumMethod())
	for i := 0; i < v.NumMethod(); i++ {
		methodType := v.Method(i).Type()
		fmt.Printf("method name:%s\n", t.Method(i).Name)
		fmt.Printf("method:%s\n", methodType)
		// 通过反射调用方法传递的参数必须是 []reflect.Value 类型
		var args = []reflect.Value{}
		v.Method(i).Call(args)
	}
}

func TestGetField(t *testing.T) {
	typeOf := reflect.TypeOf(u{})
	// 遍历机结构体所有字段
	for i := 0; i < typeOf.NumField(); i++ {
		field := typeOf.Field(i)
		fmt.Printf("name:%s index:%d type:%v json tag:%v\n", field.Name, field.Index, field.Type, field.Tag.Get("json"))
		// name:name index:[0] type:string json tag:name
		// name:age  index:[1]  type:int    json tag:age
	}
	// 指定字段
	if fieldByName, ok := typeOf.FieldByName("age"); ok {
		fmt.Printf("name:%s index:%d type:%v json tag:%v\n", fieldByName.Name, fieldByName.Index, fieldByName.Type, fieldByName.Tag.Get("json"))
		// name:age index:[1] type:int json tag:age
	}
	// 获取结构体的方法
	printMethod(u{})
	/*
	  method name:Sleep
	  method:func() string
	  好好睡觉，快快长大。
	  method name:Study
	  method:func() string
	  好好学习，天天向上。
	*/
}
```