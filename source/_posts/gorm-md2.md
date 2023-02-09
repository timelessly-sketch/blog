---
title: gorm.md
date: 2023-02-10 00:08:27
tags: ps3
show_category: true # 表示强制开启
categories:
  - Go进阶训练营
  - "Week02: Go错误处理"
---
# 基础数据类型

```plaintext
1. 函数
2. go mod
3. 单元测试
```

1. ## 函数

### 1.1 实例化

> 针对实例化必须要带上的参数 一般会为该参数构建一个实例化函数

```go
func NewRecode(filePath string) *recode {
	return &recode{
		filePath: filePath,
		yamlPath: filePath + ".yaml",
	}
}

type recode struct {
	filePath string
	yamlPath string
}

func main() {
	r1 := &recode{"了解了解了解"} // 报错

	rr1 := NewRecode("辣椒考虑考虑")
	fmt.Println(rr1) // &{辣椒考虑考虑 辣椒考虑考虑.yaml}
}
```

2. ## `go mod`

### 2.1 初始化

```go
go mod init [模块名]
```

如果我们的项目根目录在`$GOPATH/src/`中，模块名可以不填写，将自动生成，一般是与项目根目录名称同名，如`project1`或`github.com/project1`；如果项目根目录不在`$GOPATH/src/`中，则模块名必须填写，模块名同样可以命名如`project1`或`github.com/project1`，也就是说模块名不一定与路径对应起来，但如果我们使用了路径，如`github.com/project1`，后续也可以把项目搬到`$GOPATH/src/github.com`目录下去。

### 2.2 `replace`工作机制

- 版本替换

```go
google.golang.org/protobuf v1.1.1
```

如果我们想使用protobuf的v1.1.0版本进行构建，可以修改require指定的版本号，还可以使用replace来指定

`正常情况下是不需要用replace的，这不是它的使用场景,下面会有使用场景`

```go
[root@ecs-d8b6]# cat go.mod
module github.com/jk/test
go 1.13
require google.golang.org/protobuf v1.1.1
replace google.golang.org/protobuf v1.1.1 => google.golang.org/protobuf v1.1.0
#此时编译时就会选择v1.1.0 版本，如果没有会自动下载
```

- 替换无法下载的包

大陆网络问题有些包无法下载 比如`golang.org`但是可以从github.com clone下来

```go
replace (
	golang.org/x/text v0.3.2 => github.com/golang/text v0.3.2
)
```

### 2.3 整理依赖包

```go
go mod tidy
```

命令执行后，go mod会去项目文件中发现依赖包，将依赖包名单添加到`go.mod`文件中，自动删除那些有错误或者没有使用的依赖包。

```go
go mod vendor
```

将依赖包下载到本地，防止出现依赖包版本变动或者无法下载

### 2.4 其他

```go
go clean -modcache	// 清除依赖包
go mod edit -droprequire=golang.org/x/text   // 删除单个依赖包
go mod verify		// 校验依赖包是否正确
```

3. ## 单元测试

   单元测试编写规则：

      - 必须包含在以`"_test.go"`结尾的文件中
      - 必须符合命名规则`func TestXxxxx(t *testing.T){}`


