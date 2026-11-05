#!/bin/sh
# Tests for scripts/prune.sh. They use only a scratch repo.
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

r="$HOME/repo"
git init -q -b main "$r"
cd "$r" || exit 1
printf 'a\nb\nc\n' > f && git add f && git commit -q -m base

# $1 branch, $2 file, $3 text: a worktree with one commit.
work() { git worktree add -q "$HOME/$1" -b "$1" && echo "$3" > "$HOME/$1/$2" && git -C "$HOME/$1" add . && git -C "$HOME/$1" commit -q -m "$1"; }
squash() { git merge -q --squash "$1" >/dev/null && git commit -q -m "squash $1"; }

work merged m.txt merged; squash merged
work later f.txt one; squash later; echo two > f.txt && git commit -q -am "main changes the same line"
work open o.txt open
git worktree add -q "$HOME/fresh" -b fresh
work dirty d.txt dirty; squash dirty; echo edit >> "$HOME/dirty/d.txt"
work current c.txt current; squash current

(cd "$HOME/current" && sh "$prune") > "$HOME/out" 2>&1

gone() { [ ! -d "$HOME/$1" ] && ! git show-ref -q --verify "refs/heads/$1"; }
kept() { [ -d "$HOME/$1" ] && git show-ref -q --verify "refs/heads/$1"; }
if gone merged;  then ok "removes a squash-merged branch"; else fail "removes a squash-merged branch"; fi
if gone later;   then ok "removes a merged branch after main changed the same lines"; else fail "removes a merged branch after main changed the same lines"; fi
if kept open;    then ok "keeps a branch that is not in main"; else fail "keeps a branch that is not in main"; fi
if kept fresh;   then ok "keeps a branch with no commits"; else fail "keeps a branch with no commits"; fi
if kept dirty;   then ok "keeps a worktree with uncommitted changes"; else fail "keeps a worktree with uncommitted changes"; fi
if kept current; then ok "keeps the current worktree"; else fail "keeps the current worktree"; fi

cd / && rm -rf "$HOME"
exit $failed
