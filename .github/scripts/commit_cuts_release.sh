#!/usr/bin/env bash
# Will this commit trigger a release?
#
# The answer is read out of `.releaserc.yml` -- the file semantic-release itself
# reads -- so the check cannot drift from the real rules.
#
# usage (commit message on stdin):
#   git log -1 --format=%B <sha> | .github/scripts/commit_cuts_release.sh
#   exit 0 = triggers a release, 1 = does not, 2 = cannot tell (see below),
#   3 = written in the format this repository used before it moved to angular,
#   4 = a `!` header, which releases nothing here
#
# The rules below were **run against @semantic-release/commit-analyzer@13 with this
# preset**, not read off its default `releaseRules` -- the two disagree, and trusting
# the rule table gives the wrong answer:
#
#   feat:                             -> minor
#   fix: / perf:                      -> patch / patch
#   a line starting with BREAKING CHANGE: (spaces allowed) -> major
#   the message `git revert` writes   -> patch
#   under the jshint preset, [[FEAT]] / [[FIX]]
#
# What is *not* in the list, and surprises people: `!`. `feat!:` does not parse as a
# feat header under this preset at all, so it releases nothing -- not major, not minor.
# The default `releaseRules` say `{breaking: true, release: "major"}`, but what counts
# as breaking is decided by the parser, and this parser does not set it for `!`. A
# subject like that is answered by exit 4 so the mismatch is visible.
#
# This covers the shapes this repository writes; angular also releases on an emoji or
# a `BUGFIX` tag, which is answered "does not trigger" here. The direction is
# deliberate -- the cost is a release that gets no note, not a note demanded for a
# release that never happens -- but it is a real gap, and it is why the rules above are
# measured rather than inferred.
#
# Exit 3 is about a repository that has switched presets, which this one has. A
# `[[FIX]]` subject under angular releases nothing, and it does so silently: no error,
# no run, just a version that never moves -- and nobody looks until weeks later. So it
# is reported as its own outcome rather than folded into "does not trigger", and the
# caller turns it into a failed check.
#
# Exit 2 is deliberate and is meant to fail the check: it means someone changed
# .releaserc.yml in a way this script does not model, and silently applying the old
# rules would be worse than stopping. Two such cases:
#
#   * an unknown preset (a preset this script has no rules for);
#   * a `releaseRules` block -- rules listed per repository, which take precedence over
#     the preset defaults. Wanting one is normal: `{type: chore, scope: deps,
#     release: patch}` is how a repository makes dependency bumps cut a release, which
#     is exactly the case that surprised us when a chain33 bump released nothing.
#     Add the block if you need it, then teach this script the same rules.
set -u

if grep -q '"releaseRules"' .releaserc.yml; then
  echo "commit_cuts_release.sh: .releaserc.yml defines releaseRules, which override the preset defaults -- teach this script those rules before it can answer" >&2
  exit 2
fi

PRESET=$(sed -n 's/.*"preset"[[:space:]]*:[[:space:]]*"\([a-zA-Z-]*\)".*/\1/p' .releaserc.yml | head -1)
MSG=$(cat)
SUBJECT=$(printf '%s\n' "$MSG" | head -1)

case "$PRESET" in
  angular)
    if printf '%s\n' "$SUBJECT" | grep -qE '^(feat|fix|perf)(\([^)]*\))?:'; then
      exit 0
    fi
    # The breaking footer has to start a line, and it may be indented; the phrase
    # appearing inside a sentence is not a footer and releases nothing.
    printf '%s\n' "$MSG" | grep -qE '^[[:space:]]*BREAKING[ -]CHANGE:' && exit 0
    # `{revert: true, release: "patch"}` matches the parser's revert *pattern*, not a
    # `revert:` type: what releases is the message `git revert` writes.
    if printf '%s\n' "$SUBJECT" | grep -qE '^Revert "'; then
      printf '%s\n' "$MSG" | grep -qE 'This reverts commit [0-9a-f]+' && exit 0
    fi
    # A `!` header releases nothing under this preset -- not major, not minor -- because
    # the parser does not accept it, so the type is never read. Someone writing `feat!:`
    # believes they cut a breaking release and gets silence, which is the same failure
    # as the old `[[FIX]]` form. Reported, not tolerated.
    if printf '%s\n' "$SUBJECT" | grep -qE '^[a-zA-Z]+(\([^)]*\))?!:'; then
      echo "commit_cuts_release.sh: '$SUBJECT' releases nothing -- a '!' header does not parse under this preset. Drop the '!' and put a line starting with 'BREAKING CHANGE:' in the body." >&2
      exit 4
    fi
    # The format this repository used until it moved to angular. Reported, not
    # tolerated: this is the shape a commit has when someone writes it out of habit,
    # and it releases nothing.
    if printf '%s\n' "$SUBJECT" | grep -qE '^\[\[(FEAT|FIX)\]\]'; then
      echo "commit_cuts_release.sh: '$SUBJECT' is the old jshint form -- under the angular preset only feat:, fix:, perf: and revert: (optionally with a scope, optionally with '!') trigger a release, so this commit releases nothing" >&2
      exit 3
    fi
    exit 1
    ;;
  jshint)
    printf '%s\n' "$SUBJECT" | grep -qE '^\[\[(FEAT|FIX)\]\]' && exit 0
    exit 1
    ;;
  *)
    echo "commit_cuts_release.sh: .releaserc.yml uses preset '$PRESET', which this script does not know -- teach it that preset's release types" >&2
    exit 2
    ;;
esac
