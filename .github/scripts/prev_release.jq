# Which release a tag was released *after*: the newest release, by creation time, that
# is older than $v. Feeds `jq -rs --arg v <tag>`, so the input is the releases array.
#
# The previous release is the one older than $v, not merely the first entry that is not
# $v. The releases list comes back newest first, and on the manual path $v is an older
# tag being repackaged -- so "first that is not $v" would pick a *newer* release and
# compare it backwards, which yields no commits and therefore no upgrade notes.
#
# Compared by creation time rather than by version, because "older" has to hold for
# tags this cannot parse.
(map(select(.tag_name == $v)) | first | .created_at) as $mine
| map(select(.tag_name != $v))
| map(select($mine == null or .created_at < $mine))
| sort_by(.created_at) | last | .tag_name // empty
