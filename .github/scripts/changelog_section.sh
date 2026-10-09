#!/usr/bin/env bash
#
# Print the CHANGELOG.md section of one version: the body a release page is
# published with.
#
# Usage: changelog_section.sh <version>     (from the repository root)
#
# A patch release is headed "## [x.y.z](...)" and a minor or major one
# "# [x.y.z](...)"; the section runs up to the next such header. The header line
# itself is part of the body, because that is what the published pages carry.
#
# This lives in a script rather than inline in the workflow so that the plan job
# can read the very same section back on every pull request: the two halves of
# the flow agreeing is a property worth checking before a release needs it.
set -euo pipefail

usage() {
  echo "usage: changelog_section.sh <version>" >&2
  exit 2
}

fail() {
  echo "release_body: $*" >&2
  exit 1
}

[ "$#" -eq 1 ] || usage

VERSION=$1
[ -n "$VERSION" ] || fail "the version is empty"
[ -f CHANGELOG.md ] || fail "CHANGELOG.md not found; run this from the repository root"

# index() rather than a regex: the version goes in as a literal, and a version
# full of dots must not become a pattern that matches something else.
BODY=$(awk -v ver="$VERSION" '
  /^#{1,2} \[/ {
    if (found) exit
    if (index($0, "[" ver "]") > 0) found = 1
  }
  found { print }
' CHANGELOG.md)

[ -n "$BODY" ] || fail "CHANGELOG.md has no section for $VERSION"

printf '%s\n' "$BODY"
