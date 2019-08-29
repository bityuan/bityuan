# golang1.12 or latest
export GO111MODULE=on
CHAIN33_VERSION=$(shell nl go.mod |grep "github.com/33cn/chain33" |awk '{print $$3}')
PLUGIN_VERSION=$(shell nl plugin/go.mod |grep "github.com/33cn/plugin" |awk '{print $$4}')
export CHAIN33_PATH=${GOPATH}/pkg/mod/github.com/33cn/chain33@${CHAIN33_VERSION}
export PLUGIN_PATH=${GOPATH}/pkg/mod/github.com/33cn/plugin@${PLUGIN_VERSION}
PKG_LIST_VET := `go list ./... | grep -v "vendor" | grep -v plugin/dapp/evm/executor/vm/common/crypto/bn256`
PKG_LIST_INEFFASSIGN= `go list -f {{.Dir}} ./... | grep -v "vendor"`
BUILD_FLAGS = -ldflags "-X ${CHAIN33_PATH}/common/version.GitCommit=`git rev-parse --short=8 HEAD`"

.PHONY: default build

default: build

all:  build

build:
	go build ${BUILD_FLAGS} -v -i -o bityuan
	go build ${BUILD_FLAGS} -v -i -o bityuan-cli github.com/bityuan/bityuan/cli


updateplugin:
	@if [ -n "$(version)" ]; then \
	cd plugin  \
	        && go mod edit -require="github.com/33cn/plugin@$(version)"&& cd ../; fi
	@if [ -n "$(commithash)" ]; then   \
	cd plugin \
	&& sed -i 's/github.com\/33cn\/plugin .*/github.com\/33cn\/plugin ${commithash}/g' go.mod \
	&& go mod tidy &&cd ../; fi
	@go mod tidy
updatechain33:
	@if [ -n "$(version)" ]; then \
	        go mod edit -require="github.com/33cn/chain33@$(version)"; fi
	@if [ -n "$(commithash)" ]; then   \
	sed -i 's/github.com\/33cn\/chain33 .*/github.com\/33cn\/chain33 ${commithash}/g' go.mod ; fi
	@go mod tidy

vet:
	@go vet ${PKG_LIST_VET}

ineffassign:
	@golangci-lint  run --no-config --issues-exit-code=1  --deadline=2m --disable-all   --enable=ineffassign -n ${PKG_LIST_INEFFASSIGN}

linter: vet ineffassign ## Use gometalinter check code, ignore some unserious warning
	@./golinter.sh "filter"

.PHONY: checkgofmt
checkgofmt: ## get all go files and run go fmt on them
	@files=$$(find . -name '*.go' -not -path "./vendor/*" | xargs gofmt -l -s); if [ -n "$$files" ]; then \
		  echo "Error: 'make fmt' needs to be run on:"; \
		  echo "${files}"; \
		  exit 1; \
		  fi;
	@files=$$(find . -name '*.go' -not -path "./vendor/*" | xargs goimports -l -w); if [ -n "$$files" ]; then \
		  echo "Error: 'make fmt' needs to be run on:"; \
		  echo "${files}"; \
		  exit 1; \
		  fi;

fmt_shell: ## check shell file
	@find . -name '*.sh' -not -path "./vendor/*" | xargs shfmt -w -s -i 4 -ci -bn

fmt: fmt_shell ## go fmt
	@go fmt ./...
	@find . -name '*.go' -not -path "./vendor/*" | xargs goimports -l -w

autotest: ## build autotest binary
	@cd build/autotest && bash ./build.sh && cd ../../
	@if [ -n "$(dapp)" ]; then \
		rm -rf build/autotest/local \
		&& cp -r $(CHAIN33_PATH)/build/autotest/local $(CHAIN33_PATH)/build/autotest/*.sh build/autotest/ \
		&& cd build/autotest && chmod -R 755 local && chmod 755 *.sh && bash ./copy-autotest.sh local && cd local && bash ./local-autotest.sh $(dapp) && cd ../../../; fi


clean:
	@rm -rf datadir
	@rm -rf logs
	@rm -rf wallet
	@rm -rf grpc33.log
	@rm -rf bityuan
	@rm -rf bityuan-cli
	@rm -rf tool
