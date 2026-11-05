# dotfiles

My development tools behave the same on each machine (Windows, macOS, Linux).
A new machine is ready after one clone and one command.

## Contents

| Folder | Content | Installed to |
|---|---|---|
| `agents/` | My personal rules for coding agents | Claude Code (pointer), Codex (copy) |
| `claude/` | Claude Code settings, the notification sound hook for each OS, and the status line script | `~/.claude/settings.json` (copy) |
| `principle/` | How I build software with coding agents. `project/AGENTS.md` is the template for a new project. | — |
| `git/` | Shared git config, the commit email for each forge, and the global ignore file. Machine keys (credential helpers) stay in `~/.gitconfig`. | `~/.config/git/config` (pointer) |
| `tmux/` | Shared tmux config and 7 status bar colors. macOS and Linux only: tmux does not run on native Windows. The color of each machine is machine state in `~/.config/tmux/local.conf`. | `~/.tmux.conf` (pointer) |
| `mise/` | Global tools with pinned versions: jq (for the Claude Code status line) on each OS, tmux on macOS and Linux. `~/dotfiles/mise.toml` has the tools of this repo only. | `~/.config/mise/config.toml` (copy) |
| `claude/`, `codex/`, `git/`, `mise/`, `tmux/` | `files.list`: which file goes where | — |
| `scripts/` | Repo tasks: `prune.sh` removes the worktrees of merged branches | — |
| `hooks/` | Git hooks of this repo: secret scan before commit, check before push, apply after pull | — |

## New machine

1. Install git, [gh](https://cli.github.com) and [mise](https://mise.jdx.dev).
2. `gh auth login`
3. `git clone https://github.com/jeew00/dotfiles.git ~/dotfiles`
4. `cd ~/dotfiles && mise trust && sh install.sh && mise install` (on Windows, use Git Bash). On macOS and Linux, it asks for the tmux status bar color of this machine. `mise install` installs the tools of this repo and the global tools.
5. Log in to each agent: `claude` then `/login`; `codex login` (one time for each Codex account folder).

## Daily use

| Task | Command |
|---|---|
| Get the changes from another machine | `git -C ~/dotfiles pull` (the post-merge hook runs `install.sh`), then `mise install` if a tool version changed |
| Show drift between this repo and home | `sh ~/dotfiles/install.sh --check` |
| Change the tmux color of this machine | `sh ~/dotfiles/install.sh --theme <name>` (names: `tmux/themes/`), then `prefix r` in tmux |
| Make a change | See `AGENTS.md` |

## Never in this repo

Secrets, tokens, keys, history, caches and machine state. The repo is public.
The pre-commit hook and `mise run check` scan for secrets with gitleaks.
