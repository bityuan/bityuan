CHAIN33=github.com/33cn/chain33
CHAIN33_PATH=vendor/${CHAIN33}
all: vendor build

build:
	go build -i -o bityuan
	go build -i -o bityuan-cli github.com/bityuan/bityuan/cli

vendor:
	make update
	make updatevendor

update:
	go get -u -v github.com/kardianos/govendor
	rm -rf ${CHAIN33_PATH}
	git clone --depth 1 -b master https://${CHAIN33}.git ${CHAIN33_PATH}
	rm -rf vendor/${CHAIN33}/.git
	rm -rf vendor/${CHAIN33}/vendor/github.com/apache/thrift/tutorial/erl/
	cp -Rf vendor/${CHAIN33}/vendor/* vendor/
	rm -rf vendor/${CHAIN33}/vendor
	govendor init
	go build -i -o tool github.com/33cn/plugin/vendor/github.com/33cn/chain33/cmd/tools
	./tool import --path "plugin" --packname "github.com/bityuan/bityuan/plugin" --conf "plugin/plugin.toml"

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
