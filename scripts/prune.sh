#!/bin/sh
# Remove each worktree and local branch whose PR is merged on the server.
#
# The server does a squash merge, so git cannot see that the branch is merged. The PR can:
# a branch is merged if its tip is the last commit of a merged PR. So a branch that got
# new commits after the merge stays.
# These also stay: a worktree with uncommitted changes, and the worktree you are in.
# If gh fails (no network, no login), the script stops and deletes nothing.
set -eu

here=$(git rev-parse --show-toplevel)
merged=$(gh pr list --state merged --limit 100 --json headRefOid --jq '.[].headRefOid')

git for-each-ref --format='%(refname:lstrip=2) %(objectname) %(worktreepath)' refs/heads |
while read -r b tip path; do
  if [ "$b" = main ]; then
    continue
  elif ! printf '%s\n' "$merged" | grep -qx "$tip"; then
    echo "keep    $b (no merged PR)"
  elif [ -z "$path" ]; then
    git branch -q -D "$b"
    echo "remove  $b"
  elif [ "$path" = "$here" ]; then
    echo "keep    $b (you are in this worktree)"
  elif git worktree remove "$path" </dev/null; then
    git branch -q -D "$b"
    echo "remove  $b ($path)"
  else
    echo "keep    $b (see the git error above)"
  fi
done
