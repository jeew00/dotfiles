#!/bin/sh
# Tests for scripts/prune.sh. They use only a scratch repo and a fake gh.
set -u

# A git hook exports GIT_DIR: then git would change the dotfiles repo, not the scratch repo.
# shellcheck disable=SC2046
unset $(git rev-parse --local-env-vars) XDG_CONFIG_HOME
# No git config of this machine.
HOME=$(mktemp -d); GIT_CONFIG_NOSYSTEM=1; export HOME GIT_CONFIG_NOSYSTEM
git config --global user.name test
git config --global user.email test@example.com

prune="$(cd "$(dirname "$0")/.." && pwd)/scripts/prune.sh"
failed=0
ok()   { echo "ok    $1"; }
fail() { echo "FAIL  $1"; sed 's/^/      /' "$HOME/out"; failed=1; }

# The fake gh prints the head commits of the merged PRs from $HOME/prs.
# If $HOME/prs does not exist, it fails, as gh does without a network.
mkdir "$HOME/bin"
printf '#!/bin/sh\nexec cat "$HOME/prs"\n' > "$HOME/bin/gh"
chmod +x "$HOME/bin/gh"
PATH="$HOME/bin:$PATH"

r="$HOME/repo"
git init -q -b main "$r"
cd "$r" || exit 1
echo a > f && git add f && git commit -q -m base

# $1 branch: a worktree with one commit.
work() { git worktree add -q "$HOME/$1" -b "$1" && echo "$1" > "$HOME/$1/$1.txt" && git -C "$HOME/$1" add . && git -C "$HOME/$1" commit -q -m "$1"; }
# $1 branch: the server merged a PR with the tip of this branch.
merge() { git rev-parse "refs/heads/$1" >> "$HOME/prs"; }

work merged; merge merged
work later; merge later; echo more >> "$HOME/later/later.txt" && git -C "$HOME/later" commit -q -am "after the merge"
work open
work dirty; merge dirty; echo edit >> "$HOME/dirty/dirty.txt"
work current; merge current
work bare-merged; merge bare-merged; git worktree remove "$HOME/bare-merged"
work bare-open; git worktree remove "$HOME/bare-open"

gone() { [ ! -d "$HOME/$1" ] && ! git show-ref -q --verify "refs/heads/$1"; }
kept() { [ -d "$HOME/$1" ] && git show-ref -q --verify "refs/heads/$1"; }
has()  { git show-ref -q --verify "refs/heads/$1"; }

# Without the PR list, nothing is safe to delete.
mv "$HOME/prs" "$HOME/prs.later"
if ! (cd "$HOME/current" && sh "$prune") > "$HOME/out" 2>&1 && kept merged && has bare-merged
then ok "fails and deletes nothing when gh fails"; else fail "fails and deletes nothing when gh fails"; fi
mv "$HOME/prs.later" "$HOME/prs"

(cd "$HOME/current" && sh "$prune") > "$HOME/out" 2>&1

if gone merged;       then ok "removes a branch whose PR is merged"; else fail "removes a branch whose PR is merged"; fi
if ! has bare-merged; then ok "deletes a merged branch without a worktree"; else fail "deletes a merged branch without a worktree"; fi
if kept later;        then ok "keeps a branch with new commits after the merge"; else fail "keeps a branch with new commits after the merge"; fi
if kept open;         then ok "keeps a branch without a merged PR"; else fail "keeps a branch without a merged PR"; fi
if has bare-open;     then ok "keeps a branch without a worktree and without a merged PR"; else fail "keeps a branch without a worktree and without a merged PR"; fi
if kept dirty;        then ok "keeps a worktree with uncommitted changes"; else fail "keeps a worktree with uncommitted changes"; fi
if kept current;      then ok "keeps the current worktree"; else fail "keeps the current worktree"; fi

cd / && rm -rf "$HOME"
exit $failed
