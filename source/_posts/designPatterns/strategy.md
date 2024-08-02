---
title: 策略模式
date: 2023-04-29 15:43:22
tags: golang
banner_img: /img/index.png
index_img: /img/golang/strategy.png
show_category: true # 表示强制开启
comment: 'valine'
categories:
  - Go系列
  - 三. 设计模式
---
> 主要用于针对某些行为的策略选择，减少多次类型断言或者判断

栗子：利用云厂商的cos进行文件存储时，希望A类型的文件上传到腾讯云；B类型的文件上传到阿里云。

```go
// BucketStrategy 上传策略
type BucketStrategy interface {
	upload(ctx context.Context, file string) error
}

// 定义bucket有哪些 进行选择
var buckets = map[string]BucketStrategy{
	"tencent": &tencentBucket{},
	"ali":     &aliBucket{},
}

func NewBucketStrategy(b string) (BucketStrategy, error) {
	s, ok := buckets[b]
	if !ok {
		return nil, fmt.Errorf("not found bucket %s", b)
	}
	return s, nil
}
```

```go
// 腾讯云bucket
type tencentBucket struct{}

func (t *tencentBucket) upload(ctx context.Context, file string) error {
	//TODO implement me
	panic("implement me")
}

// 阿里云bucket
type aliBucket struct{}

func (a *aliBucket) upload(ctx context.Context, file string) error {
	//TODO implement me
	panic("implement me")
}
```

如上就实现了策略选择的一个大致框架，在使用时只需要判断好文件类型即可，如下：

```go
func TestBucketStrategy(t *testing.T) {
	bucket := getFileType("B")
	bucketStrategy, _ := NewBucketStrategy(bucket)
	_ = bucketStrategy.upload(context.Background(), "localPath")
}

func getFileType(file string) string {
	if file == "A" {return "tencent"}
	return "ali"
}
```