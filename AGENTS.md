# AGENTS.md

dotfiles: my config for development tools, so that each of my machines (Windows, macOS, Linux) behaves the same.
Scope: config that changes how I develop (git, coding agents, editor, shell), my working rules, and pinned tool versions.
Out of scope: secrets, machine state, project config, and apps that are not dev tools. If a request is out of scope, say so before you start.

## Work loop

- Commands: `mise tasks`. A task is done when `mise run check` passes. On Windows, run it in Git Bash: only Git Bash has `sh`.
- `~/dotfiles` is the live config and stays on `main`. Make each change in a worktree: `git worktree add ../dotfiles-<name> -b <name>`.
- After review, merge in `~/dotfiles` as one squash commit. The post-merge hook applies the change.
- Each change to `install.sh` comes with a test in `tests/install_test.sh`.
- Commit messages tell why the change was made.

## Rules

- The repo is public. Never add secrets, tokens, keys, history, caches or machine paths. The pre-commit hook runs gitleaks.
- `install.sh` owns each target in a `files.list`. Edit the source in this repo, never the target in home.
- `install.sh` and the hooks are POSIX `sh`. They must run in Git Bash (Windows), macOS and Linux. shellcheck examines them.
- Each file fixes a problem that exists now. Its commit message names the problem.

## Add a program

1. Problem: what is different between machines without this config? If nothing, stop.
2. Install: pin the version in mise if mise has the program. If not, add the install step to `README.md`.
3. Location: find the config path on Windows, macOS and Linux.
4. Split: shared preferences go into `<program>/`. Machine state stays in home. Secrets never go here.
5. Mechanism: use the first one that the program supports:
   1. An include or import in the program's config (a `pointer`).
   2. An env var or a flag that points to the repo file.
   3. A `copy`.
6. Register: add lines to `<program>/files.list`. If a path differs by OS, add one variable for it in `install.sh`.
7. Verify: `mise run check`, then `sh install.sh` and `sh install.sh --check` on this machine.
