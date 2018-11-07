bityuan 系统

### 安装

##### 1. 安装govendor 工具

```
go get -u -v github.com/kardianos/govendor
```

#### 支持make file的平台

```
make
```
就可以完成编译安装

#### 不支持的平台，可以手工执行下面的命令

```
govendor init
govendor fetch +m
govendor add +e
go build -o bityuan
go build -o cli gitlab.33.cn/chain33/chain33/cmd/cli
go build -o tool gitlab.33.cn/chain33/chain33/cmd/tools
```