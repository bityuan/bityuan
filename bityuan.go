package main

import (
	"fmt"

	"github.com/bityuan/bityuan/version"
)

var bityuan = fmt.Sprintf(`
TestNet=false
version="%s"
CoinSymbol="bty"

[crypto]
enableTypes=[]    #设置启用的加密插件名称，不配置启用所有
[crypto.enableHeight]  #配置已启用插件的启用高度，不配置采用默认高度0， 负数表示不启用
bls=-1
btcscript=19900000
[crypto.sub.secp256k1eth] 
evmChainID=2999

[address]
defaultDriver="btc"
[address.enableHeight]
eth=19900000
btcMultiSign=2270000

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
# blockchain模块保留的区块数，指定最新的reservedBlockNum个区块不参与分片
reservedBlockNum=300000

[p2p]
enable=true
msgCacheSize=10240
driver="leveldb"

[p2p.sub.gossip]
serverStart=true

[p2p.sub.dht]
#bootstraps是内置不能修改的引导节点
bootstraps=["/ip4/13.115.235.168/tcp/13803/p2p/16Uiu2HAkzNiDx1mN6muuBRgPpDRaUG5NGs8HMHmp1HND968Y6Kho",
"/ip4/174.139.188.98/tcp/13803/p2p/16Uiu2HAm7nyy2yYhHW5VkhbXpTo8vqoZNsgzEH8hMNn98UWWfaK6",
"/ip4/23.224.75.178/tcp/13803/p2p/16Uiu2HAmQ9E5dQR1kyQPj1JARsHjNFFVEYZAeQWePM9nysdjPPNC"]

[p2p.sub.dht.broadcast]
# 区块哈希广播最小大小 100KB
minLtBlockSize=100
#关闭交易批量广播功能, 后续全网升级后再开启
disableBatchTx=true
#关闭轻广播方案, 后续全网升级后再开启
disableLtBlock=true

#下一个版本改成: price 模式
[mempool]
name="price"
poolCacheSize=102400
minTxFeeRate=100000
maxTxFee=1000000000
isLevelFee=true

[mver.mempool.ForkMaxTxFeeV1]
# 单笔交易最大的手续费,  50 coins
maxTxFee=5000000000

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
proxyExecAddress="0x0000000000000000000000000000000000200005"
[exec.sub.coins]
#允许evm执行器操作coins
friendExecer=["evm"]

[exec.sub.token]
#配置一个空值，防止配置文件被覆盖
tokenApprs = []

[exec.sub.relay]
genesis="14KEKbYtKKQm4wMthSK9J4La4nAiidGozt"

[exec.sub.manage]
superManager=[
    "1JmFaA6unrCFYEWPGRi7uuXY1KthTJxJEP", 
]
#自治合约执行器名字
autonomyExec="autonomy"

[exec.sub.paracross]
nodeGroupFrozenCoins=0
#平行链共识停止后主链等待的高度
paraConsensusStopBlocks=30000
#配置平行链资产跨链交易的高度列表，title省略user.p,不同title使用,分割，不同hit高度使用"."分割，
#不同ignore高度区间用"."分割，区间内部使用"-"分割，hit高度在ignore范围内，为平行链自身的高度，不是主链高度
## para.hit.10.50.250, para.ignore.1-100.200-300
paraCrossAssetTxHeightList=[
"fzmtest.hit.74485",
"fzmtest.ignore.1-67335.67850-72473.73667-77630.77920-79495.79936-79939",
"game.hit.4203.4226.17725.18195.18403.18405.18859.18951.19393.28966.61168",
"game.ignore.1-8797.16808-20365.25637-33828.43399-44595.58333-166131",
"testuwallet.hit.35556.35564.36505.36511.53386",
"testuwallet.ignore.1-3121.4496-7422.33032-37596.37928-40556.44599-46879.52600-72584",
"mall.hit.80276.80295.81260.81271",
"mall.ignore.1-196397",
"uwallet.hit.9954.39357",
"uwallet.ignore.1-2896.7518-90568",
"HonorDecentchain.ignore.1-90000000",
"HonorDecent.ignore.1-198279",
"bontav1.ignore.1-109068",
"bonta.ignore.1-89729",
"mc.ignore.1-90000000",
"proof.ignore.1-38810"
]


[exec.sub.autonomy]
total="16htvcBNSEA7fZhAdLJphDwQRQJaHpyHTp"
useBalance=false

[mver.autonomy]
#最小委员会数量
minBoards=20
#最大委员会数量
maxBoards=40
#公示一周时间，以区块高度计算
publicPeriod=120960
#单张票价
ticketPrice=3000
#重大项目公示金额阈值
largeProjectAmount=1000000
#创建者消耗金额bty
proposalAmount=500
#董事会成员赞成率，百分比，可修改
boardApproveRatio=51
#全体持票人参与率，百分比
pubAttendRatio=75
#全体持票人赞成率，百分比
pubApproveRatio=66
#全体持票人否决率，百分比
pubOpposeRatio=33
#提案开始结束最小周期高度
startEndBlockPeriod=720
#提案高度 结束高度最大周期 100W
propEndBlockPeriod=1000000
#最小董事会赞成率
minBoardApproveRatio=50
#最大董事会赞成率
maxBoardApproveRatio=66
#最小全体持票人否决率
minPubOpposeRatio=33
#最大全体持票人否决率
maxPubOpposeRatio=50
#可以调整，但是可能需要进行范围的限制：参与率最低设置为 50， 最高设置为 80，赞成率，最低 50.1，最高80
#不能设置太低和太高，太低就容易作弊，太高则有可能很难达到
#最小全体持票人参与率
minPubAttendRatio=50
#最大全体持票人参与率
maxPubAttendRatio=80
#最小全体持票人赞成率
minPubApproveRatio=50
#最大全体持票人赞成率
maxPubApproveRatio=80
#最小公示周期
minPublicPeriod=120960
#最大公示周期
maxPublicPeriod=241920
#最小重大项目阈值(coin)
minLargeProjectAmount=1000000
#最大重大项目阈值(coin)
maxLargeProjectAmount=3000000
#最小提案金(coin)
minProposalAmount=20
#最大提案金(coin)
maxProposalAmount=2000	
#每个时期董事会审批最大额度300万
maxBoardPeriodAmount =3000000
#时期为一个月
boardPeriod=518400
#4w高度，大概2天 (未生效)
itemWaitBlockNumber=40000

[exec.sub.evm]
addressDriver="eth"
ethMapFromExecutor="coins"
#title的币种名称
ethMapFromSymbol="bty" 
#当前最大为200万
evmGasLimit=2000000


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
#eth address key format fork
ForkFormatAddressKey=21000000
ForkCheckEthTxSort=26670000
ForkProxyExec=29528000
ForkMaxTxFeeV1=30839600
ForkEthAddressFormat=32350000

[fork.sub.evm]
Enable=19900000
ForkEVMABI=19900000
ForkEVMYoloV1=19900000
ForkEVMState=19900000
ForkEVMFrozen=19900000
ForkEVMTxGroup=19900000
ForkEVMKVHash=19900000
ForkEVMMixAddress=25200000
ForkIntrinsicGas=25200000
ForkEVMAddressInit=25770000
ForkEvmExecNonce=26670000
ForkEvmExecNonceV2=29528000
[fork.sub.rollup]
Enable=25770000


[fork.sub.none]
ForkUseTimeDelay=23000000

[fork.sub.coins]
Enable=0
ForkFriendExecer=23000000

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
ForkManageAutonomyEnable=19030000

[fork.sub.token]
Enable=0
ForkTokenBlackList= 0
ForkBadTokenSymbol= 0
ForkTokenPrice= 300000
ForkTokenSymbolWithNumber=1600000
ForkTokenCheck= 2270000
ForkTokenEvm=-1
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
ForkParaSupervision=18000000
ForkParaAutonomySuperGroup=19030000
#仅平行链适用
ForkParaFullMinerHeight=-1
ForkParaRootHash=-1
ForkParaFreeRegister=21000000
ForkParaCheckTx=25200000

[fork.sub.multisig]
Enable=1600000

[fork.sub.autonomy]
Enable=7200000
ForkAutonomyDelRule=16000000
ForkAutonomyEnableItem=19030000

[fork.sub.unfreeze]
Enable=1600000
ForkTerminatePart=1600000
ForkUnfreezeIDX= 2270000

[fork.sub.store-kvmvccmavl]
ForkKvmvccmavl=2270000
`, version.Version)
