#!/usr/bin/env bash
# Table-driven tests for the two scripts that decide what a release note has to say.
#
# Both are pure functions of their input -- a commit message, a pull request body -- so
# they are pinned here instead of being read and believed. This is the half of the
# release tooling that a pull request can exercise, and the lint job runs it on every
# pull request.
#
#   .github/scripts/test_release_notes.sh
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

cases=0
fail=0

# --- commit_cuts_release.sh ---------------------------------------------------------
# It reads .releaserc.yml out of the working directory, so every case gets a fixture.
expect_rc() { # expect_rc <expected exit> <label> <commit message>
  local want="$1" label="$2" msg="$3" rc=0
  printf '%s' "$msg" | "$HERE/commit_cuts_release.sh" >/dev/null 2>&1 || rc=$?
  cases=$((cases + 1))
  if [ "$rc" != "$want" ]; then
    printf 'FAIL: %s: expected exit %s, got %s\n' "$label" "$want" "$rc" >&2
    fail=$((fail + 1))
  fi
}

angular='{"branches":["master"],"plugins":[["@semantic-release/commit-analyzer",{"preset":"angular"}]]}'
printf '%s\n' "$angular" > .releaserc.yml
expect_rc 0 "feat" 'feat: add a thing'
expect_rc 0 "feat(scope)" 'feat(api): add a thing'
expect_rc 0 "fix" 'fix: correct a thing'
expect_rc 0 "perf" 'perf: speed up a thing'
# `!` releases nothing under this preset -- not major, not minor. These four cases are
# the ones a reader is most likely to assume the opposite of, and they are measured
# against @semantic-release/commit-analyzer@13 rather than read off its rules.
expect_rc 4 "chore with !" 'chore!: drop the old config'
expect_rc 4 "refactor(scope) with !" 'refactor(core)!: drop the old config'
expect_rc 4 "feat with !" 'feat!: drop the old config'
expect_rc 4 "fix with !" 'fix!: drop the old config'
expect_rc 0 "BREAKING CHANGE footer" 'fix: correct a thing

BREAKING CHANGE: the config key moved'
expect_rc 0 "indented BREAKING CHANGE footer" 'fix: correct a thing

  BREAKING CHANGE: the config key moved'
expect_rc 1 "the phrase in prose is not a footer" 'ci(release): tidy up

A note whose text carries a BREAKING CHANGE: mention is still not one.'
# What releases is the message `git revert` writes, not a `revert:` type.
expect_rc 0 "git revert message" 'Revert "feat: add a thing"

This reverts commit 0123456789abcdef.'
expect_rc 1 "chore" 'chore: tidy up'
expect_rc 1 "docs" 'docs: explain a thing'
expect_rc 1 "ci" 'ci: adjust the pipeline'
expect_rc 1 "hand-written revert:" 'revert: undo a thing'
expect_rc 1 "no type at all" '把索引修好了'
expect_rc 3 "old jshint form, fix" '[[FIX]] fix the thing'
expect_rc 3 "old jshint form, feat" '[[FEAT]] add the thing'

printf '%s\n' '{"branches":["master"],"plugins":[["@semantic-release/commit-analyzer",{"preset":"jshint"}]]}' > .releaserc.yml
expect_rc 0 "jshint [[FIX]]" '[[FIX]] fix the thing'
expect_rc 1 "jshint does not know fix:" 'fix: correct a thing'

# A rule set this script does not model has to stop, not answer with the old rules.
printf '%s\n' '{"branches":["master"],"releaseRules":[{"type":"chore","release":"patch"}]}' > .releaserc.yml
expect_rc 2 "unmodelled releaseRules" 'chore: tidy up'

printf '%s\n' '{"branches":["master"],"plugins":[["@semantic-release/commit-analyzer",{"preset":"does-not-exist"}]]}' > .releaserc.yml
expect_rc 2 "unknown preset" 'feat: add a thing'
rm -f .releaserc.yml

# --- extract_release_note.sh ---------------------------------------------------
expect_note() { # expect_note <label> <pull request body> <expected note>
  local label="$1" body="$2" want="$3" got
  got=$(printf '%s' "$body" | "$HERE/extract_release_note.sh")
  cases=$((cases + 1))
  if [ "$got" != "$want" ]; then
    printf 'FAIL: %s: expected [%s], got [%s]\n' "$label" "$want" "$got" >&2
    fail=$((fail + 1))
  fi
}

expect_note "heading" '## Release note

Upgrade every node together.' 'Upgrade every node together.'
expect_note "the template, untouched" '## Release note

<!-- replace this comment with the note -->' ''
expect_note "NONE" '## Release note

NONE' 'NONE'
expect_note "stops at the next heading" '## Release note

One line.

## Anything else

not part of the note' 'One line.'
expect_note "case insensitive heading" '### RELEASE NOTES

Body.' 'Body.'
expect_note "attribution is not part of the note" '## Release note

Body.

🤖 Generated with [Claude Code](https://claude.com/claude-code)' 'Body.'
expect_note "no heading at all" 'Just a description of the change.' ''

if [ "$fail" -ne 0 ]; then
  printf '\nrelease notes test: %s of %s cases failed\n' "$fail" "$cases" >&2
  exit 1
fi
echo "release notes test: all $cases cases passed"
