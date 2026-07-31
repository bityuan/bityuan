#!/bin/bash
# shellcheck disable=SC2207
set +e

OP="${1}"
path="${2}"

function filterLinter() {
    res=$(
        golangci-lint run --no-config --issues-exit-code=1 --timeout=5m -j 1 --disable-all \
            --enable=gofmt \
            --enable=gosimple \
            --enable=unused \
            --enable=unconvert \
            --enable=goimports \
            --enable=misspell \
            --exclude=underscores
    )
    if [[ ${#res} -gt "0" ]]; then
        echo -e "${res}"
        exit 1
    fi
}

function testLinter() {
    cd "${path}" >/dev/null || exit
    golangci-lint run --no-config --issues-exit-code=1 --timeout=5m -j 1 --disable-all \
        --enable=gofmt \
        --enable=gosimple \
        --enable=unused \
        --enable=unconvert \
        --enable=goimports \
        --enable=misspell \
        --exclude=underscores

    cd - >/dev/null || exit
}

function main() {
    if [ "${OP}" == "filter" ]; then
        filterLinter
    elif [ "${OP}" == "test" ]; then
        testLinter
    fi
}

# run script
main
