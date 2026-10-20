# bityuan (v6.9.4)

[![build](https://github.com/bityuan/bityuan/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/bityuan/bityuan/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/bityuan/bityuan?sort=semver)](https://github.com/bityuan/bityuan/releases/latest)
[![Go Report Card](https://goreportcard.com/badge/github.com/bityuan/bityuan)](https://goreportcard.com/report/github.com/bityuan/bityuan)

`bityuan` (BTY) is an EVM-compatible blockchain with a parachain architecture, built
on the [chain33](https://github.com/33cn/chain33) framework.

- Website: <https://www.bityuan.com>
- Block explorer: <https://mainnet.bityuan.com>
- chain33: [source](https://github.com/33cn/chain33), [website and documentation](https://chain.33.cn)

> **`master` is not a release branch.** Do not run it in production -- use the
> [latest release](https://github.com/bityuan/bityuan/releases/latest).

## Where the code lives

The node is assembled from two upstream repositories: [chain33](https://github.com/33cn/chain33),
the blockchain framework, and [plugin](https://github.com/33cn/plugin), which holds the
dapps and the consensus plugins. This repository pins them, carries the network
parameters and the fork heights, and ships the binaries. Code changes belong upstream;
a pull request here is normally a version sync or a configuration change.

## Download

Releases since v6.9.3 ship binaries for every supported platform, named as below,
plus a `SHA256SUMS` file covering them. Earlier releases used other names, and
before v6.9.1 they shipped no checksum file -- read the release page for those.

| Platform | Package |
| --- | --- |
| Linux (glibc >= 2.17) | `bityuan-linux-amd64-<version>.tar.gz` |
| macOS 14+ | `bityuan-darwin-amd64-<version>.tar.gz`, `bityuan-darwin-arm64-<version>.tar.gz` |
| Windows (CLI) | `bityuan-windows-amd64-<version>.zip` |
| Windows (wallet) | `bityuan-windows-amd64-qt-<version>.exe` |

## Build from source

Go 1.22 or newer, and a C compiler: the build sets `CGO_ENABLED=1`, so on Windows
you need MinGW and elsewhere `gcc` or `clang`.

```sh
git clone https://github.com/bityuan/bityuan.git
cd bityuan
make          # builds ./bityuan and ./bityuan-cli
make update   # refreshes go.mod and go.sum
```

## Running a node

Operator settings live in `bityuan.toml`; the archives above ship the configuration
the public network runs with. Network parameters, bootstrap peers, genesis and fork
heights are compiled into the binary, so they change with a release, not with the
file. The value operators most often change is `dbCache` -- see
[docs/db-cache.md](docs/db-cache.md).

## Documentation

<https://docs.bityuan.com> -- quick start, running a main-chain node, the API
reference, wallets and DApp development, in English and Chinese.

## Security

Do not open a public issue for a vulnerability. Report it privately through the
[security policy](SECURITY.md).

## Community

- X: <https://x.com/Bityuanofficial>
- Telegram: <https://t.me/bityuanblockchain>

## License

BSD-2-Clause -- see [LICENSE](LICENSE).
