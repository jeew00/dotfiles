#!/bin/sh
# Install the config from this repo into $HOME, or show the drift.
#
#   install.sh           apply each */files.list
#   install.sh --check   show each target that differs; exit 1 if one differs
#
# A files.list line is:  <mode> <target> <value>
#   pointer  ~/path  text    the target contains only <text>
#   copy     ~/path  file    the target is a copy of <file> (relative to the list)
#
# install.sh owns each target. Edit the source in this repo, not the target.
# Before it replaces a different file, it keeps that file as <target>.bak-<time>.
set -eu

repo=$(cd "$(dirname "$0")" && pwd)

case "${1:-}" in
  "")      check=false ;;
  --check) check=true ;;
  *)       echo "usage: install.sh [--check]" >&2; exit 2 ;;
esac

if [ "$repo" != "$HOME/dotfiles" ]; then
  echo "warning: the repo is at $repo, but the pointers refer to ~/dotfiles" >&2
fi

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
    apply "$mode" "$target" "$value" "$(dirname "$list")"
  done < "$list"
done

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
