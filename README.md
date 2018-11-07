构造bityuan

### 安装

##### 1. 安装govendor 工具

```
go get -u -v github.com/kardianos/govendor
```

##### 2. 安装chain33 相关的所有依赖

```
govendor init
govendor fetch +m
govendor add +e
```

##### 3. 编译命令行

```
go build -o bityuan
go build -o cli gitlab.33.cn/chain33/chain33/cmd/cli
go build -o tool gitlab.33.cn/chain33/chain33/cmd/tools
```
