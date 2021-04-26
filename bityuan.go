package main

var bityuan = `
TestNet=false
version="6.5.3"
CoinSymbol="bty"

[crypto]

[blockchain]
defCacheSize=128
maxFetchBlockNum=128
timeoutSeconds=5
batchBlockNum=128
driver="leveldb"
isStrongConsistency=false
singleMode=false
# 分片存储中每个大块包含的区块数，固定参数
chunkblockNum=1000

[p2p]
enable=true
msgCacheSize=10240
driver="leveldb"

[p2p.sub.gossip]
serverStart=true

[p2p.sub.dht]
#bootstraps是内置不能修改的引导节点
bootstraps=["/ip4/39.106.166.159/tcp/13803/p2p/16Uiu2HAmUArNCfwMBigGzQmBVyXiV75qicTQjdJokpb8wXNf7CY3",
"/ip4/116.62.14.25/tcp/13803/p2p/16Uiu2HAmLMuiWz3he9mUviztvEPMsugTRbfC8AUvL9dsqDHYPo5C",
"/ip4/47.106.114.93/tcp/13803/p2p/16Uiu2HAmHtBkrU4s6PgBXuwjJhEaexvenDCdE62xJBcyi8mFGR7Y",
"/ip4/120.76.100.165/tcp/13803/p2p/16Uiu2HAm2HenToxaxfxFoTkX9kZMJ4pRUQK8BNWPCgQF7AvuHs2o",
"/ip4/120.24.85.66/tcp/13803/p2p/16Uiu2HAmDnfooCgiE8ctHrfWqeuFeJXiUDxbMvRLp99ottPH2VVV",
"/ip4/120.24.92.123/tcp/13803/p2p/16Uiu2HAmHD3PrM1cqPPMdrbtd7SHj1wY14XL4NGbTcDVNhH6dyGh",
"/ip4/39.106.193.172/tcp/13803/p2p/16Uiu2HAm19JAcWxkryuYShj6RWn3TGP4Y4Er1DwFe7AC4TevbuU6",
"/ip4/124.71.111.3/tcp/13803/p2p/16Uiu2HAm7ZLbuBNDqfoxggBPDkycioB5Ca8eEti8PSD5wA94L8aV",
"/ip4/124.71.149.47/tcp/13803/p2p/16Uiu2HAmT1cw8dtXwBSqekWqrxdUd2BvEaf25xTFTmpzuxFMgRFS",
"/ip4/139.9.183.97/tcp/13803/p2p/16Uiu2HAm2tDLsDbPtQKEm2mHni3RJuXQhcTa5NyqPY2f1J2P29jm",
"/ip4/124.71.97.194/tcp/13803/p2p/16Uiu2HAm5UwJFNjMnuhGNHCTR5WdN37gEg2mLrpsaNDgE4R3xCEt",
"/ip4/139.9.179.193/tcp/13803/p2p/16Uiu2HAmCGCaMxpH6Wn8YHCLcDGc7D2Zt76e7k2YgXQdvVs7jTPH",
"/ip4/139.159.161.108/tcp/13803/p2p/16Uiu2HAmFCFuMrR6CtgUe3ZrA4AS3VsP2x4tnSKGEF8ZPDyoXdLq",
"/ip4/116.63.185.219/tcp/13803/p2p/16Uiu2HAm4q6wAZMRPyPVhRPVY2eUV9AcMWzXW5FgiGmRozzpL9ws",
"/ip4/139.9.248.40/tcp/13803/p2p/16Uiu2HAmVhCcegye1N3nvScTGvcWSK1BEiJbTErpTFxgzjnxwJQL",
"/ip4/139.9.241.163/tcp/13803/p2p/16Uiu2HAkzBPdRCCGDgUE7UNPrjAdv311JxBUCv4m9GJJXvfRh3g4",
"/ip4/139.9.232.17/tcp/13803/p2p/16Uiu2HAmFtGhxe7EcA31tqi61XRdWycJN8psRzgf6CKcdsUKbn1C",
"/ip4/116.63.176.50/tcp/13803/p2p/16Uiu2HAm8wHrbLi5Abyz3mJe8BDMeP6yLSvLBQ9WxH74cgc6YPHc",
"/ip4/124.71.141.74/tcp/13803/p2p/16Uiu2HAkyxqG3QVHiBTBYUAXN38BXTN4uytUJCK1vT2SgoeMZtvi",
"/ip4/124.71.140.69/tcp/13803/p2p/16Uiu2HAmJ3SUtDJci44TQzKpQYoJJtnkx9qtN5LPTGZFLnyLCpnt",
"/ip4/124.71.162.190/tcp/13803/p2p/16Uiu2HAmTHFqRBqHeimjW27owogR6ZxHGPTgaMumUWH7ukYz16uM",
"/ip4/124.71.146.105/tcp/13803/p2p/16Uiu2HAmBTJQnejJsv8ktePiPBL41oLFSxEpLHN2A67e9jrxmG7m"]
#下一个版本改成: price 模式
[mempool]
name="price"
poolCacheSize=102400
minTxFeeRate=100000
maxTxFee=1000000000
isLevelFee=true

[mempool.sub.score]
poolCacheSize=102400
minTxFee=100000
maxTxNumPerAccount=100
timeParam=1      #时间占价格比例
priceConstant=1544  #手续费相对于时间的一个合适的常量,取当前unxi时间戳前四位数,排序时手续费高1e-5~=快1s
pricePower=1     #常量比例

[mempool.sub.price]
poolCacheSize=102400

[consensus]
name="ticket"
minerstart=true
genesisBlockTime=1514533394
genesis="14KEKbYtKKQm4wMthSK9J4La4nAiidGozt"
minerExecs=["ticket", "autonomy"]
enableBestBlockCmp=true

[mver.consensus]
fundKeyAddr = "1JmFaA6unrCFYEWPGRi7uuXY1KthTJxJEP"
powLimitBits = "0x1f00ffff"
maxTxNumber = 1500

[mver.consensus.ticket]
coinReward = 18
coinDevFund = 12
ticketPrice = 10000
retargetAdjustmentFactor = 4
futureBlockTime = 15
ticketFrozenTime = 43200
ticketWithdrawTime = 172800
ticketMinerWaitTime = 7200
targetTimespan = 2160
targetTimePerBlock = 15

[mver.consensus.ticket.ForkChainParamV2]
coinReward = 5
coinDevFund = 3
targetTimespan = 720
targetTimePerBlock = 5
ticketPrice = 3000

[mver.consensus.ForkTicketFundAddrV1]
fundKeyAddr = "1Ji3W12KGScCM7C2p8bg635sNkayDM8MGY"

[consensus.sub.ticket]
genesisBlockTime=1526486816

[[consensus.sub.ticket.genesis]]
minerAddr="184wj4nsgVxKyz2NhM3Yb5RK5Ap6AFRFq2"
returnAddr="1FB8L3DykVF7Y78bRfUrRcMZwesKue7CyR"
count=3000

[[consensus.sub.ticket.genesis]]
minerAddr="1M4ns1eGHdHak3SNc2UTQB75vnXyJQd91s"
returnAddr="1Lw6QLShKVbKM6QvMaCQwTh5Uhmy4644CG"
count=3000

[[consensus.sub.ticket.genesis]]
minerAddr="19ozyoUGPAQ9spsFiz9CJfnUCFeszpaFuF"
returnAddr="1PSYYfCbtSeT1vJTvSKmQvhz8y6VhtddWi"
count=3000

[[consensus.sub.ticket.genesis]]
minerAddr="1MoEnCDhXZ6Qv5fNDGYoW6MVEBTBK62HP2"
returnAddr="1BG9ZoKtgU5bhKLpcsrncZ6xdzFCgjrZud"
count=3000

[[consensus.sub.ticket.genesis]]
minerAddr="1FjKcxY7vpmMH6iB5kxNYLvJkdkQXddfrp"
returnAddr="1G7s64AgX1ySDcUdSW5vDa8jTYQMnZktCd"
count=3000

[[consensus.sub.ticket.genesis]]
minerAddr="12T8QfKbCRBhQdRfnAfFbUwdnH7TDTm4vx"
returnAddr="1FiDC6XWHLe7fDMhof8wJ3dty24f6aKKjK"
count=3000

[[consensus.sub.ticket.genesis]]
minerAddr="1bgg6HwQretMiVcSWvayPRvVtwjyKfz1J"
returnAddr="1AMvuuQ7V7FPQ4hkvHQdgNWy8wVL4d4hmp"
count=3000

[[consensus.sub.ticket.genesis]]
minerAddr="1EwkKd9iU1pL2ZwmRAC5RrBoqFD1aMrQ2"
returnAddr="1ExRRLoJXa8LzXdNxnJvBkVNZpVw3QWMi4"
count=3000

[[consensus.sub.ticket.genesis]]
minerAddr="1HFUhgxarjC7JLru1FLEY6aJbQvCSL58CB"
returnAddr="1KNGHukhbBnbWWnMYxu1C7YMoCj45Z3amm"
count=3000

[[consensus.sub.ticket.genesis]]
minerAddr="1C9M1RCv2e9b4GThN9ddBgyxAphqMgh5zq"
returnAddr="1AH9HRd4WBJ824h9PP1jYpvRZ4BSA4oN6Y"
count=4733

[store]
name="kvmvccmavl"
driver="leveldb"
storedbVersion="2.0.0"

[wallet]
minFee=100000
driver="leveldb"
signType="secp256k1"

[exec]

[exec.sub.token]
#配置一个空值，防止配置文件被覆盖
tokenApprs = []

[exec.sub.relay]
genesis="14KEKbYtKKQm4wMthSK9J4La4nAiidGozt"

[exec.sub.manage]
superManager=[
    "1JmFaA6unrCFYEWPGRi7uuXY1KthTJxJEP", 
]

[exec.sub.paracross]
nodeGroupFrozenCoins=0
#平行链共识停止后主链等待的高度
paraConsensusStopBlocks=30000

[exec.sub.autonomy]
total="16htvcBNSEA7fZhAdLJphDwQRQJaHpyHTp"
useBalance=false

#系统中所有的fork,默认用chain33的测试网络的
#但是我们可以替换
[fork.system]
ForkChainParamV1= 0
ForkCheckTxDup=0
ForkBlockHash= 1
ForkMinerTime= 0
ForkTransferExec= 100000
ForkExecKey= 200000
ForkTxGroup= 200000
ForkResetTx0= 200000
ForkWithdraw= 200000
ForkExecRollback= 450000
ForkCheckBlockTime=2270000
ForkTxHeight= -1
ForkTxGroupPara= 2270000
ForkChainParamV2= 2270000
ForkMultiSignAddress=2270000
ForkStateDBSet=2270000
ForkLocalDBAccess=2270000
ForkBlockCheck=2270000
ForkBase58AddressCheck=2270000
ForkEnableParaRegExec=2270000
ForkCacheDriver=4320000
ForkTicketFundAddrV1=4320000
#fork for 6.4
ForkRootHash=7200000           

[fork.sub.coins]
Enable=0

[fork.sub.ticket]
Enable=0
ForkTicketId = 1600000
ForkTicketVrf = 2270000

[fork.sub.retrieve]
Enable=0
ForkRetrive=0
ForkRetriveAsset=4320000

[fork.sub.hashlock]
Enable=0
ForkBadRepeatSecret=4320000

[fork.sub.manage]
Enable=0
ForkManageExec=100000

[fork.sub.token]
Enable=0
ForkTokenBlackList= 0
ForkBadTokenSymbol= 0
ForkTokenPrice= 300000
ForkTokenSymbolWithNumber=1600000
ForkTokenCheck= 2270000

[fork.sub.trade]
Enable=0
ForkTradeBuyLimit= 0
ForkTradeAsset= 2270000
ForkTradeID = 2270000
ForkTradeFixAssetDB=4320000
ForkTradePrice=4320000

[fork.sub.paracross]
Enable=1600000
ForkParacrossWithdrawFromParachain=1600000
ForkParacrossCommitTx=2270000
ForkLoopCheckCommitTxDone=4320000
#fork for 6.4
ForkParaAssetTransferRbk=7200000    
ForkParaSelfConsStages=7200000
#仅平行链适用
ForkParaFullMinerHeight=-1

[fork.sub.multisig]
Enable=1600000

[fork.sub.autonomy]
Enable=7200000

[fork.sub.unfreeze]
Enable=1600000
ForkTerminatePart=1600000
ForkUnfreezeIDX= 2270000

[fork.sub.store-kvmvccmavl]
ForkKvmvccmavl=2270000
`
