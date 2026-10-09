#!/usr/bin/env bash
#
# Exercise the git half of release_pr.sh against a local bare repository, with a
# stub `gh`, so that the branch push and the lease are tested without touching
# GitHub. This is the half of the release flow that cannot be rehearsed on a pull
# request any other way: it only runs while a release is being cut, which is the
# worst moment to find out that it does not work.
#
# Usage: test_release_pr.sh     (from the repository root)
#
# Cases: a first run that creates the branch; a run after master moved, where the
# push has to be forced under a valid lease; a branch that somebody else moved
# before the run, which is deliberately replaced; a branch that moves between the
# fetch and the push, which the lease must refuse; and the same version planned
# twice, which must not stack a second section or a second commit.
set -euo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

fail() {
  echo "release_pr test: $*" >&2
  exit 1
}

# --- a stub gh ---------------------------------------------------------------
# `pr list` answers from STUB_PR, so a case can decide whether an open release
# pull request already exists. Every call is recorded for the failure message.
mkdir -p "$ROOT/bin"
cat > "$ROOT/bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "gh $*" >> "${STUB_LOG:-/dev/null}"
case "$1 $2" in
  "pr list") [ -n "${STUB_PR:-}" ] && echo "${STUB_PR}"; exit 0 ;;
  "pr create") echo "https://example.invalid/pull/99"; exit 0 ;;
  "pr edit") exit 0 ;;
  "pr view") echo "https://example.invalid/pull/99"; exit 0 ;;
esac
echo "stub gh: unexpected call: $*" >&2
exit 1
STUB
chmod +x "$ROOT/bin/gh"
PATH="$ROOT/bin:$PATH"
export PATH
export GH_TOKEN=stub
export STUB_LOG="$ROOT/gh.log"
: > "$STUB_LOG"

# --- a remote that looks like this repository --------------------------------
git init -q --bare "$ROOT/origin.git"
git clone -q "$ROOT/origin.git" "$ROOT/clone"
cd "$ROOT/clone"
git config user.name test
git config user.email test@example.invalid
mkdir -p version .github/scripts
# The fixture is the repository's own three files, so the scripts are exercised
# against their real shape rather than against something written for the test.
cp "$HERE/../../version/version.go" version/version.go
cp "$HERE/../../README.md" README.md
cp "$HERE/../../CHANGELOG.md" CHANGELOG.md
cp "$HERE/release_plan.sh" "$HERE/release_pr.sh" .github/scripts/
# The fixture stands one release behind, so that 9.9.9 is the release to plan.
sed -i.bak 's/^\(\s*\)Version\s*=.*/\1Version   = "9.9.8"/' version/version.go
rm -f version/version.go.bak
sed -i.bak 's/（v[0-9.]*）/（v9.9.8）/' README.md
rm -f README.md.bak
git add version/version.go README.md CHANGELOG.md .github/scripts
git commit -qm "chore(release): 9.9.8"
git tag v9.9.8
git push -q origin HEAD:refs/heads/master
git push -q origin v9.9.8
git checkout -q -B master origin/master

NOTES=$ROOT/notes.md
cat > "$NOTES" <<'EOF'
## [9.9.9](https://example.invalid/compare/v9.9.8...v9.9.9) (2026-01-01)


### Bug Fixes

* a fix ([abc1234](https://example.invalid/commit/abc1234))
EOF

# The tip of the release branch, read through FETCH_HEAD: `git fetch <remote>
# <branch>` is not guaranteed to update the remote-tracking ref, which is the trap
# the script itself documents.
remote_tip() {
  git fetch -q origin release/pending
  git rev-parse FETCH_HEAD
}

echo "=== case 1: first run, the branch does not exist ==="
run() { bash .github/scripts/release_pr.sh "$1" test/repo "$NOTES"; }
run 9.9.9 > "$ROOT/out1" 2>&1 || fail "the first run failed: $(cat "$ROOT/out1")"
grep -q "opening a pull request" "$ROOT/out1" || fail "the first run did not open a pull request"
TIP=$(remote_tip)
[ "$(git log -1 --format=%an "$TIP")" = "bityuan-release-bot[bot]" ] || fail "the commit is not attributed to the App"
# The address is the half that links a commit to an account; a name alone leaves the
# author greyed out. It carries the App's *bot user* id, not its App id (5246955) --
# building it from the App id links nothing, and did, unnoticed, until the rehearsal.
[ "$(git log -1 --format=%ae "$TIP")" = "339981476+bityuan-release-bot[bot]@users.noreply.github.com" ] \
  || fail "the commit is not linked to the App's account"
git log -1 --format=%s "$TIP" | grep -qx "chore(release): 9.9.9" || fail "wrong commit subject"
git log -1 --format=%b "$TIP" | grep -q "a fix" || fail "the notes are not in the commit body"
[ -z "$(git status --porcelain)" ] || fail "the working tree was left dirty"
echo "case 1 OK"

echo "=== case 2: master moved, the push has to be forced ==="
git checkout -q -B master origin/master
echo x > later.txt
git add later.txt
git commit -qm "a later change"
git push -q origin HEAD:refs/heads/master
STUB_PR=42 run 9.9.9 > "$ROOT/out2" 2>&1 || fail "the second run failed: $(cat "$ROOT/out2")"
grep -q "updating pull request #42" "$ROOT/out2" || fail "the second run did not update the open pull request"
TIP=$(remote_tip)
git merge-base --is-ancestor "$(git rev-parse origin/master)" "$TIP" \
  || fail "the rebuilt branch does not contain the new master"
echo "case 2 OK"

echo "=== case 3a: somebody else moved the branch before the run ==="
OTHER=$ROOT/other
git clone -q "$ROOT/origin.git" "$OTHER"
( cd "$OTHER" && git config user.name other && git config user.email other@example.invalid \
  && git checkout -q -B release/pending origin/release/pending && echo y > other.txt \
  && git add other.txt && git commit -qm "somebody else's commit" && git push -q origin release/pending )
run 9.9.9 > "$ROOT/out3" 2>&1 || fail "the third run failed: $(cat "$ROOT/out3")"
TIP=$(remote_tip)
git merge-base --is-ancestor "$(git rev-parse origin/master)" "$TIP" \
  || fail "the rebuilt branch does not contain master"
git cat-file -e "$TIP:other.txt" 2>/dev/null && fail "the stale content survived"
echo "case 3a OK"

echo "=== case 3b: the branch moves between the fetch and the push ==="
git fetch -q origin release/pending
LEASE=$(git rev-parse FETCH_HEAD)
( cd "$OTHER" && git fetch -q origin && git checkout -q -B release/pending origin/release/pending \
  && echo z > race.txt && git add race.txt && git commit -qm "a commit racing the plan" \
  && git push -q origin HEAD:release/pending )
BEFORE=$(git ls-remote origin release/pending | cut -f1)
if git push --force-with-lease="refs/heads/release/pending:$LEASE" origin \
     HEAD:refs/heads/release/pending 2> "$ROOT/out3b"; then
  fail "the forced push went through although the branch had moved since the fetch"
fi
# "stale info" is the lease talking; a plain non-fast-forward rejection reads
# differently and would not show that the lease is what stopped it.
grep -q "stale info" "$ROOT/out3b" || fail "unexpected error: $(cat "$ROOT/out3b")"
[ "$BEFORE" = "$(git ls-remote origin release/pending | cut -f1)" ] || fail "the branch was overwritten anyway"
echo "case 3b OK"

echo "=== case 4: the same version planned twice ==="
# In the workflow every plan is a fresh checkout of master, so reproduce it that way.
git checkout -q -B master origin/master
run 9.9.9 > "$ROOT/out4a" 2>&1 || fail "the fourth run failed: $(cat "$ROOT/out4a")"
git checkout -q -B master origin/master
run 9.9.9 > "$ROOT/out4b" 2>&1 || fail "the fifth run failed: $(cat "$ROOT/out4b")"
TIP=$(remote_tip)
SECTIONS=$(git show "$TIP:CHANGELOG.md" | grep -c '^#\{1,2\} \[9.9.9\]')
[ "$SECTIONS" = "1" ] || fail "the branch carries $SECTIONS sections for 9.9.9"
COMMITS=$(git rev-list --count "$(git merge-base origin/master "$TIP")".."$TIP")
[ "$COMMITS" = "1" ] || fail "the branch is $COMMITS commits above master"
echo "case 4 OK"

echo "release_pr test: all cases passed"
