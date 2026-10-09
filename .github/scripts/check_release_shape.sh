#!/usr/bin/env bash
#
# Exercise the release tooling on a fixture, so that a release does not find out
# at release time that one of the three files changed shape.
#
# Usage: check_release_shape.sh     (from the repository root)
#
# It copies version/version.go, README.md and CHANGELOG.md into a scratch
# directory, applies a synthetic release to them with release_plan.sh, and then
# reads the section back with changelog_section.sh. The round trip is the point: the
# plan job writes that section and the publish job reads it back, and nothing
# else checks that the two agree. Nothing in the repository is modified.
set -euo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Not a version anyone will release: it only has to be a well formed one, and it
# must not be able to collide with a real section.
VERSION=9.9.9
PREVIOUS=$(sed -n 's/^#\{1,2\} \[\([^]]*\)\].*/\1/p' CHANGELOG.md | head -1)

fail() {
  echo "release shape: $*" >&2
  exit 1
}

for f in version/version.go README.md CHANGELOG.md; do
  [ -f "$f" ] || fail "$f not found; run this from the repository root"
done
[ -n "$PREVIOUS" ] || fail "CHANGELOG.md has no section header to keep"
[ "$PREVIOUS" != "$VERSION" ] || fail "CHANGELOG.md already carries $VERSION"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/version"
cp version/version.go "$WORK/version/version.go"
cp README.md CHANGELOG.md "$WORK/"

NOTES=$WORK/notes.md
cat > "$NOTES" <<EOF
## [$VERSION](https://example.invalid/compare/v9.9.8...v$VERSION) (2026-01-01)


### Bug Fixes

* preflight fixture ([0000000](https://example.invalid/commit/0000000))
EOF

( cd "$WORK" && bash "$HERE/release_plan.sh" "$VERSION" "$NOTES" >/dev/null ) \
  || fail "release_plan.sh failed on the fixture"

# --- what release_plan.sh had to produce ------------------------------------
grep -qF "Version   = \"$VERSION\"" "$WORK/version/version.go" \
  || fail "version/version.go did not take the version"
# ${VERSION} is braced on purpose: a bare $VERSION followed by the full-width "）"
# would be read as a variable whose name includes that character.
grep -qF "（v${VERSION}）" "$WORK/README.md" \
  || fail "README.md did not take the version"
[ "$(head -n 1 "$WORK/CHANGELOG.md")" = "changelog" ] \
  || fail "CHANGELOG.md lost its header line"
grep -qF "[$PREVIOUS]" "$WORK/CHANGELOG.md" \
  || fail "CHANGELOG.md lost the section for $PREVIOUS"

# --- and what the publish job will read back --------------------------------
EXPECTED=$(cat "$NOTES")
ACTUAL=$(cd "$WORK" && bash "$HERE/changelog_section.sh" "$VERSION")
if [ "$EXPECTED" != "$ACTUAL" ]; then
  diff <(printf '%s\n' "$EXPECTED") <(printf '%s\n' "$ACTUAL") >&2 || true
  fail "changelog_section.sh does not read back what release_plan.sh wrote"
fi

echo "release shape: the release files and the body round trip are intact"
