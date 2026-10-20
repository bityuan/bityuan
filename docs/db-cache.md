# dbCache

`dbCache` is a config value consumed by `chain33/common/db/go_level_db.go` -- one integer that sets three leveldb parameters at once. Before any of it applies, `0` is read as 64 and anything below 4 as 4.

```
open file handles = max(dbCache, 16)
block cache       = dbCache/2 MiB
write buffer      = min(dbCache/4, 16) MiB   (up to three are held in memory; cap from 33cn/chain33#1398)
```

Four databases each carry their own, all editable in `bityuan.toml` / `bityuan-fullnode.toml`:

| database | setting | default | can be raised to |
|---|---|---|---|
| chain `blockchain.db` (~380k SST files) | `[blockchain] dbCache` | 64 | 256 - 1024 |
| state `mavltree` | `[store] dbCache` | 128 | 128 - 512 |
| addrbook / wallet (a few MB) | `[p2p] dbCache` / `[wallet] dbCache` | 4 / 16 | leave at default |

Only the chain database is worth raising. goleveldb must hold a handle on every table it touches, and with hundreds of thousands of SST files in `blockchain.db` against 64 slots, block and transaction-index reads are effectively uncached. State reads (transaction execution, block production) go through the `store` database, which holds far fewer tables and already has 128.

**The default stays 64.** Raising it has not been measured to help: chain33 exposes no read-latency metric, and a node at the chain tip sees too little read pressure to show one. The only workload that would produce that evidence is a full genesis sync. Memory cost if raised: ~+0.25 GiB at 256, ~+0.5 GiB at 512, ~+1 GiB at 1024. Note that `0` means 64 for every database -- it does not mean "use this database's default", so `[store] dbCache=0` gives 64 rather than the shipped 128 -- and that a restart is required.
