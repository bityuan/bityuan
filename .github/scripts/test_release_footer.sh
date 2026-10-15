#!/usr/bin/env bash
# Tests for add_release_footer.sh -- the script that writes the operator-facing part of
# a release page: the "Upgrade Notes" the pull requests declared, and "System
# Requirements".
#
# It reads and writes everything through `gh`, so `gh` is replaced here by a stub that
# answers from a fixture directory. That is what makes this testable at all: it runs only
# on a push to master, which is the one path no pull request check can reach.
#
# Why it exists: the call that picks the previous release passed `--arg v "$V"` to
# `gh api --jq`, which takes a jq program and nothing else. The call failed on every run,
# the `|| true` meant to tolerate a missing release swallowed it, and the release page
# came out with no Upgrade Notes -- silently, on the path that publishes them. The cases
# below run the real script against the real jq program.
#
#   .github/scripts/test_release_footer.sh
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
set -eu
cmd="${1:-}"; shift || true
expr=""; rest=()
while [ $# -gt 0 ]; do
  case "$1" in
    --jq|-q) expr="$2"; shift 2 ;;
    --repo|--json) shift 2 ;;
    *) rest+=("$1"); shift ;;
  esac
done
j() { jq -r "${expr:-.}" "$1"; }
case "$cmd" in
release)
  case "${rest[0]:-}" in
    view) cat "$FIX/body.md" ;;
    edit) cat > "$FIX/edited.md"; echo "edited" ;;
    *) echo "stub gh: unexpected release ${rest[0]:-}" >&2; exit 1 ;;
  esac ;;
pr) cat "$FIX/pr-${rest[1]:-0}.md" ;;
api)
  url="${rest[0]:-}"; url="${url%%\?*}"
  case "$url" in
    */releases)
      if [ -f "$FIX/releases.fail" ]; then exit 1; fi
      j "$FIX/releases.json" ;;
    */compare/*) printf '%s\n' "$url" >> "$FIX/compared.txt"; j "$FIX/commits.json" ;;
    */commits/*/pulls) j "$FIX/pulls-$(basename "$(dirname "$url")").json" ;;
    */commits/*) j "$FIX/commit-$(basename "$url").json" ;;
    *) echo "stub gh: unexpected api $url" >&2; exit 1 ;;
  esac ;;
*) echo "stub gh: unexpected command $cmd" >&2; exit 1 ;;
esac
STUB
chmod +x "$WORK/bin/gh"
export PATH="$WORK/bin:$PATH"

# The footer classifies each commit before it collects anything, and the classifier reads
# .releaserc.yml out of the working directory. The cases run from a directory that has
# one, so they do not depend on where the test was started from.
cd "$WORK"
printf '%s\n' '{"branches":["master"],"plugins":[["@semantic-release/commit-analyzer",{"preset":"angular"}]]}' > .releaserc.yml

cases=0
fail=0

new_case() { # new_case <name>
  CASE="$WORK/$1"
  mkdir -p "$CASE"
  export FIX="$CASE"
  printf 'Changelog text.\n' > "$CASE/body.md"
}

run() { # run <tag>
  REPO=owner/repo "$HERE/add_release_footer.sh" "$1" > "$FIX/stdout.txt" 2> "$FIX/stderr.txt"
}

assert_has() { # assert_has <label> <file> <text>
  cases=$((cases + 1))
  if ! grep -qF -- "$3" "$2" 2>/dev/null; then
    printf 'FAIL: %s: [%s] not found in %s\n' "$1" "$3" "$2" >&2
    fail=$((fail + 1))
  fi
}

assert_lacks() { # assert_lacks <label> <file> <text>
  cases=$((cases + 1))
  if grep -qF -- "$3" "$2" 2>/dev/null; then
    printf 'FAIL: %s: [%s] should not be in %s\n' "$1" "$3" "$2" >&2
    fail=$((fail + 1))
  fi
}

assert_absent() { # assert_absent <label> <file>
  cases=$((cases + 1))
  if [ -e "$2" ]; then
    printf 'FAIL: %s: %s should not exist\n' "$1" "$2" >&2
    fail=$((fail + 1))
  fi
}

# --- the ordinary case: one pull request, one note ------------------------------------
new_case normal
cat > "$FIX/releases.json" <<'EOF'
[{"tag_name": "v6.9.3", "created_at": "2026-10-09T08:00:00Z"},
 {"tag_name": "v6.9.2", "created_at": "2026-09-01T00:00:00Z"}]
EOF
printf '{"commits":[{"sha":"aaaa1111"}]}\n' > "$FIX/commits.json"
printf '[{"number":4}]\n' > "$FIX/pulls-aaaa1111.json"
printf '{"commit":{"message":"fix: a thing\\n"}}\n' > "$FIX/commit-aaaa1111.json"
printf '## Release note\n\nUpgrade every node together.\n' > "$FIX/pr-4.md"
run v6.9.3
assert_has "normal: upgrade notes section" "$FIX/edited.md" "### Upgrade Notes"
assert_has "normal: the note" "$FIX/edited.md" "* Upgrade every node together."
assert_has "normal: system requirements" "$FIX/edited.md" "### System Requirements"
assert_has "normal: the changelog body survives" "$FIX/edited.md" "Changelog text."

# --- the manual repack: $V is an older tag, so the previous release is not the newest --
new_case repack
cat > "$FIX/releases.json" <<'EOF'
[{"tag_name": "v6.9.4", "created_at": "2026-11-01T00:00:00Z"},
 {"tag_name": "v6.9.2", "created_at": "2026-09-01T00:00:00Z"},
 {"tag_name": "v6.9.1", "created_at": "2026-08-01T00:00:00Z"}]
EOF
printf '{"commits":[{"sha":"bbbb2222"}]}\n' > "$FIX/commits.json"
printf '[{"number":7}]\n' > "$FIX/pulls-bbbb2222.json"
printf '{"commit":{"message":"fix: another thing\\n"}}\n' > "$FIX/commit-bbbb2222.json"
printf '## Release note\n\nRepacked for the older tag.\n' > "$FIX/pr-7.md"
run v6.9.2
assert_has "repack: compares against the older tag" "$FIX/compared.txt" "compare/v6.9.1...v6.9.2"
assert_has "repack: the note" "$FIX/edited.md" "* Repacked for the older tag."

# --- no release older than this one: empty notes, and it says so ----------------------
new_case first
printf '[{"tag_name": "v6.9.3", "created_at": "2026-10-09T08:00:00Z"}]\n' > "$FIX/releases.json"
run v6.9.3
assert_lacks "first: no upgrade notes section" "$FIX/edited.md" "### Upgrade Notes"
assert_has "first: warns about the missing previous release" "$FIX/stderr.txt" "no release older than"
assert_has "first: still writes the footer" "$FIX/edited.md" "### System Requirements"

# --- the releases call itself fails: a warning, not a silent empty page ---------------
new_case apifail
printf '[{"tag_name": "v6.9.3", "created_at": "2026-10-09T08:00:00Z"}]\n' > "$FIX/releases.json"
touch "$FIX/releases.fail"
run v6.9.3
assert_has "apifail: warns" "$FIX/stderr.txt" "could not list the releases"
assert_has "apifail: still writes the footer" "$FIX/edited.md" "### System Requirements"

# --- already footered: left alone, so repairing an old release cannot double-append ---
new_case idempotent
printf 'Changelog text.\n\n---\n\n### System Requirements\n\nLinux\n' > "$FIX/body.md"
run v6.9.3
assert_absent "idempotent: does not rewrite the page" "$FIX/edited.md"

# --- a commit that never went through a pull request: the Release-Note trailer ---------
new_case nopr
cat > "$FIX/releases.json" <<'EOF'
[{"tag_name": "v6.9.3", "created_at": "2026-10-09T08:00:00Z"},
 {"tag_name": "v6.9.2", "created_at": "2026-09-01T00:00:00Z"}]
EOF
printf '{"commits":[{"sha":"cccc3333"}]}\n' > "$FIX/commits.json"
printf '[]\n' > "$FIX/pulls-cccc3333.json"
printf '{"commit":{"message":"fix: a thing\\n\\nRelease-Note: Restart every node.\\n"}}\n' > "$FIX/commit-cccc3333.json"
run v6.9.3
assert_has "nopr: the trailer becomes the note" "$FIX/edited.md" "* Restart every node."

# --- a pull request that cuts no release contributes nothing --------------------------
# The note answers "what does this release mean for an operator". A `ci:` pull request has
# nothing to answer, and asking it anyway is how "NONE -- CI only, no operator action."
# reached a published release page.
new_case norelease
cat > "$FIX/releases.json" <<'EOF'
[{"tag_name": "v6.9.3", "created_at": "2026-10-09T08:00:00Z"},
 {"tag_name": "v6.9.2", "created_at": "2026-09-01T00:00:00Z"}]
EOF
printf '{"commits":[{"sha":"dddd4444"}]}\n' > "$FIX/commits.json"
printf '[{"number":9}]\n' > "$FIX/pulls-dddd4444.json"
printf '{"commit":{"message":"ci: tighten the pipeline\\n"}}\n' > "$FIX/commit-dddd4444.json"
printf '## Release note\n\nNothing an operator would see.\n' > "$FIX/pr-9.md"
run v6.9.3
assert_lacks "norelease: nothing collected" "$FIX/edited.md" "### Upgrade Notes"
assert_lacks "norelease: the note text is absent" "$FIX/edited.md" "Nothing an operator would see."

# --- "NONE" however the author spells it out ------------------------------------------
new_case noneword
cat > "$FIX/releases.json" <<'EOF'
[{"tag_name": "v6.9.3", "created_at": "2026-10-09T08:00:00Z"},
 {"tag_name": "v6.9.2", "created_at": "2026-09-01T00:00:00Z"}]
EOF
printf '{"commits":[{"sha":"eeee5555"}]}\n' > "$FIX/commits.json"
printf '[{"number":11}]\n' > "$FIX/pulls-eeee5555.json"
printf '{"commit":{"message":"fix: a thing\\n"}}\n' > "$FIX/commit-eeee5555.json"
printf '## Release note\n\nNONE — CI only, no operator action.\n' > "$FIX/pr-11.md"
run v6.9.3
assert_lacks "noneword: the sentence is not a note" "$FIX/edited.md" "CI only"
assert_lacks "noneword: no section at all" "$FIX/edited.md" "### Upgrade Notes"

# --- rules the classifier cannot model: keep the note rather than drop it on a guess ---
new_case unmodelled
printf '%s\n' '{"branches":["master"],"releaseRules":[{"type":"chore","release":"patch"}]}' > .releaserc.yml
cat > "$FIX/releases.json" <<'EOF'
[{"tag_name": "v6.9.3", "created_at": "2026-10-09T08:00:00Z"},
 {"tag_name": "v6.9.2", "created_at": "2026-09-01T00:00:00Z"}]
EOF
printf '{"commits":[{"sha":"ffff6666"}]}\n' > "$FIX/commits.json"
printf '[{"number":13}]\n' > "$FIX/pulls-ffff6666.json"
printf '{"commit":{"message":"chore: tidy up\\n"}}\n' > "$FIX/commit-ffff6666.json"
printf '## Release note\n\nKept when the rules cannot be read.\n' > "$FIX/pr-13.md"
run v6.9.3
assert_has "unmodelled: the note is kept" "$FIX/edited.md" "Kept when the rules cannot be read."
printf '%s\n' '{"branches":["master"],"plugins":[["@semantic-release/commit-analyzer",{"preset":"angular"}]]}' > .releaserc.yml

if [ "$fail" -ne 0 ]; then
  printf '\nrelease footer test: %s of %s cases failed\n' "$fail" "$cases" >&2
  exit 1
fi
echo "release footer test: all $cases cases passed"
