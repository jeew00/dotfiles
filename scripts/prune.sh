#!/bin/sh
# Remove each worktree whose branch is already in main, and delete the branch.
# Also delete each branch without a worktree that is already in main.
#
# A squash merge makes `git branch --merged` useless, so this compares the content.
# A branch is in main if one of these is true:
#   1. A merge of the branch into main changes nothing. This works just after the merge.
#   2. A commit on main has the same diff as the whole branch. This works also later,
#      when main changed the same lines again.
# These stay: a worktree with uncommitted changes, a branch with no commits,
# the worktree you are in, and each branch that is not in main.
set -eu

main_tree=$(git rev-parse 'main^{tree}')
here=$(git rev-parse --show-toplevel)

patch_id() { git patch-id --stable | cut -d' ' -f1; }

in_main() {
  ref=refs/heads/$1
  merged=$(git merge-tree --write-tree main "$ref" 2>/dev/null | head -n 1)
  [ "$merged" = "$main_tree" ] && return 0
  base=$(git merge-base main "$ref")
  want=$(git diff "$base" "$ref" -- | patch_id)
  for c in $(git rev-list "$base..main"); do
    [ "$(git show "$c" -- | patch_id)" = "$want" ] && return 0
  done
  return 1
}

git worktree list --porcelain | while read -r key value; do
  case $key in
    worktree) path=$value ;;
    branch)
      b=${value#refs/heads/}
      if [ "$b" = main ]; then
        continue
      elif [ "$path" = "$here" ]; then
        echo "keep    $b (you are in this worktree)"
      elif [ "$(git rev-list --count "main..refs/heads/$b")" -eq 0 ]; then
        echo "keep    $b (no commits)"
      elif ! in_main "$b"; then
        echo "keep    $b (not in main)"
      elif git worktree remove "$path" </dev/null; then
        git branch -q -D "$b"
        echo "remove  $b ($path)"
      else
        echo "keep    $b (see the git error above)"
      fi
      ;;
  esac
done

# A branch without a worktree: the same test, but there is no worktree to remove.
git for-each-ref --format='%(if)%(worktreepath)%(then)%(else)%(refname:lstrip=2)%(end)' refs/heads |
while read -r b; do
  if [ -z "$b" ] || [ "$b" = main ]; then
    continue
  elif [ "$(git rev-list --count "main..refs/heads/$b")" -eq 0 ]; then
    echo "keep    $b (no commits)"
  elif ! in_main "$b"; then
    echo "keep    $b (not in main)"
  else
    git branch -q -D "$b"
    echo "remove  $b (no worktree)"
  fi
done
