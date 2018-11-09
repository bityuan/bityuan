CHAIN33=gitlab.33.cn/chain33/chain33

all: vendor build

build:
	go build -i -o bityuan
	go build -i -o bityuan-cli gitlab.33.cn/chain33/bityuan/cli

vendor:
	make update
	make updatevendor

update:
	rm -rf vendor/${CHAIN33}
	git clone --depth 1 -b master https://${CHAIN33}.git vendor/${CHAIN33}
	rm -rf vendor/${CHAIN33}/.git
	cp -R vendor/${CHAIN33}/vendor/* vendor/
	rm -rf vendor/${CHAIN33}/vendor
	govendor init
	go build -i -o tool gitlab.33.cn/chain33/bityuan/vendor/${CHAIN33}/cmd/tools
	./tool import --path "plugin" --packname "gitlab.33.cn/chain33/bityuan/plugin" --conf ""

updatevendor:
	govendor add +e
	govendor fetch -v +m

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
