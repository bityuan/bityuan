all: vendor build

build:
	go build -i -o tool gitlab.33.cn/chain33/chain33/cmd/tools
	./tool updateinit --path "plugin" --packname "gitlab.33.cn/chain33/bityuan"
	./tool import -path "plugin" --packname "gitlab.33.cn/chain33/bityuan" --conf "plugin/plugin.toml"
	go build -i -o bityuan
	go build -i -o bityuan-cli gitlab.33.cn/chain33/bityuan/cli
updatevendor:
	govendor fetch +m

vendor:
	go get -v -u gitlab.33.cn/chain33/chain33
	govendor init
	govendor fetch +m
	govendor add +e

clean:
	@rm -rf vendor
	@rm -rf bityuan
	@rm -rf bityuan-cli
	@rm -rf tool
	@rm -rf plugin/consensus
	@rm -rf plugin/dapp
	@rm -rf plugin/crypto
	@rm -rf plugin/store
