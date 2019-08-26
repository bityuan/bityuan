#!/usr/bin/env bash

set -e
set -o pipefail
#set -o verbose
#set -o xtrace

sedfix=""
if [ "$(uname)" == "Darwin" ]; then
    sedfix=".bak"
fi

AutoTestMain="${CHAIN33_PATH}/cmd/autotest/main.go"
ImportPlugin='"github.com/33cn/plugin/plugin"'

function build_auto_test() {
    cp ../../bityuan ../chain33
    cp ../../bityuan-cli ../chain33-cli
    cp ../../bityuan.toml ../chain33.toml

    cp "${AutoTestMain}" ./
    sed -i $sedfix "/^package/a import _ ${ImportPlugin}" main.go
    go build -v -i -o autotest

}

function clean_auto_test() {
    rm -f ../autotest/main.go
}

trap "clean_auto_test" INT TERM EXIT

build_auto_test
