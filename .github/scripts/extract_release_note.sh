#!/usr/bin/env bash
# Print the release note a pull request declares. Empty output means no note was written.
#
#   gh pr view 213 --repo bityuan/bityuan --json body -q .body | .github/scripts/extract_release_note.sh
#
# The convention is a heading, and the text under it up to the next heading of the same
# or a higher level:
#
#   ## Release note
#
#   Nodes older than 6.9.0 are dropped at the p2p layer and blacklisted for 24 hours,
#   so upgrade every node together.
#
# A heading was chosen over a fenced ```release-note block (which is what Kubernetes
# uses) because a pull request body is often written without the repository's template,
# and a heading needs no convention to be remembered. "Release notes"/"release-note"
# are accepted too; matching is case-insensitive.
#
# HTML comments are stripped, so the guidance the pull request template carries reads as
# "no note" rather than as a note about writing one. 'NONE' is printed as-is; callers
# decide what an empty result means.
set -u

BODY=$(cat)

# The note is the body of the first `Release note` heading, up to the next heading that
# closes it (same level or higher). Body lines only -- the heading itself is not printed.
extract_by_heading() {
  printf '%s\n' "$BODY" | awk '
    {
      line = $0
      heading = match(line, /^#+[ \t]*/)
      if (heading > 0) {
        level = RLENGTH - 1
        text = tolower(substr(line, RLENGTH + 1))
        sub(/[ \t\r]+$/, "", text)
        if (!inside && text ~ /^release[ _-]?notes?$/) { inside = 1; level_of_note = level; next }
        if (inside && level <= level_of_note) { exit }
      }
      if (inside) { print }
    }
  '
}

# Drop HTML comments (they may span lines), then trim and drop blank lines.
strip_comments() {
  awk '
    {
      line = $0
      out = ""
      while (length(line) > 0) {
        if (incomment) {
          p = index(line, "-->")
          if (p == 0) { line = "" } else { line = substr(line, p + 3); incomment = 0 }
        } else {
          p = index(line, "<!--")
          if (p == 0) { out = out line; line = "" } else { out = out substr(line, 1, p - 1); line = substr(line, p + 4); incomment = 1 }
        }
      }
      print out
    }
  ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sed '/^$/d'
}

# The attribution the PR tooling appends after the note is not part of what an operator
# has to do, so it never reaches the release page.
strip_attribution() {
  awk 'tolower($0) !~ /generated with \[?claude code\]?/ && $0 !~ /claude\.com\/claude-code/'
}

extract_by_heading | strip_comments | strip_attribution
