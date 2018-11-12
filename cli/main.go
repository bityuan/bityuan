// +build go1.8

package main

import (
	_ "github.com/bityuan/bityuan/plugin"
	_ "github.com/33cn/chain33/system"
	"github.com/33cn/chain33/util/cli"
	//_ "github.com/33cn/plugin"
)

func main() {
	cli.Run("", "")
}
