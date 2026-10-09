# Release flow / manual re-packaging

A release happens **only** when a release pull request is merged, and its page is published by
**`bityuan-release-bot[bot]`**. No personal access token is involved, and nothing is pushed straight
to master.

## Cutting a release

1. **Merge a commit that cuts a release** (`feat:` / `fix:` -- see below) into master.
2. **The bot opens a release pull request**: within a minute a `chore(release): X.Y.Z` pull request
   appears on the `release/pending` branch, opened with the App token so it **does run the normal
   checks**. If master moves before it merges, the same pull request is rebuilt and rewritten; a
   second one is never opened.
3. **Review it.** The diff *is* the release: `version/version.go`, `README.md`, one `CHANGELOG.md`
   section. The release page is built from that **CHANGELOG section**, so an operator-facing warning
   belongs in the CHANGELOG diff, where it gets reviewed like anything else. That edit lives on the
   branch, and the branch is rebuilt from master (force-pushed) on every later merge -- so **merge it
   promptly**, or reapply the warning after the next rebuild.
4. **You do not merge it -- the bot does**, once the checks on it are green: master's required checks
   plus the two release-tooling jobs master does not require (the shape round trip; lint and the
   script tests). It merges with **Rebase and merge** through the API.
   - Rebase, not a merge commit: a merge commit is authored by whoever merged, and the newest commit
     on master -- and the tag -- has to be the bot's. Either way the top commit of master is
     `author=bityuan-release-bot[bot]`.
   - An App's events are **not** suppressed, which is the whole reason for the App: a merge made with
     `GITHUB_TOKEN` would leave the release unpublished, with no run to point at.
   - **master requires one approving review, and the bot cannot approve its own pull request.** It
     merges because `bityuan-release-bot` is on the branch protection's **bypass list**; removing it
     there stops every release at this step, leaving a green pull request open. The merge goes through
     the REST API (`PUT /pulls/N/merge`), which honours the bypass -- **`gh pr merge` does not**: it
     reads the pull request's mergeable state first and refuses locally with "the base branch policy
     prohibits the merge", without ever asking the server.
   - A red check merges nothing, by design. Fix it by pushing to master, which rebuilds the branch.
   - GitHub's own auto-merge is deliberately unused: it is a repository-wide setting, and a pull
     request that is not ready must not be merged by GitHub on its own.
5. **That push releases.** `publish-release` takes the matching `CHANGELOG.md` section as the body and
   creates the tag and the release in one call, on the bot's own release commit. Meanwhile
   `build-windows` / `build-macos` / `build-linux` build and smoke-test the five packages; only when
   all three pass does `upload-win-mac` upload them, write `SHA256SUMS`, append the operator footer
   and assert the asset list is complete.

The version is read from **`version/version.go`**, never from the commit subject, so the merge method
does not change *what* is released -- only who the newest commit belongs to. A tag that already exists
(`refs/tags/vX.Y.Z`) is never released twice.

### The release bot

Everything that writes runs with a **GitHub App installation token**: the branch push, the pull
request, the merge, the tag, the release. The App is `bityuan-release-bot`, owned by the `bityuan`
organisation, App ID `5246955`, installed on `bityuan/bityuan`, with two write permissions --
`Contents` and `Pull requests` -- and no webhook.

`APP_ID` and `APP_PRIVATE_KEY` are repository secrets; the workflow mints a per-job token from them
with `actions/create-github-app-token`, so nothing long-lived sits in the repository.

Why not `GITHUB_TOKEN`, which needs no secrets: **GitHub starts no workflow run for an event
`GITHUB_TOKEN` caused.** The release pull request would carry no checks, and its merge would publish
nothing.

**Rotating the key** (every 6-12 months, or at once if it leaks): App settings -> Private keys ->
Generate. The old key keeps working and an App may hold 25, so there is no downtime.

```bash
gh secret set APP_PRIVATE_KEY --repo bityuan/bityuan < new-key.pem
```

`APP_ID` does not change. Delete the old key after one release has gone through. Losing the key is not
fatal either.

## What a commit has to look like to release

semantic-release decides, using **Conventional Commits / angular** (`.releaserc.yml`,
`preset: angular` -- the same convention as chain33 and plugin).

| Subject | Result |
|---|---|
| `feat: ...` / `feat(scope): ...` | minor, under Features |
| `fix: ...` / `perf: ...` | patch, under Bug Fixes / Performance |
| the `Revert "..."` message `git revert` writes, with `This reverts commit <sha>.` in the body | patch |
| a line of its own starting `BREAKING CHANGE:` (indentation allowed) | major |

Two things measured against this repository's own `commit-analyzer`, both counter-intuitive:

- **a hand-written `revert: ...` releases nothing** -- what triggers a patch is the parser's revert
  *message* pattern, not the `revert` type;
- **`!` releases nothing here**: `feat!:` / `chore!:` do not even release a minor, because this
  preset's parser cannot read a header carrying `!`, so the type is never read at all. For a major,
  write `BREAKING CHANGE:` on its own line in the body. A `!` header fails the `release note` check
  (exit 4) -- it is not something you can step over in silence.

**No release**, and no CHANGELOG entry: `docs:` / `refactor:` / `test:` / `chore:` / `build:` / `ci:`,
and a subject with no type prefix at all.

> **The format changed: `[[FEAT]]` / `[[FIX]]` no longer cut a release.** They now fail silently -- no
> error, just no release. `release-note.yml` classifies every commit of a pull request against
> `.releaserc.yml` and names the old form, so this does not go unnoticed.

## The release note check (one per pull request that cuts a release)

The release page carries the CHANGELOG ("what changed", generated) and **Upgrade Notes** ("what an
operator has to do", written by the author) -- different questions, so different sources.

The rule: **a pull request that cuts a release must say what it means for an operator, under a
`## Release note` heading in its description.** A pull request that cuts no release -- `ci:`, `docs:`,
`chore:` and the rest -- has nothing to answer and needs no section at all: the footer skips those
commits, so a note written there goes nowhere.

- Everything under that heading, up to the next heading. `.github/pull_request_template.md` has the
  section already.
- **One per pull request**, not one per commit -- the unit is the change, not the diff.
- Write the **consequence**, not a restatement. 6.9.1 is the counter-example: raising verLimit to
  6.9.0 does not merely reject old nodes, it disconnects and blacklists them for 24 hours -- which no
  commit subject was going to carry.
- One or two sentences (~300 characters); **over 600 fails the check**. Put detail in the body.
- **English** -- it is published to the release page.
- `NONE` when a release-cutting pull request really has nothing an operator needs to act on -- and
  then write just that word. The footer reads the **opening word**, so "NONE -- CI only, no operator
  action." is dropped exactly like a bare `NONE`; a sentence that begins "None of the nodes..." would
  be dropped too, so start such a sentence another way.

It is a **required check on master** (next to `build`, `check_fmt`, the three `Build *`), so it really
does block the merge. **Rewriting the description is enough** -- it subscribes to `edited`, no new
commit needed. The release pull request itself is skipped: its description is generated.

`.github/workflows/release-note.yml` runs `.github/scripts/commit_cuts_release.sh` over the pull
request's commits. **It checks that a note is present and well formed, not that it is true** -- that
half is review, against the diff. A commit pushed straight to master falls back to a `Release-Note:`
line in its body.

At publish time `.github/scripts/add_release_footer.sh` collects one bullet per **release-cutting**
pull request merged between the previous release and this tag, and appends them with the System
Requirements block. Idempotent.

## Who can operate

Anyone with **write** on the repository (anyone who can merge a pull request): merge the release pull
request and you are done. The manual re-pack below runs from Actions and uses the workflow's own
`GITHUB_TOKEN` -- no personal token, no local setup.

## Re-packaging by hand (refill every platform)

Actions -> **release** -> Run workflow, with one input: `manual_upload` = an **existing release tag**
(with the `v`), e.g. `v6.9.0`.

It rebuilds all five packages (linux, windows `.zip`, windows Qt installer, darwin amd64/arm64),
smoke-tests each platform, validates the Qt installer (SFX script intact, no 32-bit leftovers, binary
matches the zip), then overwrites all five on that release (`--clobber`) and refreshes `SHA256SUMS`.

- **One package cannot be refilled alone** -- one run is all five, all from one build.
- **The input is a tag, not a commit** -- the target is an existing release.

## When something is wrong

| Symptom | What to do |
|---|---|
| The release pull request sits there unmerged | Look at the `merge-release-pr` job: it is either waiting or red on a check. **A red check merges nothing, by design** -- land another `fix:`/`feat:` on master and the branch is rebuilt. If it never ran, check the head branch is `release/pending` and the head repository is this one |
| A platform's package is missing | Re-pack with the entry above, on that tag |
| No release at all (no tag) | Did a release pull request appear (`plan-release` computes the version, pushes the branch, opens it)? Then find which of `publish-release` / `build-*` went red. Transient (network, runner): re-run. Code: land another `fix:`/`feat:` |
| Tag exists, release page does not | The one state that needs a human: `is_release` only looks at tags, so CI will not create the page (later pushes skip publishing). Either `gh release create vX.Y.Z --target <commit>`, or delete the tag and let the next push release again. Deleting a release page (GitHub keeps the tag) or tagging by hand lands here |
| `check` says the tag exists, or `publish-release` says the release exists | Normal protection: that version is published. Re-pack for assets; a new version number needs another `fix:`/`feat:` |
| Re-pack finished but the release is still short | See which job went red. **A failed smoke test blocks the upload** -- deliberately: no unverified package is published |
| Verifying a download | `SHA256SUMS` is on the release: `shasum -a 256 -c SHA256SUMS` |

## What runs where

Everything that **writes** can only run during a release, but the decision logic and the scripts run
on every pull request, so a release is not the first time they run at all.

| File / job | What it does | On a pull request |
|---|---|---|
| `release.yml` · `check` | reads the version from `version/version.go`; tag exists -> `is_release=false` | same code the release path uses |
| `release.yml` · `plan-release` | semantic-release **dry run** (computes version and notes, writes nothing); on a push, calls `release_pr.sh` with the **App token** to maintain the release pull request | semantic-release really starts: plugins install, configuration loads, the branch is one it may release from. It does **not** reach the version -- semantic-release returns early on a pull request (`isCi && isPr`), so version and notes are computed on the push to master, which every merge produces |
| `release.yml` · `publish-release` | after the merge, takes the version's `CHANGELOG.md` section as the body and creates tag + release in one call, with the **App token** | skipped (push only) |
| `release.yml` · `merge-release-pr` | release pull request only: waits for master's required checks plus the two tooling jobs, then `merge_method=rebase`. Does not use the repository's auto-merge | exercised for real every release; a wrong branch name in its `if` shows up as a job that never runs -- check `gh pr checks <n>` |
| `.github/scripts/merge_release_pr.sh` | that job's logic: wait for checks to appear, wait for the required ones (`--required --watch --fail-fast`) and the two by name, verify the head sha was not rebuilt, merge with `sha` | — |
| `release.yml` · `lint` | actionlint, shellcheck, and the test scripts | runs |
| `.github/scripts/release_plan.sh` | writes the version into `version/version.go`, `README.md`, `CHANGELOG.md` (working tree only) | the shape check drives it with a synthetic version |
| `.github/scripts/release_pr.sh` | rebuilds `release/pending`, commits as the bot, pushes with `--force-with-lease`, opens or updates the release pull request | `test_release_pr.sh` replays its git half against a local bare repository with a stub `gh` |
| `.github/scripts/check_release_shape.sh` | `release_plan.sh` -> `changelog_section.sh` round trip: a README title, a `version/version.go` line or a `CHANGELOG.md` header that stopped matching fails | runs |
| `.github/scripts/changelog_section.sh` | reads one version's section out of `CHANGELOG.md` | used by the shape check |
| `.github/scripts/add_release_footer.sh` | appends the Upgrade Notes and the System Requirements block at publish time | `test_release_footer.sh` runs it against a stub `gh` |
| `.github/scripts/commit_cuts_release.sh` | classifies one commit against `.releaserc.yml`: exit 0 cuts a release, 1 does not, 2 unmodelled rules, 3 the old `[[FIX]]` form, 4 a `!` header | `test_release_notes.sh`, 30 cases |
| `.github/scripts/extract_release_note.sh` | pulls the note out of a pull request description | `test_release_notes.sh` |
| `.releaserc.yml` | commit-analyzer and release-notes-generator only; everything that writes lives in the workflow and the scripts | — |

`CHANGELOG.md` sections written from the dry-run notes link a short sha (`([5f45ca3](...))`); the
6.9.x entries have empty link text (`([](...))`). Both are shapes this file has always had, not errors.

## Two things not to touch

- **`bityuan-windows-amd64-qt.exe` in the v6.8.18 release**: not to be deleted, renamed or
  overwritten -- it is the Qt installer's shell, downloaded (76 MB) at packaging time.
- The wallet GUI inside the Qt package (`bityuan-qt.exe`) is still from 2022, and CI only replaces the
  node binary and the config: **the GUI is not verified**. Only a manual run on Windows tells you
  whether it works.

## Removed entry point

`automake.yml` (Actions: `manually auto publish release`) is **deleted**. It ran a full
semantic-release with a **PAT**: it pushed the release commit and the tag straight to master and
published the release, bypassing the pull request and every check on it, with the page authored by
whoever owned the token. A live way around every protection is better deleted than documented. There
is one way to release, and it is the one above.

## Package names and the version

Package file names carry the version (`<ver>` below is the version without `v`); for v6.9.1:

| Package | File name |
|---|---|
| Linux | `bityuan-linux-amd64-6.9.1.tar.gz` |
| Windows zip | `bityuan-windows-amd64-6.9.1.zip` |
| Windows Qt installer | `bityuan-windows-amd64-qt-6.9.1.exe` |
| macOS | `bityuan-darwin-amd64-6.9.1.tar.gz`, `bityuan-darwin-arm64-6.9.1.tar.gz` |

The version comes from **`version/version.go`** (the `check` job passes it down), **not `git describe`**:
on this path the tag is pushed after the commit, so `git describe` could still name the previous
release. The manual re-pack uses the tag that was typed in, minus the `v`.

The Windows zip carries `CHANGELOG.md` too (the Linux and macOS tarballs always did).

One exception: **`bityuan-windows-amd64-qt.exe` in the v6.8.18 release keeps its unversioned name** --
packaging downloads it by that name as the shell. What CI builds from it is versioned.

> **A rename breaks consumers outside this repository.** Anything with the old name hard-coded has to
> change with it: `releases/download/<tag>/bityuan-linux-amd64.tar.gz` now 404s, and a script that runs
> `tar xzf bityuan-linux-amd64.tar.gz` finds nothing (the file inside the archive is versioned too).
> One known consumer is `~/.claude/monitors/bityuan_seed_replace.sh`, now a glob. Match with
> `bityuan-linux-amd64-*.tar.gz` rather than pinning a version.
