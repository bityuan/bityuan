#!/usr/bin/env bash
# Put the operator-facing part of a release page in place: the "Upgrade Notes" the
# authors declared, and "System Requirements".
#
# Called by release.yml from publish-release, right after the release is created --
# before any asset is uploaded. Deliberately *not* called from the job that uploads the
# Windows/macOS packages: a failed upload would otherwise leave the page with nothing
# about what an operator has to do.
#
#   usage: REPO=owner/name GH_TOKEN=... bash .github/scripts/add_release_footer.sh v6.9.2
#
# REPO is required rather than defaulted: a default pointing at the upstream repository
# would turn a run meant for a rehearsal repository into an edit of a real release page.
#
# Safe to re-run: a release whose body already carries "System Requirements" is left
# alone, so repairing an old release cannot double-append.
set -eu

V="${1:?usage: add_release_footer.sh <tag>}"
REPO="${REPO:?REPO is required, e.g. REPO=bityuan/bityuan}"
HERE=$(dirname "$0")

BODY=$(gh release view "$V" --repo "$REPO" --json body -q .body)
if printf '%s' "$BODY" | grep -q "System Requirements"; then
  echo "footer already present on $V, nothing to do"
  exit 0
fi

# Upgrade notes are the text under the `Release note` heading of each pull request merged
# in this release: one note per change, written where the narrative already is (rules:
# .github/RELEASE.md). A commit that never went through a pull request -- pushed
# straight to master -- falls back to a `Release-Note:` line in its own body.
#
# Which release counts as the previous one is decided in prev_release.jq -- see there.
# `gh api --jq` takes a jq program and nothing else: passing `--arg v "$V"` through it
# made this call fail with "accepts 1 arg(s), received 4" on every run, and the `|| true`
# that was meant to keep a missing release from failing the job swallowed it -- so `prev`
# was always empty and the upgrade notes were always empty with it. The jq program takes
# its argument on the jq command line instead, where the flag exists.
releases=""
if ! releases=$(gh api "repos/$REPO/releases?per_page=100" --paginate --jq '.[]' 2>/dev/null); then
  echo "::warning::could not list the releases of $REPO -- the previous release is unknown" >&2
fi
prev=$(printf '%s' "$releases" | jq -rs --arg v "$V" -f "$HERE/prev_release.jq" 2>/dev/null || true)
notes=""
failed=0
if [ -z "$prev" ]; then
  echo "::warning::no release older than $V was found, so the upgrade notes will be empty" >&2
else
  seen=" "
  for sha in $(gh api "repos/$REPO/compare/$prev...$V" --jq '.commits[].sha' 2>/dev/null || true); do
    # A lookup that fails is counted, not swallowed: the notes end up in the release
    # body, and "the API said no" and "the API refused" look identical from here.
    if ! msg=$(gh api "repos/$REPO/commits/$sha" --jq .commit.message 2>/dev/null); then
      failed=$((failed + 1))
      continue
    fi
    # Only a commit that cuts a release contributes a note. A note answers "what does
    # this release mean for an operator", so a pull request that changes nothing an
    # operator would see has nothing to answer -- and asking it anyway is what put
    # "NONE -- CI only, no operator action." on a release page: the sentence was written
    # to satisfy a form, and the footer read it as a note. Exit 3 and 4 are forms this
    # preset cannot read as a release either; anything else means the classifier could
    # not model the rules at all, which is counted and the note kept rather than dropped
    # on a guess.
    rc=0
    printf '%s' "$msg" | bash "$HERE/commit_cuts_release.sh" >/dev/null 2>&1 || rc=$?
    case "$rc" in
      0) ;;
      1 | 3 | 4) continue ;;
      *) failed=$((failed + 1)) ;;
    esac
    if ! pr=$(gh api "repos/$REPO/commits/$sha/pulls" --jq '.[0].number' 2>/dev/null); then
      failed=$((failed + 1))
      continue
    fi
    note=""
    if [ -n "$pr" ] && [ "$pr" != "null" ]; then
      # one note per pull request, however many commits it contributed
      case "$seen" in *" $pr "*) continue ;; esac
      seen="$seen$pr "
      if ! body=$(gh pr view "$pr" --repo "$REPO" --json body -q .body 2>/dev/null); then
        failed=$((failed + 1))
        continue
      fi
      note=$(printf '%s' "$body" | bash "$HERE/extract_release_note.sh" || true)
    else
      note=$(printf '%s' "$msg" | sed -n 's/^Release-Note:[[:space:]]*//p' || true)
    fi
    # a note is one bullet, so a wrapped block collapses to a single line
    note=$(printf '%s' "$note" | tr '\n' ' ' | sed 's/  */ /g; s/^ //; s/ $//')
    # "NONE" says there is nothing for an operator, however the author spells it out
    # after the word -- so the opening word is what decides, and "NONE -- CI only" reads
    # the same as a bare "NONE".
    first=$(printf '%s' "$note" | tr '[:upper:]' '[:lower:]' | awk '{print $1}' | sed 's/[^a-z]*$//')
    case "$first" in
      "" | none) continue ;;
    esac
    notes="$notes$note"$'\n'
  done
fi

upgrade=""
if [ -n "$notes" ]; then
  upgrade="\n\n### Upgrade Notes\n\n"
  while IFS= read -r note; do
    if [ -n "$note" ]; then
      upgrade="$upgrade* $note\n"
    fi
  done <<< "$notes"
fi

# The macOS line is the `minos` of the darwin binaries -- currently 14.0, from building
# on the macos-14 runner (`otool -l bityuan | grep -A4 LC_BUILD_VERSION`). Moving to a
# newer runner moves this floor.
FOOTER="$upgrade\n\n---\n\n### System Requirements\n\n**Linux** (glibc >= 2.17): Ubuntu 18.04+, Debian 10+, CentOS 7+, RHEL 7+, Rocky 8+, Alma 8+\n\n**macOS**: 14.0+\n\n**Windows**: Windows 10+, Windows Server 2016+"

# An empty Upgrade Notes section is a release page that promises nothing, so it is
# announced rather than silently written. It is not fatal: a release really can have
# nothing an operator has to do.
if [ "$failed" -gt 0 ]; then
  echo "::warning::$failed lookups failed while collecting the upgrade notes for $V -- they may be incomplete" >&2
fi
if [ -z "$notes" ]; then
  echo "::warning::no upgrade notes collected for $V (previous release: ${prev:-none}) -- if this release has operator-visible changes, the pull requests that carried them declared no note" >&2
fi

printf "%b" "$BODY$FOOTER" | gh release edit "$V" --repo "$REPO" -F -
echo "footer added to $V (upgrade notes: $(printf '%s' "$notes" | grep -c . || true), failed lookups: $failed)"
