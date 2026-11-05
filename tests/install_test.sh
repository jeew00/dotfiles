#!/bin/sh
# Tests for install.sh. Each test runs it against a new, empty HOME.
set -u

# A git hook exports GIT_DIR. With it, `git init <dir>` changes that repo, not <dir>:
# from a worktree hook, it set core.bare=true in the dotfiles repo. Unset the repo vars.
# shellcheck disable=SC2046
unset $(git rev-parse --local-env-vars)

# Each test gets the same OS on each machine. A test for another OS sets it again.
DOTFILES_OS=linux; export DOTFILES_OS

repo=$(cd "$(dirname "$0")/.." && pwd)
rules="$repo/agents/AGENTS.md"
pointer_text='@~/dotfiles/agents/AGENTS.md'
failed=0
out=$(mktemp)

ok()   { echo "ok    $1"; }
fail() { echo "FAIL  $1"; sed 's/^/      /' "$out"; failed=1; }
homes=$(mktemp -d)
new_home() { HOME=$(mktemp -d "$homes/home.XXXXXX"); export HOME; }
# No terminal on stdin: install.sh must not ask for a tmux color in a test.
install() { sh "$repo/install.sh" "$@" </dev/null >"$out" 2>&1; }

# 1. A new machine gets the Claude pointer and a copy of the rules for each Codex folder.
#    A person in a terminal chooses a tmux color. --theme does the same without the prompt.
new_home
install --theme blue
if [ "$(cat "$HOME/.claude/CLAUDE.md")" = "$pointer_text" ]; then ok "claude pointer"; else fail "claude pointer"; fi
for d in .codex .codex-account1 .codex-account2; do
  if cmp -s "$rules" "$HOME/$d/AGENTS.md"; then ok "codex copy in $d"; else fail "codex copy in $d"; fi
done
if cmp -s "$repo/claude/settings.json" "$HOME/.claude/settings.json"; then ok "claude settings copy"; else fail "claude settings copy"; fi
if cmp -s "$repo/mise/global.toml" "$HOME/.config/mise/config.toml"; then ok "mise global config copy"; else fail "mise global config copy"; fi
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
mkdir -p "$HOME/dotfiles/git" && cp "$repo"/git/* "$HOME/dotfiles/git/"
if [ "$(cd "$HOME" && GIT_CONFIG_NOSYSTEM=1 git config --get pull.ff)" = only ]; then ok "git reads shared key"; else fail "git reads shared key"; fi

# 7b. Each repo ignores OS junk through the global ignore file (core.excludesFile = ~/dotfiles/git/ignore).
git init -q "$HOME/proj"
if (cd "$HOME/proj" && GIT_CONFIG_NOSYSTEM=1 git check-ignore -q .DS_Store); then ok "global ignore file works"; else fail "global ignore file works"; fi
if (cd "$HOME/proj" && GIT_CONFIG_NOSYSTEM=1 git check-ignore -q main.py); then fail "normal file is not ignored"; else ok "normal file is not ignored"; fi

# 7c. The remote URL selects the commit identity. The name is the same on each forge.
github='jeew <43456094+jeew00@users.noreply.github.com>'
gitlab='jeew <8702903-jeew@users.noreply.gitlab.com>'
for case in "none|$github" \
            "https://github.com/jeew00/x.git|$github" \
            "git@github.com:jeew00/x.git|$github" \
            "https://gitlab.com/jeew/x.git|$gitlab" \
            "ssh://git@gitlab.com/jeew/x.git|$gitlab" \
            "git@gitlab.com:jeew/group/x.git|$gitlab"; do
  url=${case%%|*} want=${case#*|}
  r=$(mktemp -d "$homes/repo.XXXXXX")
  git init -q "$r"
  [ "$url" = none ] || git -C "$r" remote add origin "$url"
  got="$(cd "$r" && GIT_CONFIG_NOSYSTEM=1 git config user.name) <$(cd "$r" && GIT_CONFIG_NOSYSTEM=1 git config user.email)>"
  if [ "$got" = "$want" ]; then ok "identity for $url"; else echo "      got: $got" > "$out"; fail "identity for $url"; fi
done

# 8. A key in ~/.gitconfig that is also in git/config overrides the shared value: --check reports it.
printf '[pull]\n\tff = false\n[windows]\n\tappendAtomically = false\n' > "$HOME/.gitconfig"
if install --check; then fail "check exits 1 on shadowed key"; else ok "check exits 1 on shadowed key"; fi
if grep -q '^shadow  *~/.gitconfig pull.ff' "$out"; then ok "check names shadowed key"; else fail "check names shadowed key"; fi
if grep -q 'windows.appendatomically' "$out"; then fail "machine key is not reported"; else ok "machine key is not reported"; fi

# 9. On Linux and macOS, ~/.tmux.conf loads the shared tmux config.
for DOTFILES_OS in linux macos; do
  new_home
  install
  if [ "$(cat "$HOME/.tmux.conf")" = 'source-file ~/dotfiles/tmux/tmux.conf' ]; then ok "tmux pointer on $DOTFILES_OS"; else fail "tmux pointer on $DOTFILES_OS"; fi
done

# 10. tmux does not run on native Windows: no tmux files. The other lists still install.
DOTFILES_OS=windows
new_home
install
if [ ! -e "$HOME/.tmux.conf" ]; then ok "no tmux on windows"; else fail "no tmux on windows"; fi
if [ -f "$HOME/.claude/CLAUDE.md" ]; then ok "other lists install on windows"; else fail "other lists install on windows"; fi
if install --check && ! grep -q "tmux.conf" "$out"; then ok "check ignores tmux on windows"; else fail "check ignores tmux on windows"; fi
install --theme teal
if [ ! -e "$HOME/.config/tmux/local.conf" ]; then ok "no tmux theme on windows"; else fail "no tmux theme on windows"; fi
DOTFILES_OS=linux

# 10b. Without a terminal, install.sh does not ask for a color and writes no choice. --check names it.
new_home
install
if [ ! -e "$HOME/.config/tmux/local.conf" ] && grep -q '^skip  *~/.config/tmux/local.conf' "$out"; then ok "no prompt without a terminal"; else fail "no prompt without a terminal"; fi
if install --check; then fail "check exits 1 without a tmux color"; else ok "check exits 1 without a tmux color"; fi
if grep -q '^missing  *~/.config/tmux/local.conf' "$out"; then ok "check names the missing tmux color"; else fail "check names the missing tmux color"; fi

# 10c. --theme sets the color of this machine, and a second --theme changes it.
install --theme teal
if grep -q -x 'source-file ~/dotfiles/tmux/themes/teal.conf' "$HOME/.config/tmux/local.conf"; then ok "theme teal"; else fail "theme teal"; fi
if install --check; then ok "check passes with a tmux color"; else fail "check passes with a tmux color"; fi
install --theme gray
if grep -q -x 'source-file ~/dotfiles/tmux/themes/gray.conf' "$HOME/.config/tmux/local.conf" &&
   ! grep -q teal "$HOME/.config/tmux/local.conf"; then ok "theme changes to gray"; else fail "theme changes to gray"; fi
install
if grep -q gray "$HOME/.config/tmux/local.conf"; then ok "install keeps the theme"; else fail "install keeps the theme"; fi

# 10d. An unknown theme is an error, and install.sh changes nothing.
new_home
for bad in red ../tmux/tmux "" "blue gray"; do
  if install --theme "$bad"; then fail "theme '$bad' fails"; else ok "theme '$bad' fails"; fi
done
if [ -z "$(ls -A "$HOME")" ]; then ok "unknown theme changes nothing"; else fail "unknown theme changes nothing"; fi

# 10e. There are 7 themes, and each sets the same three style options.
n=0
for f in "$repo"/tmux/themes/*.conf; do
  n=$((n + 1))
  keys=$(sed -n 's/^set[w]* -g \([a-z-]*\) .*/\1/p' "$f" | sort | tr '\n' ' ')
  if [ "$keys" = "status-style window-status-current-style window-status-style " ]; then ok "theme ${f##*/}"; else echo "      keys: $keys" > "$out"; fail "theme ${f##*/}"; fi
done
if [ $n -eq 7 ]; then ok "7 themes"; else echo "      found: $n" > "$out"; fail "7 themes"; fi

# 11. tmux loads the shared config without an error. This runs only where tmux is installed.
if command -v tmux >/dev/null; then
  new_home
  install
  mkdir -p "$HOME/dotfiles" && cp -R "$repo/tmux" "$HOME/dotfiles/"
  sock="$HOME/tmux.sock"
  if tmux -S "$sock" -f /dev/null new-session -d \; source-file "$HOME/.tmux.conf" >"$out" 2>&1 && [ ! -s "$out" ]; then
    ok "tmux loads the config"
  else
    fail "tmux loads the config"
  fi
  tmux -S "$sock" show -gv status-style >"$out" 2>&1
  if grep -q c98ba5 "$out"; then ok "tmux status bar is pink"; else fail "tmux status bar is pink"; fi
  install --theme teal
  tmux -S "$sock" source-file "$HOME/.tmux.conf" \; show -gv status-style >"$out" 2>&1
  if grep -q -x '.*8bc5c9.*' "$out" && [ "$(wc -l < "$out")" -eq 1 ]; then ok "tmux status bar is teal"; else fail "tmux status bar is teal"; fi
  tmux -S "$sock" kill-server 2>/dev/null
else
  echo "skip  tmux loads the config (tmux is not installed)"
fi

# 12. mise reads the global pins: jq on each OS, tmux not on Windows.
#     mise has no OS override, so this tests the OS of this machine. It runs only where mise is installed.
#     The repo itself uses only mise.toml: mise reads a file like mise/config.toml as config of the repo.
if command -v mise >/dev/null; then
  (cd "$repo" && mise ls --local --no-header) >"$out" 2>&1
  if grep -q '^gitleaks ' "$out" && ! grep -q '^jq ' "$out"; then ok "repo does not use the global pins"; else fail "repo does not use the global pins"; fi
  # mise also loads ~/.config/mise/config.toml, and then --global lists nothing. An empty MISE_CONFIG_DIR stops that.
  mkdir -p "$homes/mise-config"
  (cd "$homes" && MISE_CONFIG_DIR="$homes/mise-config" MISE_GLOBAL_CONFIG_FILE="$repo/mise/global.toml" mise ls --global --no-header) >"$out" 2>&1
  if grep -q '^jq  *1\.8\.2 ' "$out"; then ok "mise reads the jq pin"; else fail "mise reads the jq pin"; fi
  case $(uname -s) in
    MINGW* | MSYS* | CYGWIN*) if grep -q '^tmux ' "$out"; then fail "mise skips tmux on windows"; else ok "mise skips tmux on windows"; fi ;;
    *)                        if grep -q '^tmux  *3\.7c ' "$out"; then ok "mise reads the tmux pin"; else fail "mise reads the tmux pin"; fi ;;
  esac
else
  echo "skip  mise global pins (mise is not installed)"
fi

rm -rf "$out" "$homes"
exit $failed
