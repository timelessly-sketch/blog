---
title: 自定义数据类型
date: 2023-02-26 21:09:44
tags: gorm
banner_img: /img/index.png
index_img: /img/gorm.png
show_category: true # 表示强制开启
categories:
  - Go系列
  - 二. 数据库操作 
---
当我们需要存储JSON格式或者数组类型的数据时，数据库并不能直接支持，此时需要自定义数据类型。
自定义数据类型必须实现Scanner和lValuer两个接口，以便让gorm知道如何将该数据类型接收、保存到数据库中。

## 1. 存储JSON格式

需要定义一个机构体，在入库的时候，把他转换为[]byte类型；在出库的时候，转化为结构体。

```go
type Info struct {
	Status string `json:"status"`
	Addr   string `json:"addr"`
	Age    int    `json:"age"`
}

// Scan 从数据库中读取
func (i *Info) Scan(v interface{}) error {
	bytes, ok := v.([]byte)
	if !ok {
		return errors.New(fmt.Sprint("Failed to unmarshal json value: ", v))
	}
	return json.Unmarshal(bytes, i)
}

// Value 存储数据
func (i Info) Value() (driver.Value, error) {
	return json.Marshal(i)
}

type AuthModel struct {
	ID   uint
	Name string
	Info Info `gorm:"type:string"`
}

DB.AutoMigrate(&AuthModel{})
```

创建完成后，数据创建等操作与之前一致，如下：

```go
// 数据创建
DB.Debug().Create(&AuthModel{
    Name: "测试007",
    Info: Info{
        Status: "我姮好",
        Addr:   "1.1.1.1",
        Age:    10,
    },
})
INSERT INTO `tb_auth_model` (`name`,`info`) VALUES ('测试007','{"status":"我姮好","addr":"1.1.1.1","age":10}')
// 在执行数据插入的时候，插入的就是一串字符串
```

```go
// 正常查询
var u AuthModel
DB.Debug().Take(&u)
fmt.Println(u)
```

## 2. 存储数组

```go
// 此种方式存储在数据库的数据为json格式的
type Array []string

// Scan 从数据库中读取
func (i *Array) Scan(v interface{}) error {
	bytes, ok := v.([]byte)
	if !ok {
		return errors.New(fmt.Sprint("Failed to unmarshal json value: ", v))
	}
	return json.Unmarshal(bytes, i)
}

// Value 存储数据
func (i Array) Value() (driver.Value, error) {
	return json.Marshal(i)
}

type HostModel struct {
	ID    uint
	IP    string
	Ports Array `gorm:"type:string"`
}

DB.AutoMigrate(&HostModel{})
```

也可以修改存储在数据库里面的数据的格式类型，方法如下：

```go
// 此时存在数据库中的值为 1|2|3
// Scan 从数据库中读取
func (i *Array) Scan(v interface{}) error {
	bytes, ok := v.([]byte)
	if !ok {
		return errors.New(fmt.Sprintf("解析失败: %v  %T", v, v))
	}
	*i = strings.Split(string(bytes), "|")
	return nil
}

// Value 存储数据
func (i Array) Value() (driver.Value, error) {
	return strings.Join(i, "|"), nil
}
```

## 3. 枚举类型

很多时候，会对一些状态进行判断，这些状态是有限的，数据库里面用字符串存储浪费空间，而且后期可能会出现复制等情况改错值，可以采用枚举类型存储。

```go
type Status int

const (
	Running Status = 1
	Except  Status = 2
	OffLine Status = 3
)

func (s Status) MarshalJSON() ([]byte, error) {
	var str string
	switch s {
	case Running:
		str = "Running"
	case Except:
		str = "Except"
	case OffLine:
		str = "OffLine"
	}
	return json.Marshal(str)
}

type Host struct {
	ID     uint   `json:"id"`
	Name   string `json:"name"`
	Status Status `json:"status"`
}

func main() {
	h := Host{1, "我们我们", Running}
	bytes, _ := json.Marshal(h)
	fmt.Println(string(bytes))
}
```

此时在存储在数据库中就是数字且取出时能自动转换为string，如下：

```go
DB.AutoMigrate(&Host{})
DB.Debug().Create(&Host{Name: "99999", Status: Except})
// INSERT INTO `tb_host` (`name`,`status`) VALUES ('99999','2').  此时插入的是数字
var host Host
DB.Take(&host)
marshal, _ := json.Marshal(&host)   // 取出之后再进行json
fmt.Println(string(marshal)) 
// {"id":1,"name":"99999","status":"Except"}
```