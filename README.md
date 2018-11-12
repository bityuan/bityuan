[![pipeline status](https://api.travis-ci.org/bityuan/bityuan.svg?branch=master)](https://travis-ci.org/bityuan/bityuan/)
[![Go Report Card](https://goreportcard.com/badge/github.com/bityuan/bityuan)](https://goreportcard.com/report/github.com/bityuan/bityuan)

# 基于 chain33 区块链开发 框架 开发的 bityuan 系统

## 安装

#### 安装govendor 工具

```
go get -u -v github.com/kardianos/govendor
```

#### 支持make file的平台

```
git clone https://github.com/bityuan/bityuan $GOPATH/src/github.com/bityuan/bityuan
cd $GOPATH/src/github.com/bityuan/bityuan
make
```

就可以完成编译安装

### 更新chain33

```
make update
```

### 更新 vendor

```
make updatevendor
```

