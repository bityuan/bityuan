#!/usr/bin/env bash
#
# Open or update the release pull request.
#
# Usage: release_pr.sh <version> <repo> [notes-file]
#
#   <version>     the version semantic-release computed in the dry run
#   <repo>        owner/repo the branch and the pull request live in; pass
#                 "${{ github.repository }}" so that the flow can be rehearsed
#                 on a fork
#   [notes-file]  the release notes, defaulting to $NOTES_FILE
#
# Runs in the plan job of .github/workflows/release.yml, on a checkout of the
# master commit that was just pushed. It pushes the release branch (never
# master) and keeps a single pull request open for it: merging that pull
# request is what releases, and the merge commit is what gets tagged.

set -euo pipefail

BRANCH=release/pending
BASE=master

usage() {
  echo "usage: release_pr.sh <version> <repo> [notes-file]" >&2
  exit 2
}

fail() {
  echo "release_pr: $*" >&2
  exit 1
}

[ "$#" -ge 2 ] || usage

VERSION=$1
REPO=$2
NOTES_FILE=${3:-${NOTES_FILE:-}}

[ -n "$VERSION" ] || fail "the version is empty"
[ -n "$REPO" ] || fail "the repository is empty"
[ -n "$NOTES_FILE" ] || fail "no notes file given (pass it as the third argument or set NOTES_FILE)"
[ -f "$NOTES_FILE" ] || fail "the notes file does not exist: $NOTES_FILE"
[ -s "$NOTES_FILE" ] || fail "the notes file is empty: $NOTES_FILE"
[ -n "${GH_TOKEN:-}" ] || fail "GH_TOKEN is not set"

command -v gh >/dev/null 2>&1 || fail "gh is not installed"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

git rev-parse --show-toplevel >/dev/null 2>&1 || fail "not inside a git repository"
cd "$(git rev-parse --show-toplevel)"

# The commit, the branch, the tag and the pull request are all attributed to the App,
# so that a release reads as one identity from the pull request that carries it to the
# tag that names it -- and so that none of it belongs to whoever owns a personal token.
# It said github-actions[bot] before, which is the built-in token's identity and not the
# one making the push.
#
# The address carries the App's *bot user* id, and that is not its App id: this App is
# 5246955 and its bot user is 339981476. Building the address from the App id links
# nothing -- the author comes out greyed out while the committer, which GitHub writes
# itself, is linked.
#
# Written down rather than read from the token, because it cannot be read from here: an
# installation token is refused by /user ("Resource not accessible by integration"), and
# /app wants a JWT, which is not what this script is given. To look the pair up after
# recreating the App:
#   gh api /users/bityuan-release-bot%5Bbot%5D --jq '.login, .id'
git config user.name 'bityuan-release-bot[bot]'
git config user.email '339981476+bityuan-release-bot[bot]@users.noreply.github.com'

# From the checked-out (just pushed) master commit, so the diff of the pull
# request is exactly the release.
git checkout -B "$BRANCH"

"$SCRIPT_DIR/release_plan.sh" "$VERSION" "$NOTES_FILE"

# Those three paths only, never `git add -A`: nothing else belongs to a release.
git add version/version.go README.md CHANGELOG.md

if git diff --cached --quiet; then
  fail "nothing to commit: master already carries $VERSION, refusing to open an empty release pull request"
fi

MSG=$(mktemp)
trap 'rm -f "$MSG"' EXIT

# Subject and notes only, and never a literal "[skip ci]" anywhere in here: that
# string in a commit message makes GitHub skip the workflows for the whole push.
{
  printf 'chore(release): %s\n\n' "$VERSION"
  cat "$NOTES_FILE"
} > "$MSG"

git commit -F "$MSG"

# The branch is rebuilt from master on every run, so the push has to be forced.
# The lease is the sha that was just fetched. FETCH_HEAD rather than the
# remote-tracking ref on purpose: `git fetch <remote> <branch>` is not guaranteed
# to update the latter, and an empty lease would silently turn the forced push
# into a plain one, which fails on every run after the first. With the lease in
# place the push only goes through while the branch still points where it did a
# moment ago, so a push that landed in between is never overwritten.
#
# On the first run the branch does not exist and the fetch fails: the plain push
# below then creates it. That fallback is safe either way, because a
# non-fast-forward push is rejected rather than overwriting anything.
LEASE=""
if git fetch origin "$BRANCH" 2>/dev/null; then
  LEASE=$(git rev-parse -q --verify FETCH_HEAD || true)
fi

if [ -n "$LEASE" ]; then
  git push --force-with-lease="refs/heads/$BRANCH:$LEASE" origin "$BRANCH"
else
  git push origin "$BRANCH"
fi

TITLE="chore(release): $VERSION"
PR_NUMBER=$(gh pr list --repo "$REPO" --base "$BASE" --head "$BRANCH" --state open \
  --json number --jq '.[0].number // empty')

if [ -n "$PR_NUMBER" ]; then
  echo "release_pr: updating pull request #$PR_NUMBER"
  gh pr edit "$PR_NUMBER" --repo "$REPO" --title "$TITLE" --body-file "$NOTES_FILE" >/dev/null
  URL=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json url --jq .url)
else
  echo "release_pr: opening a pull request"
  URL=$(gh pr create --repo "$REPO" --base "$BASE" --head "$BRANCH" \
    --title "$TITLE" --body-file "$NOTES_FILE")
fi

echo "release_pr: $URL"
