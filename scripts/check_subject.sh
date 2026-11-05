#!/bin/sh
# Check a commit subject: `area: what the change does`.
# The server squash-merges, so the PR title becomes the subject on main. CI runs this on
# the PR title. Usage: sh scripts/check_subject.sh "<subject>". Quiet when it passes.
#
# - The area is the package or directory, in lowercase: `git`, `scripts`, `claude/hooks`.
# - The rest says what the change does: "add X", not "Added X" or "Add X".
#   A name can start with a capital letter: "make GhosttyStyle smaller", "INVALID=0 keys".
# - No period at the end. 72 characters at most, so that `git log --oneline` stays readable.
# - `Revert "..."` from the GitHub revert button is accepted.
set -u

s=${1-}
bad() { printf 'subject: %s\n  "%s"\n  want: area: what the change does\n' "$1" "$s" >&2; exit 1; }

case $s in 'Revert "'*) exit 0 ;; esac

[ "${#s}" -le 72 ] || bad "longer than 72 characters (${#s})"
printf '%s\n' "$s" | grep -Eq '^[a-z0-9][a-z0-9._/-]*: ' || bad 'no lowercase area before ": "'
rest=${s#*: }
[ -n "$rest" ] || bad 'nothing after the area'
case $rest in
  ' '*|*' ') bad 'extra space' ;;
  *.) bad 'period at the end' ;;
esac
# A capital followed only by lowercase letters is a normal word: "Add", "Fix", "A".
if printf '%s\n' "$rest" | grep -Eq '^[A-Z][a-z]*( |$)'; then bad 'first word is capitalized'; fi
exit 0
