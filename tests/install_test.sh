#!/bin/sh
# Tests for install.sh. Each test runs it against a new, empty HOME.
set -u

repo=$(cd "$(dirname "$0")/.." && pwd)
rules="$repo/agents/AGENTS.md"
pointer_text='@~/dotfiles/agents/AGENTS.md'
failed=0
out=$(mktemp)

ok()   { echo "ok    $1"; }
fail() { echo "FAIL  $1"; sed 's/^/      /' "$out"; failed=1; }
homes=$(mktemp -d)
new_home() { HOME=$(mktemp -d "$homes/home.XXXXXX"); export HOME; }
install() { sh "$repo/install.sh" "$@" >"$out" 2>&1; }

# 1. A new machine gets the Claude pointer and a copy of the rules for each Codex folder.
new_home
install
if [ "$(cat "$HOME/.claude/CLAUDE.md")" = "$pointer_text" ]; then ok "claude pointer"; else fail "claude pointer"; fi
for d in .codex .codex-account1 .codex-account2; do
  if cmp -s "$rules" "$HOME/$d/AGENTS.md"; then ok "codex copy in $d"; else fail "codex copy in $d"; fi
done
if install --check; then ok "check passes after install"; else fail "check passes after install"; fi

# 2. A second install changes nothing.
install
if grep -q -E '^(install|backup)' "$out"; then fail "second install changes nothing"; else ok "second install changes nothing"; fi

# 3. An existing, different file is kept as a backup, then replaced.
new_home
mkdir -p "$HOME/.codex"
echo "old rules" > "$HOME/.codex/AGENTS.md"
install
if cmp -s "$rules" "$HOME/.codex/AGENTS.md"; then ok "different file replaced"; else fail "different file replaced"; fi
if grep -q -x "old rules" "$HOME"/.codex/AGENTS.md.bak-*; then ok "old file kept as backup"; else fail "old file kept as backup"; fi

# 4. --check names each changed or missing target, and exits 1.
echo "edit in home" >> "$HOME/.codex/AGENTS.md"
rm "$HOME/.claude/CLAUDE.md"
if install --check; then fail "check exits 1 on drift"; else ok "check exits 1 on drift"; fi
if grep -q '^drift  *~/.codex/AGENTS.md' "$out"; then ok "check names drift"; else fail "check names drift"; fi
if grep -q '^missing  *~/.claude/CLAUDE.md' "$out"; then ok "check names missing"; else fail "check names missing"; fi

# 5. --check changes nothing.
if [ ! -e "$HOME/.claude/CLAUDE.md" ]; then ok "check changes nothing"; else fail "check changes nothing"; fi

# 6. An unknown argument is an error.
if install --bad; then fail "unknown argument fails"; else ok "unknown argument fails"; fi

# 7. Git gets a pointer to the shared config, and git reads the shared keys through it.
new_home
install
if [ "$(cat "$HOME/.config/git/config")" = '[include] path = ~/dotfiles/git/config' ]; then ok "git pointer"; else fail "git pointer"; fi
mkdir -p "$HOME/dotfiles/git" && cp "$repo/git/config" "$repo/git/ignore" "$HOME/dotfiles/git/"
if [ "$(cd "$HOME" && GIT_CONFIG_NOSYSTEM=1 git config --get pull.ff)" = only ]; then ok "git reads shared key"; else fail "git reads shared key"; fi

# 7b. Each repo ignores OS junk through the global ignore file (core.excludesFile = ~/dotfiles/git/ignore).
git init -q "$HOME/proj"
if (cd "$HOME/proj" && GIT_CONFIG_NOSYSTEM=1 git check-ignore -q .DS_Store); then ok "global ignore file works"; else fail "global ignore file works"; fi
if (cd "$HOME/proj" && GIT_CONFIG_NOSYSTEM=1 git check-ignore -q main.py); then fail "normal file is not ignored"; else ok "normal file is not ignored"; fi

# 8. A key in ~/.gitconfig that is also in git/config overrides the shared value: --check reports it.
printf '[pull]\n\tff = false\n[windows]\n\tappendAtomically = false\n' > "$HOME/.gitconfig"
if install --check; then fail "check exits 1 on shadowed key"; else ok "check exits 1 on shadowed key"; fi
if grep -q '^shadow  *~/.gitconfig pull.ff' "$out"; then ok "check names shadowed key"; else fail "check names shadowed key"; fi
if grep -q 'windows.appendatomically' "$out"; then fail "machine key is not reported"; else ok "machine key is not reported"; fi

rm -rf "$out" "$homes"
exit $failed
