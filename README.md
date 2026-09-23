[![pipeline status](https://api.travis-ci.org/bityuan/bityuan.svg?branch=master)](https://travis-ci.org/bityuan/bityuan/)
[![Go Report Card](https://goreportcard.com/badge/github.com/bityuan/bityuan)](https://goreportcard.com/report/github.com/bityuan/bityuan)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/github/bityuan/bityuan?svg=true&branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20failed&pendingText=Windows%20-%20pending)](https://ci.appveyor.com/project/bityuan/bityuan)
[![Macos Build Status](https://github.com/bityuan/bityuan/actions/workflows/MacOS.yml/badge.svg)](https://github.com/bityuan/bityuan/actions/workflows/MacOS.yml)

# 基于 chain33 区块链开发 框架 开发的 bityuan 系统（v6.9.1）

官方网站: https://www.bityuan.com

区块链浏览器: https://mainnet.bityuan.com

开发框架：https://chain.33.cn

```
注意: master 分支不是 发布版本, 不要用于生产环境
```

# bug 奖励

我们会对bug 评价4个等级(不会奖励人民币，等值虚拟资产)。
只有影响现有在线运行系统的，并且会产生严重分叉等行为的，才会评价为 L3

```
L0 1000
L1 3000
L2 10000
L3 20000
```

## 安装

#### golang 1.19+


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

## Database cache (dbCache)

`dbCache` is a config value consumed by `chain33/common/db/go_level_db.go` -- one integer that sets three leveldb parameters at once.

```
open file handles = dbCache
block cache       = dbCache/2 MiB
write buffer      = min(dbCache/4, 16) MiB   (two are held in memory; cap from 33cn/chain33#1398)
```

Four databases each carry their own, all editable in `bityuan.toml` / `bityuan-fullnode.toml`:

| database | setting | default | can be raised to |
|---|---|---|---|
| chain `blockchain.db` (~380k SST files) | `[blockchain] dbCache` | 64 | 256 - 1024 |
| state `mavltree` | `[store] dbCache` | 128 | 128 - 512 |
| addrbook / wallet (a few MB) | `[p2p] dbCache` / `[wallet] dbCache` | 4 / 16 | leave at default |

Only the chain database is worth raising. goleveldb must hold a handle on every table it touches, and with hundreds of thousands of SST files against 64 slots the read path is effectively uncached -- while every state read (transaction execution, block production) goes through it.

**The default stays 64.** Raising it has not been measured to help: chain33 exposes no read-latency metric, and a node at the chain tip sees too little read pressure to show one. The only workload that would produce that evidence is a full genesis sync. Memory cost if raised: ~+0.25 GiB at 256, ~+0.5 GiB at 512, ~+1 GiB at 1024. Note that `0` falls back to the default rather than disabling the cache, and that a restart is required.



