// +build go1.8

package main

import (
	"flag"
	"fmt"
	"runtime/debug"

	_ "github.com/33cn/chain33/system"
	_ "github.com/bityuan/bityuan/plugin"
	"github.com/bityuan/bityuan/version"

	frameVersion "github.com/33cn/chain33/common/version"
	"github.com/33cn/chain33/util/cli"
	pluginVersion "github.com/33cn/plugin/version"
)

var (
	percent    = flag.Int("p", 0, "SetGCPercent")
	versionCmd = flag.Bool("version", false, "bityuan detail version")
)

func main() {
	flag.Parse()
	if *versionCmd {
		fmt.Println(fmt.Sprintf("build time: %s", version.BuildTime))
		fmt.Println(fmt.Sprintf("System version: %s", version.Platform))
		fmt.Println(fmt.Sprintf("Golang version: %s", version.GoVersion))
		fmt.Println(fmt.Sprintf("Bityuan version: %s", version.GetVersion()))
		fmt.Println(fmt.Sprintf("Chain33 frame version: %s", frameVersion.GetVersion()))
		fmt.Println(fmt.Sprintf("Chain33 plugin version: %s", pluginVersion.GetVersion()))
		return
	}
	if *percent < 0 || *percent > 100 {
		*percent = 0
	}
	if *percent > 0 {
		debug.SetGCPercent(*percent)
	}
	cli.RunChain33("bityuan", bityuan)
}
