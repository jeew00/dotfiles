#!/bin/sh
# Install the config from this repo into $HOME, or show the drift.
#
#   install.sh           apply each */files.list
#   install.sh --check   show each target that differs; exit 1 if one differs
#   install.sh --theme <name>   apply, and set the tmux color of this machine (tmux/themes/)
#
# A files.list line is:  <mode> <target> <value>
#   pointer  ~/path  text    the target contains only <text>
#   copy     ~/path  file    the target is a copy of <file> (relative to the list)
#   only     <os>...         skip the next lines on other OSes (windows, macos, linux)
#
# DOTFILES_OS sets the OS for the tests. If it is not set, uname gives the OS.
#
# install.sh owns each target. Edit the source in this repo, not the target.
# Before it replaces a different file, it keeps that file as <target>.bak-<time>.
set -eu

repo=$(cd "$(dirname "$0")" && pwd)

check=false
theme=
case "${1:-}" in
  "")      ;;
  --check) check=true ;;
  --theme) theme=${2:-} ;;
  *)       echo "usage: install.sh [--check | --theme <name>]" >&2; exit 2 ;;
esac

themes=
for f in "$repo"/tmux/themes/*.conf; do
  f=${f##*/}
  themes="$themes ${f%.conf}"
done
is_theme() {
  case $1 in "" | */* | .*) return 1 ;; esac
  [ -f "$repo/tmux/themes/$1.conf" ]
}
if [ "${1:-}" = --theme ] && ! is_theme "$theme"; then
  echo "error: unknown theme '$theme'. Themes:$themes" >&2
  exit 2
fi

if [ "$repo" != "$HOME/dotfiles" ]; then
  echo "warning: the repo is at $repo, but the pointers refer to ~/dotfiles" >&2
fi

case ${DOTFILES_OS:-$(uname -s)} in
  windows | MINGW* | MSYS* | CYGWIN*) os=windows ;;
  macos | Darwin)                     os=macos ;;
  *)                                  os=linux ;;
esac

want=$(mktemp)
trap 'rm -f "$want"' EXIT
drift=0

# $1 mode, $2 target as written in the list, $3 value, $4 folder of the list
apply() {
  # The list contains a literal "~/". Replace it with $HOME.
  # shellcheck disable=SC2088
  case $2 in
    "~/"*) target="$HOME/${2#"~/"}" ;;
    *)     target=$2 ;;
  esac
  case $1 in
    pointer) printf '%s\n' "$3" > "$want" ;;
    copy)    cp "$4/$3" "$want" ;;
    *)       echo "error: unknown mode '$1' in $4/files.list" >&2; exit 2 ;;
  esac

  if [ -f "$target" ] && cmp -s "$want" "$target"; then
    if $check; then echo "ok       $2"; fi
    return
  fi

  if $check; then
    drift=1
    if [ -f "$target" ]; then
      echo "drift    $2"
      diff -u "$target" "$want" | tail -n +3 | sed 's/^/         /' || true
    else
      echo "missing  $2"
    fi
    return
  fi

  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ]; then
    backup="$target.bak-$(date +%Y%m%d-%H%M%S)"
    mv "$target" "$backup"
    echo "backup   $2 -> ${backup##*/}"
  fi
  cp "$want" "$target"
  echo "install  $2"
}

for list in "$repo"/*/files.list; do
  [ -f "$list" ] || continue
  # The loop only reads the list. dirname does not write it.
  # shellcheck disable=SC2094
  while read -r mode target value; do
    case $mode in "" | "#"*) continue ;; esac
    if [ "$mode" = only ]; then
      case " $target $value " in *" $os "*) continue ;; *) break ;; esac
    fi
    apply "$mode" "$target" "$value" "$(dirname "$list")"
  done < "$list"
done

# Each machine has its own tmux status bar color, so that you see which host you are on.
# The choice is machine state in local.conf. install.sh asks for it once, in a terminal.
ask_theme() {
  echo "tmux status bar color for this machine:"
  n=0
  for t in $themes; do n=$((n + 1)); echo "  $n) $t"; done
  while :; do
    printf 'Number or name [pink]: '
    read -r answer || answer=
    [ -n "$answer" ] || answer=pink
    n=0
    for t in $themes; do n=$((n + 1)); if [ "$answer" = "$n" ]; then answer=$t; fi; done
    if is_theme "$answer"; then theme=$answer; return; fi
    echo "unknown color: $answer"
  done
}
local_conf="$HOME/.config/tmux/local.conf"
if [ "$os" = windows ]; then
  if [ -n "$theme" ]; then echo "skip     tmux theme (tmux does not run on native Windows)"; fi
elif $check; then
  if [ ! -f "$local_conf" ]; then
    drift=1
    echo "missing  ~/.config/tmux/local.conf (to choose a color, run: sh install.sh)"
  fi
else
  if [ -z "$theme" ] && [ ! -f "$local_conf" ]; then
    if [ -t 0 ]; then
      ask_theme
    else
      echo "skip     ~/.config/tmux/local.conf (no terminal: run sh install.sh to choose a color)"
    fi
  fi
  if [ -n "$theme" ]; then
    mkdir -p "$(dirname "$local_conf")"
    printf '%s\n' \
      "# The tmux status bar color of this machine. ~/dotfiles/install.sh wrote it." \
      "# Change it: sh ~/dotfiles/install.sh --theme <name>" \
      "source-file ~/dotfiles/tmux/themes/$theme.conf" > "$local_conf"
    echo "install  ~/.config/tmux/local.conf ($theme)"
  fi
fi

# Git reads ~/.gitconfig after ~/.config/git/config, so a key in ~/.gitconfig
# overrides the shared value. ~/.gitconfig must hold only machine keys.
if [ -f "$HOME/.gitconfig" ]; then
  shared=$(git config -f "$repo/git/config" --name-only --list)
  for key in $(git config -f "$HOME/.gitconfig" --name-only --list | sort -u); do
    if printf '%s\n' "$shared" | grep -q -x -F "$key"; then
      echo "shadow   ~/.gitconfig $key (remove it: git/config has it)"
      if $check; then drift=1; fi
    fi
  done
fi

# Git does not clone hooks. This makes git use the hooks in this repo.
if [ "$(git -C "$repo" config core.hooksPath || true)" != hooks ]; then
  if $check; then
    drift=1
    echo "missing  git hooks (core.hooksPath = hooks)"
  else
    git -C "$repo" config core.hooksPath hooks
    echo "install  git hooks (core.hooksPath = hooks)"
  fi
fi

exit $drift
