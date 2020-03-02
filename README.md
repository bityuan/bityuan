[![pipeline status](https://api.travis-ci.org/bityuan/bityuan.svg?branch=master)](https://travis-ci.org/bityuan/bityuan/)
[![Go Report Card](https://goreportcard.com/badge/github.com/bityuan/bityuan)](https://goreportcard.com/report/github.com/bityuan/bityuan)
 [![Windows Build Status](https://ci.appveyor.com/api/projects/status/github/bityuan/bityuan?svg=true&branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20failed&pendingText=Windows%20-%20pending)](https://ci.appveyor.com/project/bityuan/bityuan)
# 基于 chain33 区块链开发 框架 开发的 bityuan 系统

官方网站: https://www.bityuan.com

区块链浏览器: https://mainnet.bityuan.com

开发框架：https://chain.33.cn

```
注意: master 分支不是 发布版本, 不要用于生产环境
```
## 安装

#### golang 1.12 or latest


#### 支持make file的平台

```
git clone https://github.com/bityuan/bityuan $GOPATH/src/github.com/bityuan/bityuan

//开启mod功能
export GO111MODULE=on

//国内用户需要导入阿里云代理，用于下载依赖包
export GOPROXY=https://mirrors.aliyun.com/goproxy

cd $GOPATH/src/github.com/bityuan/bityuan

make
```

就可以完成编译安装

### 更新go.mod

```
make update
```



