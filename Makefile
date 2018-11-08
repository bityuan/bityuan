all: vendor build

build:
	go build -i -o bityuan
	go build -i -o bityuan-cli gitlab.33.cn/chain33/bityuan/cli
updatevendor:
	govendor fetch +m

vendor:
	go get -v -u gitlab.33.cn/chain33/chain33
	govendor init
	govendor fetch +m
	govendor add +e
	go build -i -o tool gitlab.33.cn/chain33/chain33/cmd/tools
	./tool import --path "plugin" --packname "gitlab.33.cn/chain33/bityuan/plugin" --conf "plugin/plugin.toml"

clean:
	@rm -rf vendor
	@rm -rf datadir
	@rm -rf logs
	@rm -rf wallet
	@rm -rf grpc33.log
	@rm -rf bityuan
	@rm -rf bityuan-cli
	@rm -rf tool
	@rm -rf plugin/init.go
	@rm -rf plugin/consensus/init
	@rm -rf plugin/dapp/init
	@rm -rf plugin/crypto/init
	@rm -rf plugin/store/init
