// +build go1.8

package main

import (
	_ "github.com/33cn/chain33/system"
	_ "github.com/bityuan/bityuan/plugin"

	"github.com/33cn/chain33/types"
	"github.com/33cn/chain33/util/cli"
)

func main() {
	types.S("cfg.bityuan", bityuan)
	cli.RunChain33("bityuan")
}
