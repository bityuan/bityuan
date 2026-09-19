# 手动发布 / 补包操作

正常情况下不用看这份文档：合并到 master 后 CI 会自动发版并上传全部 5 个包。
这里只讲**自动流程出问题时，怎么手动把包装上去**。

## 谁可以操作

仓库 **write 权限**（能合并 PR 的人）：仓库 → Actions → 选 workflow → **Run workflow**。
上传用的是仓库里的 `GH_TOKEN` secret，操作者不需要自己的 token，也不需要本地环境。

## 最常用：重新打包并上传（补齐所有平台的包）

**入口**：Actions → **release** → Run workflow，在弹出的输入框里填：

| 参数 | 填什么 | 举例 |
|---|---|---|
| `manual_upload` | **一个已经存在的 release tag**（要带 `v`） | `v6.9.0` |

点 **Run workflow** 就行。它会：

1. 按这个 tag 重新构建**全部 5 个包**：linux、windows `.zip`、windows Qt 安装包、darwin amd64 / arm64；
2. 每个平台起节点跑一次冒烟测试；
3. 校验 Qt 安装包（SFX 脚本完整、无 32 位残留、包内二进制与 zip 一致）；
4. 把这 5 个包**覆盖上传**（`--clobber`）到该 tag 的 release，并刷新 `SHA256SUMS`。

两点注意：

- **不能只补某一个包**——一次触发就是 5 个一起重传（它们必须是同一次构建的产物）；
- 输入框里**必须填 tag，不能填 commit 哈希**（上传目标是已存在的 release）。

## 另一个入口：手动跑一次发版（automake）

**入口**：Actions → **manually auto publish release** → Run workflow（输入随便填）。

用途：push 没能触发发布流程时，手动跑一遍 semantic-release。它会打 tag、发 release、上传 linux 包。

⚠️ **它不能"强制"发版**：如果自上一个 tag 以来没有 `[[FEAT]]` / `[[FIX]]` 这类发版类型的提交，
它会判定"无需发布"直接退出，什么都不做。想发版得先有一个发版类型的提交。

## 什么样的提交才会发版

发版由 semantic-release 判定，它用的是 **jshint 格式**（`.releaserc.yml` 里 `preset: jshint`），
**只认方括号标签、且必须大写**：

| 提交标题写成 | 结果 |
|---|---|
| `[[FEAT]] 描述` | 发 minor（6.8.x → 6.9.0），CHANGELOG 归入 Features |
| `[[FIX]] 描述` | 发 patch（6.8.21 → 6.8.22），CHANGELOG 归入 Bug Fixes |
| 正文含 `BREAKING CHANGE:` | 发 major |

**其他写法一律不发版**，也不会进 CHANGELOG：`feat: xxx`、`fix(scope): xxx`、`ci: xxx`、纯中文描述等。
所以只改 CI / 文档、又想让版本号往前走时，得单独写一个 `[[FIX]] ...` 的提交——
历史上就是这么做的（见 CHANGELOG 6.8.21 的 "trigger patch release for build and CI fixes"）。

## 出问题了怎么判断

| 现象 | 怎么办 |
|---|---|
| 某个平台的包没上传 | 用上面「重新打包」入口，填那个 tag 重跑一遍 |
| 整个 release 都没出来（tag 都没打） | 看 `release` workflow 里 **Release Linux** 的日志：偶发问题（网络 / runner）就重跑那次失败的 run；代码问题就修好后再推一个带 `[[FIX]]` 或 `[[FEAT]]` 的提交 |
| 手动补包跑完，release 里还是缺东西 | 看那次 run 里哪个 job 红了。**冒烟测试没通过时上传会被拦住**（故意的：宁可不上传，也不发没验证过的包） |
| 想核对下载到的文件 | release 里有 `SHA256SUMS`，`shasum -a 256 -c SHA256SUMS`（macOS / Linux） |

## 两个不能碰的地方

- **v6.8.18 release 里的 `bityuan-windows-amd64-qt.exe` 不能删、不能改名、不能覆盖**——
  它是 Qt 安装包的"壳"，打包时会去下载它（76MB）。要换壳得改 `release.yml` 里那一行。
- Qt 包里的钱包 GUI（`bityuan-qt.exe`）还是 2022 年的版本，CI 只替换里面的节点二进制和配置，
  **不验证 GUI**；装完能不能正常用，只能在 Windows 上人工点一遍确认。
