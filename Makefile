
export GO111MODULE=on
export CHAIN33_PATH=$(shell go list -f {{.Dir}} github.com/33cn/chain33)
export PLUGIN_PATH=$(shell go list -f {{.Dir}} github.com/33cn/plugin)
PKG_LIST_VET := `go list ./... | grep -v "vendor" | grep -v plugin/dapp/evm/executor/vm/common/crypto/bn256`
PKG_LIST_INEFFASSIGN= `go list -f {{.Dir}} ./... | grep -v "vendor"`
LDFLAGS := ' -w -s'
BUILDTIME:=$(shell date +"%Y-%m-%d %H:%M:%S %A")
VERSION=$(shell git describe --tags || git rev-parse --short=8 HEAD)
GitCommit=$(shell git rev-parse --short=8 HEAD)
BUILD_FLAGS := -ldflags '-X "github.com/bityuan/bityuan/version.GitCommit=$(GitCommit)" \
                         -X "github.com/33cn/chain33/common/version.GitCommit=$(GitCommit)" \
                         -X "github.com/bityuan/bityuan/version.BuildTime=$(BUILDTIME)"'

.PHONY: default build

default: build

all:  build

build: toolimport
	CGO_ENABLED=1 go build ${BUILD_FLAGS} -v  -o bityuan
	CGO_ENABLED=1 go build ${BUILD_FLAGS} -v  -o bityuan-cli github.com/bityuan/bityuan/cli


PLATFORM_LIST = \
	darwin-amd64 \
	linux-amd64

WINDOWS_ARCH_LIST = \
	windows-amd64

GOBUILD=CGO_ENABLED=1 go build $(BUILD_FLAGS)' -X "github.com/bityuan/bityuan/version.Version=$(VERSION)"  -w -s'
GOBUILD_NOCGO=CGO_ENABLED=0 go build $(BUILD_FLAGS)' -X "github.com/bityuan/bityuan/version.Version=$(VERSION)"  -w -s'
SRC_CLI := ./cli
SRC := ./
APP := bityuan
CLI := bityuan-cli

linux-action-amd64:
	@echo "Linux x86_64 / glibc >= 2.17" > COMPAT.txt
	@echo "Supports: Ubuntu 18.04+, Debian 10+, CentOS 7+, RHEL 7+, Rocky 8+, Alma 8+" >> COMPAT.txt
	@echo "Alpine: use Docker or glibc compat layer" >> COMPAT.txt
	GOARCH=amd64 GOOS=linux $(GOBUILD) -o $(APP)-linux-amd64 $(SRC)
	GOARCH=amd64 GOOS=linux $(GOBUILD) -o $(CLI)-linux-amd64 $(SRC_CLI)
	chmod +x $(APP)-linux-amd64 $(CLI)-linux-amd64
	tar -zcvf build/$(APP)-linux-amd64.tar.gz $(APP)-linux-amd64  $(CLI)-linux-amd64 CHANGELOG.md bityuan-fullnode.toml bityuan.toml COMPAT.txt

windows-action-amd64:
	GOARCH=amd64 GOOS=windows $(GOBUILD_NOCGO) -o $(APP)-windows-amd64.exe $(SRC)
	GOARCH=amd64 GOOS=windows $(GOBUILD_NOCGO) -o $(CLI)-windows-amd64.exe $(SRC_CLI)
	zip -j build/$(APP)-windows-amd64.zip $(APP)-windows-amd64.exe $(CLI)-windows-amd64.exe CHANGELOG.md bityuan-fullnode.toml bityuan.toml

# CGO=1 native Windows build (used by release CI on windows runner)
windows-release:
	GOARCH=amd64 $(_GOBUILD) -o $(APP)-windows-amd64.exe $(SRC)
	GOARCH=amd64 $(_GOBUILD) -o $(CLI)-windows-amd64.exe $(SRC_CLI)

# Download the previous release's Windows package as template
PREV_RELEASE_TAG ?= v6.8.18
QT_PACKAGE_DIR := build/qt-package

windows-qt-package:
	@echo "Downloading previous release Windows package as template..."
	@mkdir -p $(QT_PACKAGE_DIR)
	@curl -sSL -o $(QT_PACKAGE_DIR)/prev-qt.zip "https://github.com/bityuan/bityuan/releases/download/$(PREV_RELEASE_TAG)/bityuan-windows-amd64-qt.zip"; \
	if [ ! -f $(QT_PACKAGE_DIR)/prev-qt.zip ]; then \
		echo "WARNING: no previous Windows package found, skipping Qt wrap"; exit 0; \
	fi
	@# Extract previous installer
	@if ls $(QT_PACKAGE_DIR)/* 2>/dev/null | head -1 | grep -q .; then \
		7z x $(QT_PACKAGE_DIR)/* -o$(QT_PACKAGE_DIR)/extracted -y > /dev/null; \
		rm -f $(QT_PACKAGE_DIR)/extracted/bityuan.exe \
		      $(QT_PACKAGE_DIR)/extracted/bityuan-cli.exe \
		      $(QT_PACKAGE_DIR)/extracted/bityuan-x86.exe \
		      $(QT_PACKAGE_DIR)/extracted/bityuan-cli-x86.exe \
		      $(QT_PACKAGE_DIR)/extracted/bityuan.toml \
		      $(QT_PACKAGE_DIR)/extracted/bityuan-fullnode.toml \
		      $(QT_PACKAGE_DIR)/extracted/grpc33.log; \
		cp $(APP)-windows-amd64.exe $(QT_PACKAGE_DIR)/extracted/bityuan.exe; \
		cp $(CLI)-windows-amd64.exe $(QT_PACKAGE_DIR)/extracted/bityuan-cli.exe; \
		cp bityuan-fullnode.toml $(QT_PACKAGE_DIR)/extracted/ 2>/dev/null || true; \
		cp bityuan.toml $(QT_PACKAGE_DIR)/extracted/ 2>/dev/null || true; \
		cd $(QT_PACKAGE_DIR)/extracted && zip -r ../../build/$(APP)-windows-amd64-qt.zip . > /dev/null; \
	else \
		echo "No previous Windows package, creating raw .zip"; \
		zip -j build/$(APP)-windows-amd64-qt.zip $(APP)-windows-amd64.exe $(CLI)-windows-amd64.exe bityuan.toml bityuan-fullnode.toml; \
	fi

_GOBUILD := CGO_ENABLED=1 go build $(BUILD_FLAGS)' -w -s'
linux-amd64:
	GOARCH=amd64 GOOS=linux $(_GOBUILD) -o $(APP)-$@ $(SRC)
	GOARCH=amd64 GOOS=linux $(_GOBUILD) -o $(CLI)-$@ $(SRC_CLI)
	chmod +x $(APP)-$@ $(CLI)-$@
	tar -zcvf build/$(APP)-$@.tar.gz $(APP)-$@  $(CLI)-$@ CHANGELOG.md bityuan-fullnode.toml bityuan.toml

darwin-amd64:
	GOARCH=amd64 GOOS=darwin $(_GOBUILD) -o $(APP)-$@ $(SRC)
	GOARCH=amd64 GOOS=darwin $(_GOBUILD) -o $(CLI)-$@ $(SRC_CLI)
	chmod +x $(APP)-$@ $(CLI)-$@
	tar -zcvf build/$(APP)-$@.tar.gz $(APP)-$@  $(CLI)-$@ CHANGELOG.md bityuan-fullnode.toml bityuan.toml

windows-amd64:
	GOARCH=amd64 GOOS=windows $(_GOBUILD) -o $(APP)-$@.exe $(SRC)
	GOARCH=amd64 GOOS=windows $(_GOBUILD) -o $(CLI)-$@.exe $(SRC_CLI)
	#zip -j build/$(APP)-$@.zip $(APP)-$@.exe  $(CLI)-$@.exe CHANGELOG.md bityuan-fullnode.toml bityuan.toml

#make updateplugin version=xxx
#单独更新plugin或chain33, version可以是tag或者commit哈希(tag必须是--vMajor.Minor.Patch--规范格式)
updateplugin:
	@if [ -n "$(version)" ]; then   \
    go get -d github.com/33cn/plugin@${version}; \
    else \
    go get -d github.com/33cn/plugin@master;fi
updatechain33:
	@if [ -n "$(version)" ]; then   \
	go get -d github.com/33cn/chain33@${version}; \
	else \
	go get -d github.com/33cn/chain33@master;fi

#make update version=xxx, 同时更新chain33和plugin, 两个项目必须有相同的tag(tag必须是--vMajor.Minor.Patch--规范格式)
update:updatechain33 updateplugin

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

largefile-check:
	git gc
	./findlargefile.sh

autotest: ## build autotest binary
	@cd build/autotest && bash ./run.sh build && cd ../../
	@if [ -n "$(dapp)" ]; then \
		cd build/autotest && bash ./run.sh local $(dapp) && cd ../../; fi

buildtool: ## chain33 tool
	@go build  -o tool `go list -f {{.Dir}} github.com/33cn/chain33`/cmd/tools

toolimport: buildtool ## update plugin import
	@./tool import --path "plugin" --packname "github.com/bityuan/bityuan/plugin" --conf "plugin/plugin.toml"

clean:
	@rm -rf datadir
	@rm -rf logs
	@rm -rf wallet
	@rm -rf grpc33.log
	@rm -rf bityuan
	@rm -rf bityuan-cli
	@rm -rf tool
