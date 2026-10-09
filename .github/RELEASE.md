# Release flow / manual re-packaging

A release happens **only** when a release pull request is merged, and the release page is
published by **`bityuan-release-bot[bot]`**: no personal access token (PAT) is involved anywhere,
and nothing is ever pushed straight to master.

## Cutting a release: merge a commit, then the bot does the rest

1. **Merge a commit that cuts a release** (`feat:` / `fix:`, next section) into master.
2. **The bot opens a release pull request on its own**: within a minute, a pull request titled
   `chore(release): X.Y.Z` appears on the `release/pending` branch. If master moves again before it
   is merged, that same pull request is updated -- the branch is rebuilt, the title and the body are
   rewritten -- and a second one is never opened.
   The branch and the pull request are created with the App token, so the pull request **does run
   the normal checks** (`build`, `check_fmt`, the three platform builds, the release tooling's own
   dry run and lint).
3. **Review it.** The diff *is* the release: it bumps `version/version.go` and `README.md` and adds
   one section to `CHANGELOG.md`. The body of the pull request is the semantic-release note; the
   release page, however, is built from that **CHANGELOG section**, so an operator-facing warning
   ("upgrade every node together", ...) belongs in the CHANGELOG diff, where it is reviewed like any
   other change.
   **That edit lives on the branch, and the branch is rebuilt from master -- and force-pushed -- on
   every later merge, so it is dropped if master moves before this pull request is merged.** Review
   and merge it promptly, or apply the warning again after the next rebuild.
4. **You do not merge it -- the bot does**, and only once the checks on it are green. The job that
   does it waits for the checks master requires, and for the two release-tooling checks that master
   does not require (the dry run with the shape round trip, and the lint and script tests), then
   merges with **Rebase and merge** through the API. Three things to know:
   - **Rebase, not "Create a merge commit".** A merge commit is authored by whoever merged, so the
     newest commit on master would carry that name. Rebasing keeps the release commit exactly as the
     bot wrote it -- `author=bityuan-release-bot[bot]` -- as the top commit of master, and the tag
     lands on it.
   - the merge is a push to master performed by a GitHub App, and **events an App causes do run
     workflows**, which is the whole reason the App is here: a merge done with `GITHUB_TOKEN` would
     leave the release unpublished, with no run to point at.
   - a red check does not merge anything. The pull request stays open and the failing job is the
     place to look; fixing it means pushing to master, which rebuilds the branch and starts over.
   - **master requires one approving review, and the bot cannot give itself one** -- a pull request
     cannot be approved by whoever opened it, and this one is opened by the bot. It merges anyway
     because `bityuan-release-bot` is on the branch protection's bypass list ("Allow specified
     actors to bypass required pull requests"). Removing it there stops every release at the merge
     step, with a green release pull request sitting open. The job merges through the REST API
     (`PUT /pulls/N/merge`), which honours the bypass; `gh pr merge` does not, because it reads the
     pull request's mergeable state first and refuses locally with "the base branch policy prohibits
     the merge" without ever asking the server.
   GitHub's own auto-merge is deliberately **not** used for this: it is a repository-wide setting,
   and a pull request of your own that is not ready yet must not be merged by GitHub on its own.
5. **That push releases.** `publish-release` reads the version, takes the matching section of
   `CHANGELOG.md` as the release body, and creates the tag and the release in a single call, with the
   tag on the commit this push carries -- the bot's own release commit. Meanwhile `build-windows` / `build-macos` / `build-linux` build and
   smoke-test the five packages; only when all three pass does `upload-win-mac` upload them, write
   `SHA256SUMS`, add the System Requirements footer and assert that the asset list is complete.

The version is read from **`version/version.go`**, never from the commit subject, so the flow does not
depend on how the release pull request is merged -- but the merge strategy does decide who the newest
commit on master belongs to, which is why Rebase and merge is the one to use. A version whose tag
(`refs/tags/vX.Y.Z`) already exists is never released twice.

### The release bot

Everything that writes on this path runs with a **GitHub App installation token**: the branch push,
the pull request, the merge, the tag and the release. The App is `bityuan-release-bot` (owned by the
`bityuan` organisation, App ID `5246955`), installed on `bityuan/bityuan` and
`bityuan/release-rehearsal` with exactly two write permissions -- `Contents` and `Pull requests` --
and no webhook.

Its App ID and private key live in the two repository secrets `APP_ID` and `APP_PRIVATE_KEY`. The
workflow mints a token from them per job with `actions/create-github-app-token`; the token expires
with the job, so nothing long-lived sits in the repository.

Why an App and not `GITHUB_TOKEN`, which needs no secrets at all: **GitHub starts no workflow run for
an event `GITHUB_TOKEN` caused.** The release pull request is opened by the bot, so with the built-in
token it carries no checks, and the merge -- which is what pushes to master -- would not trigger the
run that publishes the release. An App's events are not suppressed, so the same automation works with
the built-in token's problem gone.

**Rotating the key** (do this every 6-12 months, or immediately if it leaks):

1. App settings -> Private keys -> **Generate a private key**. GitHub downloads a `.pem`; it is shown
   once and never again. The old key keeps working, and an App may hold up to 25 keys, so there is no
   downtime and no need to touch the installation or the permissions.
2. Store the new key in both repositories:
   `gh secret set APP_PRIVATE_KEY --repo bityuan/bityuan < new-key.pem` and the same for
   `bityuan/release-rehearsal`. `APP_ID` does not change.
3. Wait for one release pull request to be opened, merged and published, then delete the old key in
   the App settings.

Losing the key is not fatal either: generate a new one the same way. The App is never locked out.

## 什么样的提交才会发版

发版由 semantic-release 判定，用的是 **Conventional Commits / angular 格式**
（`.releaserc.yml` 里 `preset: angular`，跟 chain33、plugin 一致）：

| 提交标题写成 | 结果 |
|---|---|
| `feat: 描述` 或 `feat(scope): 描述` | 发 minor（6.8.x → 6.9.0），CHANGELOG 归入 Features |
| `fix: 描述` / `perf: 描述` | 发 patch（6.8.21 → 6.8.22），归入 Bug Fixes / Performance |
| `git revert` 生成的 `Revert "..."` + 正文 `This reverts commit <sha>.` | 发 patch |
| 正文里**独立一行**以 `BREAKING CHANGE:` 开头（允许缩进） | 发 major |

有两点**反直觉，而且实测过**（跑的是本仓同版本的 `commit-analyzer`，不是读它的规则表推的）：

- **手写 `revert: 描述` 不发版**——触发它的是 parser 的 revert **报文模式**，不是 `revert` 这个 type；
- **`!` 在这里一律不发版**：`feat!:` / `chore!:` **连 minor 都不发**，因为本 preset 的 parser 根本解析不了带 `!` 的 header，type 压根没被读出来。要 major 就在正文里单独写一行 `BREAKING CHANGE:`。写了 `!` 会被 `release note` 检查**直接判红**（exit 4），不会让你静默踩过去。

**不发版**（也不进 CHANGELOG）：`docs:` / `refactor:` / `test:` / `chore:` / `build:` / `ci:`，
以及没有任何类型前缀的纯中文描述。只改 CI / 文档、又想让版本号往前走时，提交类型得选
`fix:`（"这是真 bug 修复"）——历史上这类提交见 CHANGELOG 6.8.21。

> **⚠️ 格式换过了：`[[FEAT]]` / `[[FIX]]` 从这次改动起不再触发发版。**
> 老写法现在**静默不发版**——不会报错，只是新版本出不来。为了不让这件事悄悄发生，
> `release-note.yml` 会在 PR 上按 `.releaserc.yml` 的分类规则逐提交判断：一个 PR 里有
> 老写法的提交，检查会直接点出来（见下面「Release note 检查」）。

## Release note 检查（每个 PR 一条）

发版页面上除了 CHANGELOG（说"改了什么"，自动生成），还有一节 **Upgrade Notes**（说"运维要做什么"，
由 PR 作者写）。这两件事问的不是同一个问题，所以来源也不同。

规则只有一条：**一个会触发发版的 PR，必须在其描述里用一个 `## Release note` 段落说明它对运维意味着什么。**

- 写在 PR 描述里的 `## Release note` 标题下，到下一个标题为止，**整段**就是这条 note；
  模板 `.github/pull_request_template.md` 里已经有这个段落；
- **一个 PR 一条**，不是每个提交一条；粒度是"这次变更"，不是"这次 diff"；
- 写**后果**，不写改动复述。反面例子就是 6.9.1：verLimit 提到 6.9.0，而 `checkVersionLimit`
  不只是拒绝老节点——它会**断连并拉黑 24 小时**，这种事写不进提交标题；
- 一两句话（~300 字符），**超过 600 字符检查直接失败**（详情放 PR 正文）；
- 用**英文**（它会被发布到 release 页面）；
- 确实没有运维可见影响时，标题下写 `NONE`。

**这条检查是 master 的必需检查**（与 `build`、`check_fmt`、三个 `Build *` 并列），所以它会真的挡住合并。
**补写 note 不需要再推一次提交**：它订阅了 `edited` 事件，改完 PR 描述会自动重跑。
（release PR 本身被跳过——它的描述是脚本生成的，没有作者可以应答。）

检查由 `.github/workflows/release-note.yml` 承担：它拿 `.github/scripts/commit_cuts_release.sh`
按 `.releaserc.yml` 的分类规则逐提交判断这个 PR 会不会发版——会，就必须有 note。**note 写得对不对
不是 CI 的事**（CI 只能查有没有、格式合不合规），内容是否属实靠 review 对着 diff 看。
推 master 而没走 PR 的提交，回退用提交正文里的 `Release-Note:` 行。

发布时由 `.github/scripts/add_release_footer.sh` 收集：它把上一个 release 到本次 tag 之间
**合并进来的每个 PR** 的 note 渲染成一条 bullet，连同 System Requirements 一起追加到 release 正文后面。
幂等，可重复跑。

## 谁可以操作

仓库 **write 权限**（能合并 PR 的人）：合并 release PR 就行；下面的手动补包入口在
仓库 → Actions → 选 workflow → **Run workflow**。上传用的是 workflow 自带的 `GITHUB_TOKEN`，
操作者不需要自己的 token，也不需要本地环境。

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

## 出问题了怎么判断

| 现象 | 怎么办 |
|---|---|
| release PR 一直在那儿、没被合并 | 看 `merge-release-pr` 那个 job：它要么在等检查，要么红在某个检查上。**红了的检查不合并任何东西**（这是设计）——修完要再落一个 `fix:` 或 `feat:` 提交到 master，分支会重建、流程重来。若是 job 压根没跑，先看 PR 的 head 分支是不是 `release/pending`、head 仓库是不是本仓 |
| 某个平台的包没上传 | 用上面「重新打包」入口，填那个 tag 重跑一遍 |
| 整个 release 都没出来（tag 都没打） | 先看 release PR 有没有出现（`plan-release` 负责算版本、推分支、开 PR）；再看这次 push 的 `publish-release` / `build-*` 哪一步红了。偶发问题（网络 / runner）重跑那次 run；代码问题就修好后再落一个 `fix:` 或 `feat:` 提交 |
| tag 存在、但 release 页面不存在 | 这是唯一必须人动手的状态：`is_release` 只看 tag，所以 CI 不会再为它建 release（每次后续 push 都会跳过发布）。要么手工建（`gh release create vX.Y.Z --target <该提交>`），要么删掉那个 tag 让下一次 push 重新发。删 release 页面（GitHub 保留 tag）、或手工打了 tag，都会落到这里 |
| `check` 说 tag 已存在，或 `publish-release` 说 release 已存在 | 这是**正常保护**：该版本已经发布过，不会再发第二次。要补包走上面的入口；版本号往前走要等下一个 `fix:` / `feat:` |
| 手动补包跑完，release 里还是缺东西 | 看那次 run 里哪个 job 红了。**冒烟测试没通过时上传会被拦住**（故意的：宁可不上传，也不发没验证过的包） |
| 想核对下载到的文件 | release 里有 `SHA256SUMS`，`shasum -a 256 -c SHA256SUMS`（macOS / Linux） |

## What a pull request already checks

Everything in this flow that **writes** -- pushing the branch, opening the pull request, creating the
tag and the release -- can only happen while a release is being cut. Their decision logic and their
scripts, however, run on every pull request, so a release is not the first time they run at all:

| On a pull request | What it proves |
|---|---|
| `check` | the version/tag decision, the same code the release path uses |
| `plan-release` | semantic-release is really started, installs the plugins, loads the configuration and checks that the branch is one it may release from. A broken `.releaserc.yml`, an unresolvable preset or a node setup that drifted shows up here. It does **not** get as far as computing the version on a pull request: semantic-release returns early when it sees a pull request (`isCi && isPr`), so the version and the notes are computed on the push to master instead -- which every merge produces |
| `plan-release` shape check | `release_plan.sh` rewrites the three files for a synthetic version and `changelog_section.sh` reads the section back; a README title, a `version/version.go` line or a `CHANGELOG.md` header that stopped matching what the scripts expect fails the pull request |
| `lint` | actionlint on the workflow, shellcheck on the release scripts, and `test_release_pr.sh`: the branch push and the lease, replayed against a local bare repository with a stub `gh` (the one part of the flow that cannot run on a pull request at all) |
| `build-*` + smoke tests | the three platforms build and pass their smoke test (already the case before) |
| `merge-release-pr` | only on the release pull request: it is the merge itself, so it is exercised for real every release rather than first on the day it matters. A mistaken branch name in its `if` shows up as a job that never runs on the release pull request -- check `gh pr checks <n>` on one |

## 机制速查（维护 release.yml 的人看）

| 文件 / job | 干什么 |
|---|---|
| `release.yml` · `check` | 从 `version/version.go` 读版本号；该版本的 tag 已存在 → `is_release=false`，反之 `is_release=true` |
| `release.yml` · `plan-release` | semantic-release **dry run** 只算下一个版本号和 note（dry run 不写文件、不打 tag）：push 时用 **App token** 调 `release_pr.sh` 维护 release PR，PR 时只跑形状检查 |
| `release.yml` · `publish-release` | 合并后从 `CHANGELOG.md` 取该版本的段落当正文，用 **App token** 一次调用打好 tag、建出 release（作者因此是 `bityuan-release-bot[bot]`） |
| `release.yml` · `merge-release-pr` | 只对 release PR 生效：等 master 要求的检查 + 两个 release 工具检查全绿，再调合并接口（`merge_method=rebase`）。**不依赖仓库的 auto-merge 开关** |
| `.github/scripts/merge_release_pr.sh` | 上面那个 job 的逻辑：先等检查出现（否则 `gh pr checks` 直接报 no checks reported）、`--required --watch --fail-fast` 等必需的、按名字等那两个非必需的、核对 head sha 没被重建、再带 `sha` 合并 |
| `release.yml` · `lint` | actionlint 查 workflow、shellcheck 查 `.github/scripts/*.sh`（PR 与 push 都跑） |
| `.releaserc.yml` | 只剩 commit-analyzer / release-notes-generator（负责算版本号与生成 note）；改版本号、写 CHANGELOG、提交、打 tag、发 release 现在都在 workflow 与脚本里做 |
| `.github/scripts/release_plan.sh` | 把版本号写进 `version/version.go`、`README.md`、`CHANGELOG.md`（只改工作区，不碰 git） |
| `.github/scripts/release_pr.sh` | 重建 `release/pending`、提交（作者是 bot）、push（带 `--force-with-lease`）、开或更新 release PR |
| `.github/scripts/changelog_section.sh` | 从 `CHANGELOG.md` 取某版本的段落：发布时当 release 正文，PR 上被形状检查用来验算 |
| `.github/scripts/check_release_shape.sh` | 合成版本跑一遍 `release_plan.sh` → `changelog_section.sh` 的往返，验证三个文件与读取逻辑仍然对得上 |
| `.github/scripts/test_release_pr.sh` | 用本地裸仓库 + stub `gh` 跑 `release_pr.sh` 的 git 半部分：首次建分支、master 前进后强推、lease 拒绝竞态、同版本连跑不叠加 |

`CHANGELOG.md` 的段落由 dry run 的 note 写成，所以新条目的提交链接文字是短 sha
（`([5f45ca3](...))`），而 6.9.x 那几条是空的 `([](...))`；这是历史格式本来就有过的两种写法，
不是错误。

## 两个不能碰的地方

- **v6.8.18 release 里的 `bityuan-windows-amd64-qt.exe` 不能删、不能改名、不能覆盖**——
  它是 Qt 安装包的"壳"，打包时会去下载它（76MB）。要换壳得改 `release.yml` 里那一行。
- Qt 包里的钱包 GUI（`bityuan-qt.exe`）还是 2022 年的版本，CI 只替换里面的节点二进制和配置，
  **不验证 GUI**；装完能不能正常用，只能在 Windows 上人工点一遍确认。

## 已删除的旧入口

`automake.yml`（Actions 里的 `manually auto publish release`）**已随这次改动删除**。它是旧流程：用
**PAT 跑一次完整 semantic-release，直接往 master 推提交和 tag、并发布 release**——绕过 release PR
这道闸门，release 页作者也会是 PAT 的持有人。留着它就是个活的坑（页面上点一下就能绕开全部保护），
所以不是标注"不要用"，而是删掉。发版只有上面那一条路。

## 包名与版本号

发行包的文件名现在带版本号（下文的 `<ver>` 指不带 `v` 的版本号）。以 v6.9.1 为例：

| 包 | 文件名 |
|---|---|
| Linux | `bityuan-linux-amd64-6.9.1.tar.gz` |
| Windows zip | `bityuan-windows-amd64-6.9.1.zip` |
| Windows Qt 安装包 | `bityuan-windows-amd64-qt-6.9.1.exe` |
| macOS | `bityuan-darwin-amd64-6.9.1.tar.gz`、`bityuan-darwin-arm64-6.9.1.tar.gz` |

版本号**取自 `version/version.go`**（`check` 作业把它作为 `version` 输出传下去），**不用 `git describe`**：
自动发版这条路上 tag 是在提交之后才打的，`git describe` 那时可能还解析到上一个 tag，会把这一版命名成
它的前任。手动补包时用的是输入的那个 tag 去掉 `v`。

Windows 的 zip 现在也含 `CHANGELOG.md`（Linux / macOS 的 tar 本来就有），包被下载解压后仍能自己说明
是哪个版本。

例外只有一处：**v6.8.18 release 里的 `bityuan-windows-amd64-qt.exe` 保持无版本号命名**——打包时要按
这个名字去下载它当“壳”，不能改名；CI 拿它打出来的包是带版本号的。

> **⚠️ 改名会打破仓外的消费方。** 任何写死了老名字的东西都要一起改：直接拼
> `releases/download/<tag>/bityuan-linux-amd64.tar.gz` 的下载链接现在 404，解包脚本里写死
> `tar xzf bityuan-linux-amd64.tar.gz` 的会找不到文件（包内文件名同样带版本号了）。已知的一处是
> `~/.claude/monitors/bityuan_seed_replace.sh`，已改成通配。
> 新名字可以用 `bityuan-linux-amd64-*.tar.gz` 这类通配匹配，别把版本号写死。
