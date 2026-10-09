#!/usr/bin/env bash
#
# Apply a release to the current working tree.
#
# Usage: release_plan.sh <version> <notes-file>
#
# It rewrites the three files that carry the version and performs no git
# operation at all (no commit, no tag, no branch):
#
#   version/version.go   Version   = "<version>"
#   README.md            the title line, ...（v<version>）
#   CHANGELOG.md         one new section, taken from <notes-file>, on top
#
# Every rewrite is verified: a file that does not have the expected shape
# aborts the script instead of being silently left behind.

set -euo pipefail

usage() {
  echo "usage: release_plan.sh <version> <notes-file>" >&2
  exit 2
}

fail() {
  echo "release_plan: $*" >&2
  exit 1
}

[ "$#" -eq 2 ] || usage

VERSION=$1
NOTES_FILE=$2

[ -n "$VERSION" ] || fail "the version is empty"
[ -f "$NOTES_FILE" ] || fail "the notes file does not exist: $NOTES_FILE"
[ -s "$NOTES_FILE" ] || fail "the notes file is empty: $NOTES_FILE"

for f in version/version.go README.md CHANGELOG.md; do
  [ -f "$f" ] || fail "$f not found; run this from the repository root"
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# --- version/version.go -----------------------------------------------------
# Only the value changes: the old semantic-release-replace-plugin rule kept the
# tab and the "Version" / "=" alignment untouched, and so does this.
if ! grep -Eq '^[[:space:]]*Version[[:space:]]*=[[:space:]]*"' version/version.go; then
  fail 'version/version.go has no Version = "..." line to update'
fi

sed "s|^\([[:space:]]*\)Version[[:space:]]*=.*|\1Version   = \"$VERSION\"|" \
  version/version.go > "$WORK/version.go"
mv "$WORK/version.go" version/version.go

grep -Fq "Version   = \"$VERSION\"" version/version.go \
  || fail "version/version.go was not updated to $VERSION"

# --- README.md --------------------------------------------------------------
README_TITLE='# 基于 chain33 区块链开发 框架 开发的 bityuan 系统（'
if ! grep -Fq "$README_TITLE" README.md; then
  fail 'README.md has no bityuan title line to update'
fi

# ${VERSION} is braced on purpose: a bare $VERSION followed by the full-width
# "）" would be read as a variable whose name includes that character.
sed "s|^${README_TITLE}.*）$|${README_TITLE}v${VERSION}）|" README.md > "$WORK/README.md"
mv "$WORK/README.md" README.md

grep -Fq "${README_TITLE}v${VERSION}）" README.md \
  || fail "README.md was not updated to v$VERSION"

# --- CHANGELOG.md -----------------------------------------------------------
# Layout of the file: the literal word "changelog", a blank line, then the newest
# section and the older ones, each separated by one blank line. The new section
# goes right below the header, keeping that layout.
head -n 1 CHANGELOG.md | grep -qx 'changelog' \
  || fail 'CHANGELOG.md does not start with a "changelog" line'

# The notes become the new section: drop the trailing blank lines so that the
# one blank line this script adds is the only separator before the next section.
awk '{ line[NR] = $0 }
     END {
       last = NR
       while (last > 0 && line[last] ~ /^[[:space:]]*$/) last--
       for (i = 1; i <= last; i++) {
         if (i == last) sub(/[[:space:]]+$/, "", line[i])
         print line[i]
       }
     }' "$NOTES_FILE" > "$WORK/notes"

[ -s "$WORK/notes" ] || fail "the notes file holds nothing but blank lines: $NOTES_FILE"

# Everything below the "changelog" header, without the blank lines that separated
# it from the header (this is the previous newest section).
tail -n +2 CHANGELOG.md \
  | awk '/^[[:space:]]*$/ && !seen { next } { seen = 1; print }' > "$WORK/rest"

[ -s "$WORK/rest" ] || fail 'CHANGELOG.md has no sections below the "changelog" header'

{
  printf 'changelog\n\n'
  cat "$WORK/notes"
  printf '\n'
  cat "$WORK/rest"
} > "$WORK/CHANGELOG.md"
mv "$WORK/CHANGELOG.md" CHANGELOG.md

echo "release_plan: applied $VERSION to version/version.go, README.md and CHANGELOG.md"
