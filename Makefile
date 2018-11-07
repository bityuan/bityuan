all: vendor build

build:
	go build -o bityuan
	go build -o bityuan-cli gitlab.33.cn/chain33/bityuan/cli
	go build -o tool gitlab.33.cn/chain33/chain33/cmd/tools

vendor:
	govendor init
	govendor fetch +m
	govendor add +e