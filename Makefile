all: vendor build

build:
	go build -i -o bityuan
	go build -i -o bityuan-cli gitlab.33.cn/chain33/bityuan/cli
	go build -i -o tool gitlab.33.cn/chain33/chain33/cmd/tools

vendor:
	govendor init
	govendor fetch +m
	govendor add +e