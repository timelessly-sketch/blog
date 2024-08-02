---
title: 常用包与工程化
date: 2023-03-12 16:07:04
tags: golang
banner_img: /img/index.png
index_img: /img/golang/golang05_index.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 一. 基础技能
---
## 1. 包管理

在1.17后，go get 只负责下载第三方依赖包，并且添加到go.mod里面，由go install负责安装二进制文件。

## 2. init函数

在main函数执行之前会先执行init函数，在引入其他包时，相应包里面的init函数也会在main函数之前被调用。

如果只想执行包里面的init函数，可以通过在引用目录前加一个_ 来实现。

## 3. 数学函数

```bash
math.Ceil(1.1)	//向上取整，2
math.Floor(1.9)	//向下取整，1。 math.Floor(-1.9)=-2
math.Trunc(1.9)	//取整数部分，1
math.Modf(2.5)	//返回整数部分和小数部分，2  0.5
math.Abs(-2.6)	//绝对值，2.6
math.Max(4, 8)	//取二者的较大者，8
math.Min(4, 8)	//取二者的较小者，4
math.Mod(6.5, 3.5)	//x-Trunc(x/y)*y结果的正负号和x相同，3
math.Sqrt(9)		//开平方，3
math.Cbrt(9)		//开三次方，2.08008
```

```bash
//随机数
rand.Seed(1)                //如果对两次运行没有一致性要求，可以不设seed
fmt.Println(rand.Int())     //随机生成一个整数
fmt.Println(rand.Float32()) //随机生成一个浮点数
fmt.Println(rand.Intn(100)) //100以内的随机整数，[0,100)
fmt.Println(rand.Perm(100)) //把[0,100)上的整数随机打乱
arr := []int{1, 2, 3, 4, 5, 6, 7, 8, 9}
rand.Shuffle(len(arr), func(i, j int) { //随机打乱一个给定的slice
    arr[i], arr[j] = arr[j], arr[i]
})
fmt.Println(arr)
```

## 4. 时间函数

```bash
// 解析与格式化
TIME_FMT := "2006-01-02 15:04:05"
now := time.Now()
ts := now.Format(TIME_FMT) // 2023-03-12 16:00:53
```

## 5. I/O操作

### 5.1 创建文件和目录

```bash
os.Create(name string)//创建文件
os.Mkdir(name string, perm fs.FileMode)//创建目录
os.MkdirAll(path string, perm fs.FileMode)//增强版Mkdir，沿途的目录不存在时会一并创建
os.Rename(oldpath string, newpath string)//给文件或目录重命名，还可以实现move的功能
os.Remove(name string)//删除文件或目录，目录不为空时才能删除成功
os.RemoveAll(path string)//增强版Remove，所有子目录会递归删除
```

## 6. 编码

json是go标准库里自带的序列化工具，使用了反射，效率比较低。

sonic是字节跳动开源的json序列化工具包，号称性能强过easyjson、jsoniter，使用起来非常方便。

```bash
import "github.com/bytedance/sonic"

// Marshal
output, err := sonic.Marshal(&data) 
// Unmarshal
err := sonic.Unmarshal(input, &data)
```