---
title: 并发编程
date: 2023-03-12 22:32:15
tags: golang
banner_img: /img/index.png
index_img: /img/golang/golang010_index.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 一. 基础技能
---

## 1. 基本概念

进程（process）：程序在操作系统中的一次执行过程，系统进行资源分配和调度的一个独立单位。

线程（thread）：操作系统基于进程开启的轻量级进程，是操作系统调度执行的最小单位。

协程（coroutine）：非操作系统提供而是由用户自行创建和控制的用户态‘线程’，比线程更轻量级。

## 2. goroutine

### 2.1 启动单个goroutine

启动 goroutine 的方式非常简单，只需要在调用函数（普通函数和匿名函数）前加上一个`go`关键字。我们先来看一个在 main 函数中执行普通函数调用的示例。

```go
func hello() {
	fmt.Println("hello")
}

func main() {
	go hello() // 启动另外一个goroutine去执行hello函数
	fmt.Println("你好") // 但在实际执行时，只打印你好
}
```

其实在 Go 程序启动时，Go 程序就会为 main 函数创建一个默认的 goroutine 。在上面的代码中我们在 main 函数中使用 go 关键字创建了另外一个 goroutine 去执行 hello 函数，而此时 main goroutine 还在继续往下执行，我们的程序中此时存在两个并发执行的 goroutine。当 main 函数结束时整个程序也就结束了，同时 main goroutine 也结束了，所有由 main goroutine 创建的 goroutine 也会一同退出。也就是说我们的 main 函数退出太快，另外一个 goroutine 中的函数还未执行完程序就退出了，导致未打印出“hello”。

```bash
go hello()
	fmt.Println("你好")
	time.Sleep(time.Second). // 添加一点时间，等待hello这个goroutine执行结束，这种其实是不优雅的
```

```go
// 使用waitgro
// 声明全局等待组变量
var wg sync.WaitGroup

func hello() {
	fmt.Println("hello")
	wg.Done() // 告知当前goroutine完成
}

func main() {
	wg.Add(1) // 登记1个goroutine
	go hello()
	fmt.Println("你好")
	wg.Wait() // 阻塞等待登记的goroutine完成
}
```

### 2.2 启动多个goroutine

这里同样使用了`sync.WaitGroup`来实现 goroutine 的同步。

```go
var wg sync.WaitGroup

func hello(i int) {
	defer wg.Done() // goroutine结束就登记-1
	fmt.Println("hello", i)
}
func main() {
	for i := 0; i < 10; i++ {
		wg.Add(1) // 启动一个goroutine就登记+1
		go hello(i)
	}
	wg.Wait() // 等待所有登记的goroutine都结束
}
```

多次执行上面的代码会发现每次终端上打印数字的顺序都不一致。这是因为10个 goroutine 是并发执行的，而 goroutine 的调度是随机的。

### 2.3 动态栈

操作系统的线程一般都有固定的栈内存（通常为2MB）,而 Go 语言中的 goroutine 非常轻量级，一个 goroutine 的初始栈空间很小（一般为2KB），所以在 Go 语言中一次创建数万个 goroutine 也是可能的。并且 goroutine 的栈不是固定的，可以根据需要动态地增大或缩小， Go 的 runtime 会自动为 goroutine 分配合适的栈空间。

### 2.4 goroutine调度

GPM模型

## 3. channel类型

`Channel`是用来连接并发的`goroutine`的。一个`goroutine`通过`channel`向另一个goroutine发送消息，对应的`goroutine`通过`channel`来接收消息。

```bash
var ch1 chan int   // 声明一个传递整型的通道
var ch2 chan bool  // 声明一个传递布尔型的通道
var ch3 chan []int // 声明一个传递int切片的通道
```

### 3.1 初始化channel

声明的通道类型变量需要使用内置的`make`函数初始化之后才能使用。具体格式如下：

```go
ch4 := make(chan int)   // 无缓冲的channel
ch5 := make(chan bool, 1)  // 声明一个缓冲区大小为1的通道
```

### 3.2 channel操作

通道共有发送（send）、接收(receive）和关闭（close）三种操作。而发送和接收操作都使用`<-`符号。

```go
// 定义channel
strChan := make(chan string, 3)
strChan <- "我们" // 装数据进去
strChan <- "你们"
close(strChan) // 需要关闭channel不然在读取时会panic

out := <-strChan
out = <-strChan
fmt.Println(out) // 你们

out, ok := <-strChan
fmt.Println(out, ok) // ""  false OK是标识符 标识读取的是否是真实数据
```

### 3.3 特征与注意事项

- `channel`本质是一个队列
- 本身是线程安全的
- 是数据类型敏感的
- 没有缓冲区的channel在没有可用的接收者时，程序等待
- channel不能重复关闭
- 关闭后的channel不能在往里面转数据 但是可以取数据，
- 对于已经关闭的channel进行取数据，当所有数据都结束后，依旧会取到零值。
- 非多线程程序中 谨慎使用channel
- select在选择channel时 如果多个channel都准备好 他会随机选择一个 而不是从上往下 如果没有 case 可运行，它将阻塞，直到有 case 可运行

### 3.4 无缓冲的channel通道

无缓冲的通道又称为阻塞的通道。我们来看一下如下代码片段。

```go
func main() {
	ch := make(chan int)
	ch <- 10
	fmt.Println("发送成功")
}
```

上面这段代码能够通过编译，但是执行的时候会出现以下错误：

```other
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan send]:
main.main()
        .../main.go:8 +0x54
```

因为我们使用`ch := make(chan int)`创建的是无缓冲的通道，无缓冲的通道只有在有接收方能够接收值的时候才能发送成功，否则会一直处于等待发送的阶段。同理，如果对一个无缓冲通道执行接收操作时，没有任何向通道中发送值的操作那么也会导致接收操作阻塞。

上面的代码会阻塞在`ch <- 10`这一行代码形成死锁，那如何解决这个问题呢？其中一种可行的方法是创建一个 goroutine 去接收值，例如：

```go
func recv(c chan int) {
	ret := <-c
	fmt.Println("接收成功", ret)
}

func main() {
	ch := make(chan int)
	go recv(ch) // 创建一个 goroutine 从通道接收值
	ch <- 10
	fmt.Println("发送成功")
}
```

首先无缓冲通道`ch`上的发送操作会阻塞，直到另一个 goroutine 在该通道上执行接收操作，这时数字10才能发送成功，两个 goroutine 将继续执行。相反，如果接收操作先执行，接收方所在的 goroutine 将阻塞，直到 main goroutine 中向该通道发送数字10。

使用无缓冲通道进行通信将导致发送和接收的 goroutine 同步化。因此，无缓冲通道也被称为`同步通道。`

### 3.5 有缓冲区的通道

还有另外一种解决上面死锁问题的方法，那就是使用有缓冲区的通道。我们可以在使用 make 函数初始化通道时，可以为其指定通道的容量，例如：

```go
func main() {
	ch := make(chan int, 1) // 创建一个容量为1的有缓冲区通道
	ch <- 10
	fmt.Println("发送成功")
}
```

只要通道的容量大于零，那么该通道就属于有缓冲的通道，通道的容量表示通道中最大能存放的元素数量。当通道内已有元素数达到最大容量后，再向通道执行发送操作就会阻塞，除非有从通道执行接收操作。

### 3.6 接收通道值

```bash
func f(ch chan int) {
	for v := range ch {
		fmt.Println(v)
	}
}

func TestC(t *testing.T) {
	ch := make(chan int, 2)
	ch <- 1
	ch <- 2
	close(ch) // 关闭ch 不能放，但能取
	f(ch)
}
```

### 3.7  单向通道

```go
// Producer 返回一个通道
// 并持续将符合条件的数据发送至返回的通道中
// 数据发送完成后会将返回的通道关闭
func Producer() chan int {
	ch := make(chan int, 2)
	// 创建一个新的goroutine执行发送数据的任务
	go func() {
		for i := 0; i < 10; i++ {
			if i%2 == 1 {
				ch <- i
			}
		}
		close(ch) // 任务完成后关闭通道
	}()

	return ch
}

// Consumer 从通道中接收数据进行计算
func Consumer(ch chan int) int {
	sum := 0
	for v := range ch {
		sum += v
	}
	return sum
}

func main() {
	ch := Producer()

	res := Consumer(ch)
	fmt.Println(res) // 25

}
```

从上面的示例代码中可以看出正常情况下`Consumer`函数中只会对通道进行接收操作，但是这不代表不可以在`Consumer`函数中对通道进行发送操作。作为`Producer`函数的提供者，我们在返回通道的时候可能只希望调用方拿到返回的通道后只能对其进行接收操作。但是我们没有办法阻止在`Consumer`函数中对通道进行发送操作。

Go语言中提供了**单向通道**来处理这种需要限制通道只能进行某种操作的情况。

```go
<- chan int // 只接收通道，只能接收不能发送
chan <- int // 只发送通道，只能发送不能接收
```

其中，箭头`<-`和关键字`chan`的相对位置表明了当前通道允许的操作，这种限制将在编译阶段进行检测。另外对一个只接收通道执行close也是不允许的，因为默认通道的关闭操作应该由发送方来完成。

我们使用单向通道将上面的示例代码进行如下改造。

```go
// Producer2 返回一个接收通道
func Producer2() <-chan int {
	ch := make(chan int, 2)
	// 创建一个新的goroutine执行发送数据的任务
	go func() {
		for i := 0; i < 10; i++ {
			if i%2 == 1 {
				ch <- i
			}
		}
		close(ch) // 任务完成后关闭通道
	}()

	return ch
}

// Consumer2 参数为接收通道
func Consumer2(ch <-chan int) int {
	sum := 0
	for v := range ch {
		sum += v
	}
	return sum
}

func main() {
	ch2 := Producer2()
  
	res2 := Consumer2(ch2)
	fmt.Println(res2) // 25
}
```

这一次，`Producer`函数返回的是一个只接收通道，这就从代码层面限制了该函数返回的通道只能进行接收操作，保证了数据安全。

```bash
// 通道
var ch4 = make(chan int, 1)
ch4 <- 10
var ch5 <-chan int // 声明一个只接收通道ch5
ch5 = ch4          // 变量赋值时将ch4转为单向通道
<-ch5
```

### 3.8 多路复用

在某些场景下我们可能需要同时从多个通道接收数据。通道在接收数据时，如果没有数据可以被接收那么当前 goroutine 将会发生阻塞。Select 的使用方式类似于之前学到的 switch 语句，它也有一系列 case 分支和一个默认的分支。每个 case 分支会对应一个通道的通信（接收或发送）过程。select 会一直等待，直到其中的某个 case 的通信操作完成时，就会执行该 case 分支对应的语句。

```go
select {
case <-ch1:
	//...
case data := <-ch2:
	//...
case ch3 <- 10:
	//...
default:
	//默认操作
}
```

Select 语句具有以下特点。

- 可处理一个或多个 channel 的发送/接收操作。
- 如果多个 case 同时满足，select 会**随机**选择一个执行。
- 对于没有 case 的 select 会一直阻塞，可用于阻塞 main 函数，防止退出。

下面的示例代码能够在终端打印出10以内的奇数，我们借助这个代码片段来看一下 select 的具体使用。

```go
package main

import "fmt"

func main() {
	ch := make(chan int, 1)
	for i := 1; i <= 10; i++ {
		select {
		case x := <-ch:
			fmt.Println(x)
		case ch <- i:
		}
	}
}
// 输出： 1 3  5 7 9
```

示例中的代码首先是创建了一个缓冲区大小为1的通道 ch，进入 for 循环后：

- 第一次循环时 i = 1，select 语句中包含两个 case 分支，此时由于通道中没有值可以接收，所以`x := <-ch`这个 case 分支不满足，而`ch <- i`这个分支可以执行，会把1发送到通道中，结束本次 for 循环；
- 第二次 for 循环时，i = 2，由于通道缓冲区已满，所以`ch <- i`这个分支不满足，而`x := <-ch`这个分支可以执行，从通道接收值1并赋值给变量 x ，所以会在终端打印出 1；
- 后续的 for 循环以此类推会依次打印出3、5、7、9。
## 4. Mutex锁

有时候我们的代码中可能会存在多个 goroutine 同时操作一个资源（临界区）的情况，这种情况下就会发生`竞态问题`（数据竞态）。

```bash
// 统计书的字数 当多次执行会发现统计字数不一样的情况，是由于可能存在同时操作某个变量的情况，此时需要通过锁，保证数据安全性
func TestCountNumber(t *testing.T) {
	totalNum := 0
	totalWorkers := 100

	wg := sync.WaitGroup{}
	wg.Add(totalWorkers)
	for i := 0; i < totalWorkers; i++ {
		go func() {
			defer wg.Done()
			totalNum += 100
		}()
	}
	wg.Wait()
	fmt.Println("总字数：", totalNum)
}
```

锁是一种保障被锁内容只有在拿到锁之后才能对内容进行阅读、修改的机制。通常在多线程、多routine的环境中保证操作的正确性、安全性。

### 4.1 锁的种类

- 同步锁
   - 锁只能被一个routine拿到
   - 其他routine必须等待锁释放后才可以去争抢
- 读写锁
   - 写锁只能一个routine拿到、读锁可以同时被多个routine拿到
   - 其他要拿锁的必须等待写锁释放后才可以去争抢
   - 读锁不阻止其他routine去拿锁，读锁在释放前 拿写锁的routine等待，直到所有锁释放后才可以拿到锁

### 4.2 Mutex正常模式与饥饿模式

**正常模式(非公平锁)：**

正常模式下，所有等待锁的 goroutine 按照 FIFO(先进先出)顺序等待。唤醒 的 goroutine 不会直接拥有锁，而是会和新请求 goroutine 竞争锁。新请求的 goroutine 更容易抢占:因为它正在 CPU 上执行，所以刚刚唤醒的 goroutine有很大可能在锁竞争中失败。在这种情况下，这个被唤醒的 goroutine 会加入 到等待队列的前面

**饥饿模式(公平锁)：**          为了解决了等待 goroutine 队列的长尾问题饥饿模式下，直接由 unlock 把锁交给等待队列中排在第一位的 goroutine (队头)，同时，饥饿模式下，新进来的 goroutine 不会参与抢锁也不会进入自旋状态，会直接进入等待队列的尾部。这样很好的解决了老的 goroutine 一直抢不到锁的场景。饥饿模式的触发条件:当一个 goroutine 等待锁时间超过 1 毫秒时，或者当前 队列只剩下一个 goroutine 的时候，Mutex 切换到饥饿模式。

**总结：**

对于两种模式，正常模式下的性能是最好的，goroutine 可以连续多次获取 锁，饥饿模式解决了取锁公平的问题，但是性能会下降，这其实是性能和公平 的一个平衡模式。

### 4.3 Mutex允许自旋的条件

自旋锁是指当一个线程在获取锁的时候，如果锁已经被其他线程获取，那么该线程将循环等待，然后不断地判断是否能够被成功获取，知直到获取到锁才会退出循环。获取锁的线程一直处于活跃状态 Golang中的自旋锁用来实现其他类型的锁,与互斥锁类似，不同点在于，它不是通过休眠来使进程阻塞，而是在获得锁之前一直处于活跃状态(自旋)。

- 锁已被占用，并且锁不处于饥饿模式
- 积累的自旋次数小于最大自旋次数(active_spin=4)
- CPU核数大于1
- 有空闲的P
- 当前Goroutine所挂载的P下，本地待运行队列为空

### 4.4 RWMutex实现

- 写锁只能一个routine拿到、读锁可以同时被多个routine拿到
- 其他要拿锁的必须等待写锁释放后才可以去争抢
- 读锁不阻止其他routine去拿锁，读锁在释放前 拿写锁的routine等待，直到所有锁释放后才可以拿到锁

通过记录 readerCount 读锁的数量来进行控制，当有一个写锁的时候，会将读 锁数量设置为负数 1<<30。目的是让新进入的读锁等待之前的写锁释放通知读 锁。同样的当有写锁进行抢占时，也会等待之前的读锁都释放完毕，才会开始进行后续的操作。 而等写锁释放完之后，会将值重新加上 1<<30, 并通知刚才 新进入的读锁(rw.readerSem)，两者互相限制。

### 4.5 RWMutex注意事项

- RWMutex 是单写多读锁，该锁可以加多个读锁或者一个写锁
- 读锁占用的情况下会阻止写，不会阻止读，多个 Goroutine 可以同时获取读锁
- 写锁会阻止其他 Goroutine(无论读和写)进来，整个锁由该 Goroutine独占
- 适用于读多写少的场景
- RWMutex 类型变量的零值是一个未锁定状态的互斥锁
- RWMutex 在首次被使用之后就不能再被拷贝
- RWMutex 的读锁或写锁在未锁定状态，解锁操作都会引发 panic
- RWMutex 的一个写锁去锁定临界区的共享资源，如果临界区的共享资源已被(读锁或写锁)锁定，这个写锁操作的 goroutine 将被阻塞直到解锁
- RWMutex 的读锁不要用于递归调用，比较容易产生死锁
- RWMutex 的锁定状态与特定的 goroutine 没有关联。一个 goroutine 可以 RLock(Lock)，另一个 goroutine 可以 RUnlock(Unlock)
- 写锁被解锁后，所有因操作锁定读锁而被阻塞的 goroutine 会被唤醒，并都可以成功锁定读锁
- 读锁被解锁后，在没有被其他读锁锁定的前提下，所有因操作锁定写锁而被阻塞的 Goroutine，其中等待时间最长的一个 Goroutine 会被唤醒

### 4.6 broadcast和signal的区别

- Broadcast 会唤醒所有等待的c的goroutine，调用broadcast的时候 可以加锁，也可以不加锁
- Signal会只唤醒一个等待的c的goroutine，调用signal的时候，可以加锁，可以不加锁
## 5. sync包

### 5.1 sync.waitgroup

Go语言中可以使用`sync.WaitGroup`来实现并发任务的同步。`sync.WaitGroup`有以下几个方法：

- Add 添加计数器计数
- Done 减少计数器计数
- Wait 等待计数器数字归零

`sync.WaitGroup`的原理:

1. WaitGroup主要维护了2个计数器，一个是请求计数器v，一个是等待计数器w，二者组成一个64bit的值，请求计数器占高32bit，等待计数器占低32bit.
2. 每次Add执行，请求计数器v加1，Done方法执行，等待计数器减1，v为0时通过信号量唤醒Wait()。

```go
var wg sync.WaitGroup

func hello() {
	defer wg.Done()
	fmt.Println("Hello Goroutine!")
}
func main() {
	wg.Add(1)
	go hello() // 启动另外一个goroutine去执行hello函数
	fmt.Println("main goroutine done!")
	wg.Wait()
}
```

### 5.2 sync.once

在某些场景下我们需要确保某些操作即使在高并发的场景下也只会被执行一次，例如只加载一次配置文件等。`sync`包中提供了一个针对只执行一次场景的解决方案——`sync.Once`，`sync.Once`只有一个`Do`方法。下面是借助`sync.Once`实现的并发安全的单例模式：

```go
type singleton struct {}

var instance *singleton
var once sync.Once

func GetInstance() *singleton {
    once.Do(func() {
        instance = &singleton{}
    })
    return instance
}
```

`sync.Once`其实内部包含一个互斥锁和一个布尔值，互斥锁保证布尔值和数据的安全，而布尔值用来记录初始化是否完成。这样设计就能保证初始化操作的时候是并发安全的并且初始化操作也不会被执行多次。

### 5.3 sync.map

Go 语言中内置的 map 不是并发安全的，我们不能在多个 goroutine 中并发对内置的 map 进行读写操作，否则会存在数据竞争问题。Go语言的`sync`包中提供了一个开箱即用的并发安全版 map——`sync.Map`。开箱即用表示其不用像内置的 map 一样使用 make 函数初始化就能直接使用。同时`sync.Map`内置了诸如`Store(存储k/v)`、`Load(查询k对应v)`、`LoadOrStore(查询或存储k对应v)`、`LoadAndDelete(查询并删除k)`、`Delete(删除k)`、`Range(对k/v依次调用func)`等操作方法。`v`

```go
// 并发安全的map
var m = sync.Map{}

func main() {
	wg := sync.WaitGroup{}
	// 对m执行20个并发的读写操作
	for i := 0; i < 20; i++ {
		wg.Add(1)
		go func(n int) {
			key := strconv.Itoa(n)
			m.Store(key, n)         // 存储key-value
			value, _ := m.Load(key) // 根据key取值
			fmt.Printf("k=:%v,v:=%v
", key, value)
			wg.Done()
		}(i)
	}
	wg.Wait()
}
```

### 5.4 sync.Cond

- Wait 想要只执行一次的内容
- Broadcast 广播给所有在这个cond wait的routine
- Signal 只发送一条消息 只唤醒一个在这个cond wait的routine
- Signal 只发送一条消息 只唤醒一个在这个cond wait的routine

共享的线程安全队列、生产者消费者案例

```go
type Store struct {
	DataCount int
	Max       int
	lock      sync.Mutex
	pCond     *sync.Cond
	cCond     *sync.Cond
}

// 定义生产者和生产的行为
type producer struct{}

func (producer) produce(s *Store) {
	s.lock.Lock()
	defer s.lock.Unlock()
	if s.DataCount == s.Max {
		fmt.Println("生产者在等待消费者拉货")
		s.pCond.Wait()
	}
	fmt.Println("开始生产+1") // 厂库存货不足max
	s.DataCount++
	s.cCond.Signal() // 唤醒一个消费者来消费
}

// 定义消费者和消费的行为
type consumer struct{}

func (consumer) consume(s *Store) {
	s.lock.Lock()
	defer s.lock.Unlock()
	if s.DataCount == 0 {
		fmt.Println("消费者等待生产者生产")
		s.cCond.Wait()
	}
	fmt.Println("消费者消费-1")
	s.DataCount--
	s.cCond.Signal() // 消费了一个 唤醒一个生产者来生产
}

func main() {
	// 定义仓库
	s := &Store{Max: 10}
	s.pCond = sync.NewCond(&s.lock)
	s.cCond = sync.NewCond(&s.lock)

	pCount, cCount := 20, 20
	for i := 0; i < pCount; i++ {
		go func() {
			for {
				time.Sleep(100 * time.Millisecond)
				producer{}.produce(s)
			}
		}()
	}
	for i := 0; i < cCount; i++ {
		go func() {
			for {
				time.Sleep(100 * time.Millisecond)
				consumer{}.consume(s)
			}
		}()
	}
	time.Sleep(1 * time.Second)
	fmt.Println(s.DataCount)
}
```

## 6. 原子操作
针对整数数据类型（int32、uint32、int64、uint64）我们还可以使用原子操作来保证并发安全，通常直接使用原子操作比使用锁操作效率更高。Go语言中原子操作由内置的标准库sync/atomic提供。


## 7. context

### 7.1 context初始

在 Go http包的Server中，每一个请求在都有一个对应的 goroutine 去处理。请求处理函数通常会启动额外的 goroutine 用来访问后端服务，比如数据库和RPC服务。用来处理一个请求的 goroutine 通常需要访问一些与请求特定的数据，比如终端用户的身份认证信息、验证相关的token、请求的截止时间。 当一个请求被取消或超时时，所有用来处理该请求的 goroutine 都应该迅速退出，然后系统才能释放这些 goroutine 占用的资源，此时就可以通过context来实现。

context是golang特有的用来管理多线程上下文、生命周期的设计。

- Goroutine有持久性的特性，需要信号量才可以停止
- 应用程序是逻辑控制的，逻辑结束时需要结束逻辑下生成的、需要结束的Goroutine

Go内置两个函数：`Background()`和`TODO()`，这两个函数分别返回一个实现了`Context`接口的`background`和`todo`。我们代码中最开始都是以这两个内置的上下文对象作为最顶层的`partent context`，衍生出更多的子上下文对象。

`Background()`主要用于main函数、初始化以及测试代码中，作为`Context`这个树结构的最顶层的`Context`，也就是根`Context`。

`TODO()`，它目前还不知道具体的使用场景，如果我们不知道该使用什么`Context`的时候，可以使用这个。

`background`和`todo`本质上都是`emptyCtx`结构体类型，是一个不可取消，没有设置截止时间，没有携带任何值的`Context`。

### 7.1 核心功能与语法

1. `WithCancel` 获得一个可以`cancel`的`context A`, 在取消时, 生成的`context B`以及关注B `context`的`goroutine`都将被取消

```go
eg: 做蛋挞 发现停电了 通知不做了
func withCancel() {
	ctx, cancel := context.WithCancel(context.TODO())
	fmt.Println("做蛋挞")
	go buyOil(ctx)
	go buyEgg(ctx)
	time.Sleep(500 * time.Microsecond)
	cancel() // 当调用 cancel 后，所有由此上下文衍生出的context都会cancel
	time.Sleep(1 * time.Second)
}

func buyEgg(ctx context.Context) {
	fmt.Println("去买蛋")
	select {
	case <-ctx.Done():
		fmt.Println("收到消息不买蛋了")
		return
	default:
	}
	fmt.Println("买蛋")
	go buySEgg(ctx)    // 针对买蛋在做上下文衍生 也可以
	go buyBEgg(ctx)
}
```

2. `withTimeout` 获得一个可以带有定时器的`context`，到时间后自己动`cancel`

```go
eg: 部署一样东西 超时了 就取消部署 返回结果
func withTimeout() {
	ctx, _ := context.WithTimeout(context.TODO(), 1*time.Second) // 后面时间为超时时间
	fmt.Println("开始做什么事情")
	go things(ctx)
	select {
	case <-ctx.Done():
		fmt.Println("任务都超时了 不做了")
	}
	time.Sleep(20 * time.Second)
}

func things(ctx context.Context) {
	fmt.Println("开始做事情1")
	time.Sleep(11 * time.Second)
	select {
	case <-ctx.Done():
		fmt.Println("超时了还没有做好 不做了")
		return
	default:
	}
	fmt.Println("做完了1")
}
```

3. `withvalue` 获得一个带有`key/value`的`context`, 本`context`以及后续任意生成的`context`都可以获得该`key/value`

```go
eg: go版俄罗斯套娃  都能拿到东西
func withValue() {
	ctx := context.WithValue(context.TODO(), "1", "钱包") // 第一个娃装k/v
	go func(ctx context.Context) {
		time.Sleep(1 * time.Second)
		fmt.Println("1: ", ctx.Value("1"))
		fmt.Println("2: ", ctx.Value("2"))
		fmt.Println("3: ", ctx.Value("3"))
		fmt.Println("4: ", ctx.Value("4"))
	}(ctx)
	goTwo(ctx)
}

func goTwo(ctx context.Context) {
	ctx = context.WithValue(ctx, "2", "钱包2") // 第二个
	goThree(ctx)
}

func goThree(ctx context.Context) {
	ctx = context.WithValue(ctx, "3", "钱包3")
	goAll(ctx)
}

func goAll(ctx context.Context) {
	fmt.Println("1: ", ctx.Value("1"))
	fmt.Println("2: ", ctx.Value("2"))
	fmt.Println("3: ", ctx.Value("3"))
	fmt.Println("4: ", ctx.Value("4"))
}
```

4. `withdeadline` 获取一个带有截止时间的`context`, 到截止时间`context`会自动取消 后续生成的也同样自动取消

```go
eg: 设计一个定时器 到点都停止
func withDeadLine() {
	now := time.Now()
	newTime := now.Add(1 * time.Second)
	ctx, _ := context.WithDeadline(context.TODO(), newTime)
	go tv(ctx)
	go game(ctx)
	time.Sleep(2 * time.Second)
}

func game(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			fmt.Println("时间到了，休息不打游戏")
			return
		default:
		}
		fmt.Println("打游戏")
		time.Sleep(300 * time.Millisecond)
	}
}

func tv(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			fmt.Println("时间到了，休息不看电视")
			return
		default:
		}
		fmt.Println("看电视")
		time.Sleep(300 * time.Millisecond)
	}
}
```

### 7.3  客户端示例

```go
// server端，随机出现慢响应

func indexHandler(w http.ResponseWriter, r *http.Request) {
	number := rand.Intn(2)
	if number == 0 {
		time.Sleep(time.Second * 10) // 耗时10秒的慢响应
		fmt.Fprintf(w, "slow response")
		return
	}
	fmt.Fprint(w, "quick response")
}

func main() {
	http.HandleFunc("/", indexHandler)
	err := http.ListenAndServe(":8000", nil)
	if err != nil {
		panic(err)
	}
}
```

```go
// 客户端
type respData struct {
	resp *http.Response
	err  error
}

func doCall(ctx context.Context) {
	transport := http.Transport{
	   // 请求频繁可定义全局的client对象并启用长链接
	   // 请求不频繁使用短链接
	   DisableKeepAlives: true, 	}
	client := http.Client{
		Transport: &transport,
	}

	respChan := make(chan *respData, 1)
	req, err := http.NewRequest("GET", "http://127.0.0.1:8000/", nil)
	if err != nil {
		fmt.Printf("new requestg failed, err:%v
", err)
		return
	}
	req = req.WithContext(ctx) // 使用带超时的ctx创建一个新的client request
	var wg sync.WaitGroup
	wg.Add(1)
	defer wg.Wait()
	go func() {
		resp, err := client.Do(req)
		fmt.Printf("client.do resp:%v, err:%v
", resp, err)
		rd := &respData{
			resp: resp,
			err:  err,
		}
		respChan <- rd
		wg.Done()
	}()

	select {
	case <-ctx.Done():
		//transport.CancelRequest(req)
		fmt.Println("call api timeout")
	case result := <-respChan:
		fmt.Println("call server api success")
		if result.err != nil {
			fmt.Printf("call server api failed, err:%v
", result.err)
			return
		}
		defer result.resp.Body.Close()
		data, _ := ioutil.ReadAll(result.resp.Body)
		fmt.Printf("resp:%v
", string(data))
	}
}

func main() {
	// 定义一个100毫秒的超时
	ctx, cancel := context.WithTimeout(context.Background(), time.Millisecond*100)
	defer cancel() // 调用cancel释放子goroutine资源
	doCall(ctx)
}
```