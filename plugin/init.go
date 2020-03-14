package plugin

import (
	_ "github.com/bityuan/bityuan/plugin/consensus/init" //register consensus init package
	_ "github.com/bityuan/bityuan/plugin/crypto/init"
	_ "github.com/bityuan/bityuan/plugin/dapp/init"
	_ "github.com/bityuan/bityuan/plugin/mempool/init"
	_ "github.com/bityuan/bityuan/plugin/p2p/init"
	_ "github.com/bityuan/bityuan/plugin/store/init"
)
