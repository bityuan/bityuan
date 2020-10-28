go env -w CGO_ENABLED=0
go build -i -o bityuan
go build -i -o bityuan-cli github.com/bityuan/bityuan/cli
