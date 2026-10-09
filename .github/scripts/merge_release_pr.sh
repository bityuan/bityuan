#!/usr/bin/env bash
# Merge the release pull request once the checks on it are green.
#
# Run by the `merge-release-pr` job, which only ever fires for the release pull
# request itself. GitHub's own auto-merge is deliberately not used: turning it on is
# a repository-wide setting, and a person's pull request that is not ready to be
# merged yet must not be merged by GitHub on its own. This script is scoped to one
# pull request, the release one.
#
# GH_TOKEN is the release bot's installation token and not the built-in one. The push
# to master this merge performs is the event that publishes the release, and GitHub
# starts no workflow run for a push caused by GITHUB_TOKEN.
set -euo pipefail

REPO="${REPO:?REPO is required}"
PR="${PR:?PR is required}"
HEAD_SHA="${HEAD_SHA:?HEAD_SHA is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"

# The checks this job waits for are created by the very workflow run it belongs to,
# so for the first seconds the pull request reports none at all: wait for them to show
# up before watching, or `gh pr checks` exits with "no checks reported" and the
# release is never merged.
echo "waiting for checks on #$PR (head $HEAD_SHA) to appear"
for _ in $(seq 1 60); do
  if [ -n "$(gh pr checks "$PR" --repo "$REPO" --required 2>/dev/null)" ]; then
    break
  fi
  sleep 10
done

# `--required` is also what keeps this job from deadlocking on itself: the required
# contexts on master are the platform builds plus build/check_fmt, and this job is not
# one of them. Watching every check would mean waiting for its own still-running job.
gh pr checks "$PR" --repo "$REPO" --required --watch --fail-fast

# Two checks the release depends on are not required on master, so they are named
# here: the dry run with the shape round trip, and the lint and script tests. A
# release must not be merged with them red -- the release body that publish-release
# copies is exactly what they verify.
for name in "Plan the release" "Lint and test the release tooling"; do
  for i in $(seq 1 60); do
    bucket=$(gh pr checks "$PR" --repo "$REPO" --json name,bucket \
      --jq ".[] | select(.name == \"$name\") | .bucket" 2>/dev/null | head -1)
    case "$bucket" in
      pass)
        echo "$name: pass"
        break
        ;;
      fail | cancel)
        echo "$name: $bucket" >&2
        exit 1
        ;;
    esac
    if [ "$i" -eq 60 ]; then
      echo "$name did not pass within the waiting window (last state '${bucket:-missing}')" >&2
      exit 1
    fi
    sleep 10
  done
done

# Checks that finished against an older commit say nothing about the one that is here
# now. A rebuilt release branch gets a run of its own, and that run merges it.
CURRENT=$(gh pr view "$PR" --repo "$REPO" --json headRefOid --jq .headRefOid)
if [ "$CURRENT" != "$HEAD_SHA" ]; then
  echo "the release branch moved to $CURRENT while the checks ran; its own run merges it"
  exit 0
fi

# The sha pins the merge to the commit whose checks just passed: if master or the
# branch moves in between, GitHub refuses instead of merging something unverified.
# Rebase is not a preference here. It keeps the release commit, whose author is the
# bot, as the top commit of master -- and that is the commit the tag and the release
# page then point at.
gh api --method PUT "repos/$REPO/pulls/$PR/merge" \
  -f merge_method=rebase -f sha="$HEAD_SHA" \
  --jq '"merged=\(.merged) at \(.sha)"'
