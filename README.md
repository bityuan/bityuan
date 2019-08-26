[![pipeline status](https://api.travis-ci.org/bityuan/bityuan.svg?branch=master)](https://travis-ci.org/bityuan/bityuan/)
[![Go Report Card](https://goreportcard.com/badge/github.com/bityuan/bityuan)](https://goreportcard.com/report/github.com/bityuan/bityuan)

# 基于 chain33 区块链开发 框架 开发的 bityuan 系统

官方网站: https://www.bityuan.com

区块链浏览器: https://mainnet.bityuan.com

开发框架：https://chain.33.cn

```
注意: master 分支不是 发布版本, 不要用于生产环境
```
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

