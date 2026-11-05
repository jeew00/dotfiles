# The Principles

How to build software when coding agents write the code.
The same rules apply to solo and team work, and to private and public projects.

## The 4 rules

```
1. Spec first.       Each prompt says what to build, when it is done, and what is out of scope.
2. Small branch.     One small slice on a branch. Merge to main only after a review.
3. Machines check.   One check command, and a test for each change.
4. Review, then merge.
```

## Scale the process to the task

| Task | Process |
|---|---|
| **Tiny** (typo, rename, one line) | Prompt → branch → check → merge |
| **Normal** (one feature, one bug) | Prompt with "Done when" and "Out of scope" → tests → check → review → merge |
| **Large** (more than one session) | Spec + tickets → one new session for each ticket |
| **Risky** (data, a release, a file format) | Normal, and add `/code-review` |

Start a new session (`/clear`) for each task. This is the largest saving of tokens.

## Review: 3 questions

1. **Does it do what I asked, and nothing more?**
2. **Did I see it work?** Test output, a screenshot, or I ran the app.
3. **Can I undo it?** A two-way door (easy to undo) can merge quickly. A one-way door (data loss, a public release, a file format change) gets a slow review and `/code-review`.

`check` and `/code-review` examine the rest.

## Machines do the rest

You do not need to remember these. A machine does them:

- `check`: format, lint, tests, and the secret scan
- Branch protection: `main` changes only through a PR that passes CI
- The pre-push hook: runs `check`
- CI: runs `check` on the PR, on a clean machine and on each OS that the project supports
- `/ship`: the merge steps
- The release task: version, tag, clean build, publish

---

# Reference

Read a part when its situation comes.

## Words

| Word | What it is | Where it is kept |
|---|---|---|
| **Prompt** | What you type to the agent | Only in the session |
| **Spec** | The content of a task: what to build, done when, out of scope | A prompt, an issue, or a file |
| **Issue** | A saved task with a number | The git server, or `.scratch/` |
| **Ticket** | An issue that is one slice of a larger spec | Same as an issue |
| **Tracer bullet** | A thin, complete slice through all layers, testable by itself | — |
| **Seam** | A public interface where tests examine the behavior | — |

## Tasks without a git server

- Put the task files in `.scratch/`, and add `.scratch/` to `.gitignore`.
- The agent reads a task file only when you name it. Search tools skip git-ignored files by default.
- Delete a task file when its task is done. The lasting knowledge goes into the code, the tests, the commit message, and an ADR if necessary.

## The principles in detail

**You own the work.** The agent writes the code. You say what you want, you set the checks, and you review the result.

**`main` always works.** Each commit on `main` builds and passes the checks.

**Commit when something works.** A commit is a checkpoint. The message tells why.

**New idea during a task → issue.** Then continue the current task. One topic in each session.

**Tests examine behavior at a seam.**
- Each bug first gets a test that fails.
- The expected value comes from the spec or a known example. A test that calculates the expected value the same way as the code always passes, so it shows nothing.
- ML: use exact tests for the code around the model. Use evals with metrics and thresholds for the model output.

**Check levels.**

| When | What | Target time |
|---|---|---|
| While the agent works | Only the tests of the changed part | Seconds |
| Before a push | The full `check` (the pre-push hook) | Less than 1–2 minutes |
| On the PR | The full `check` in CI, on a clean machine | Less than 5 minutes |
| Before a release, or on a schedule | Evals, tests with real models, slow scans | Any |

Run the same check on the same code only one time on the same machine. Measure before you make a check faster.

**If it is not in the repo, it does not exist.** The README, `AGENTS.md`, and ADRs give each agent and each teammate the same knowledge.

**Some things never go into git:** secrets, private data, big files, and build output. For big files, git keeps a pointer (URL + hash), and a storage service keeps the bytes.

**The setup is reproducible.** Pin the tool versions, commit the lock files, and use one setup command.

**A version, a tag, and a build are one unit.** Build from the tag on a clean machine: CI, or a clean clone. Each release gets a new version number.

**Undo with `revert`, not `reset`.** `revert` adds a commit that undoes an old commit, and the history stays the same. For a bad release: revert, then make a new patch release.

**Keep valuable things on the server.** API keys, prompts, and important logic stay on the server, not in the client.

**Each item must fix a problem that you actually have.** If nothing breaks when you delete an item, delete it.

**When an agent makes an error, fix the environment.** First try an automatic check. Write a text rule only when no check can catch the error. After a bad session, run `/retro`.

## The loops

### Change

One loop for solo and team work. Only the settings are different (see "Solo and team").

```
git switch -c my-change            1. branch
(agent: seams → tests → code)      2. work, and commit each step
git push -u origin my-change       3. the pre-push hook runs check
gh pr create                       4. body: summary, evidence, merge danger, "Closes #12"
gh pr checks --watch               5. CI must pass
(review)                           6. read the PR, then say "merge"
gh pr merge --squash               7. the server merges and deletes the branch
git switch main && git pull        8. update main
git branch -D my-change            9. clean up
```

- "merge" means steps 7–9. The agent does them all, and asks nothing more.
- If the PR has a conflict with `main`: on the branch, do `git rebase main` and `git push --force-with-lease`. Then CI runs again.
- `-D` is necessary, because after a squash merge git does not know that the branch is merged. The PR on the server shows that it is merged.

### Change without a git server

```
git switch -c my-change            1. branch
(agent: seams → tests → code)      2. work, and commit each step
mise run check                     3. check (this replaces CI)
git diff main...my-change          4. review, then say "merge"
git switch main
git merge --squash my-change       5. one commit on main
git commit
git branch -D my-change            6. clean up
```

- If `main` changed during the work: on the branch, do `git rebase main`, then do step 3 again.
- Add a git server before a second person joins. Then use the loop above.

### Release

```
version bump → commit → tag → clean build → publish
```

### Fix a bad change

```
git revert <commit> → check → (if released) new patch release
```

## Solo and team

The loop is the same. Only these settings are different:

| | Solo | Team |
|---|---|---|
| Reviewer | You read the PR, then say "merge" | A teammate approves on the server |
| Branch protection on `main` | PR + CI must pass | PR + CI + 1 approval |
| Issues | For work that you will not do now | For all planned work |

Set up each repo one time: branch protection on `main`, only squash merge, and "delete the branch after the merge".
When a teammate joins, change only the branch protection: add 1 approval.

A private repo on GitHub Free cannot enforce branch protection. Then the agent must wait for CI before the merge.
CI minutes are free for public repos. For private repos they are limited, and a macOS minute counts as 10.

## Where each rule goes

| Layer | File | Content |
|---|---|---|
| **Personal** | `agents/AGENTS.md` → Claude Code and Codex (`install.sh`) | About you: how you talk, how you work with agents, what needs your permission |
| **Project** | `project/AGENTS.md` → each repo | About the code: the agreement that each person and each agent in the repo follows |
| **Review** | `CODING_STANDARDS.md` in each repo | Judgment rules. Only the reviewer reads them. |
| **Machine** | Git hooks, `check`, CI, branch protection | Rules that must always be true |

### How to write the agent files

- **Keep them short.** They load in each session. Put pointers, and the rules that the environment does not show.
- **Write each rule one time.** Two copies of a rule will become different.
- **Do not copy the environment.** If one command shows the information, write a pointer to it.
- **Write positive instructions.** "Commit on a branch" works better than "Do not commit on `main`".
- **Remove no-ops.** If the agent does a thing without the rule, delete the rule.
- For a new project, copy `project/AGENTS.md`, fill in the `<...>` parts, and delete the parts that do not apply.

## Git commands and when to use them

| Command | Use it when |
|---|---|
| `switch -c` | You start a change. |
| `diff main...branch` | You review the changes of a branch. |
| `merge --squash` | You put a branch on `main` as one commit, without a git server. |
| `rebase main` | `main` changed and your branch must start from the new `main`. Only on your own branch. |
| `revert` | You must undo a commit that is already on `main`. |
| `worktree` | Two agents must work at the same time, each in its own folder. |
| `stash` | You must put changes aside for a short time without a commit. |
| `cherry-pick` | You need one commit from another branch, but not the rest. |
| `bisect` | Something broke and you must find the commit that caused it. |

You can skip for now: interactive rebase, submodules, git-flow.
