# dotfiles

My development tools behave the same on each machine (Windows, macOS, Linux).
A new machine is ready after one clone and one command.

## Contents

| Folder | Content | Installed to |
|---|---|---|
| `agents/` | My personal rules for coding agents | Claude Code (pointer), Codex (copy) |
| `principle/` | How I build software with coding agents. `project/AGENTS.md` is the template for a new project. | — |
| `git/` | Shared git config, the commit email for each forge, and the global ignore file. Machine keys (credential helpers) stay in `~/.gitconfig`. | `~/.config/git/config` (pointer) |
| `tmux/` | Shared tmux config and 7 status bar colors. macOS and Linux only: tmux does not run on native Windows. The color of each machine is machine state in `~/.config/tmux/local.conf`. | `~/.tmux.conf` (pointer) |
| `claude/`, `codex/`, `git/`, `tmux/` | `files.list`: which file goes where | — |
| `hooks/` | Git hooks of this repo: secret scan before commit, check before push, apply after pull | — |

## New machine

1. Install git, [gh](https://cli.github.com) and [mise](https://mise.jdx.dev). On macOS and Linux, also install tmux: `mise use -g tmux@3.7c`.
2. `gh auth login`
3. `git clone https://github.com/jeew00/dotfiles.git ~/dotfiles`
4. `cd ~/dotfiles && mise trust && mise install && sh install.sh` (on Windows, use Git Bash). On macOS and Linux, it asks for the tmux status bar color of this machine.
5. Log in to each agent: `claude` then `/login`; `codex login` (one time for each Codex account folder).

## Daily use

| Task | Command |
|---|---|
| Get the changes from another machine | `git -C ~/dotfiles pull` (the post-merge hook runs `install.sh`) |
| Show drift between this repo and home | `sh ~/dotfiles/install.sh --check` |
| Change the tmux color of this machine | `sh ~/dotfiles/install.sh --theme <name>` (names: `tmux/themes/`), then `prefix r` in tmux |
| Make a change | See `AGENTS.md` |

## Never in this repo

Secrets, tokens, keys, history, caches and machine state. The repo is public.
The pre-commit hook and `mise run check` scan for secrets with gitleaks.
