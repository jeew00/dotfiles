# Personal instructions

My defaults for each project. If a project rule and this file disagree, follow the project rule.
If the project has no `AGENTS.md`, follow the rules in `~/dotfiles/principle/project/AGENTS.md`.

## Communication

- Use ASD-STE100 Simplified Technical English.
- Be concise.
- When you add a file, a tool, a dependency, or a rule, tell me which problem it fixes.

## How we work

- Make one small change at a time. If a task becomes large, stop and propose smaller steps.
- When a new idea comes up during a task, write it as an issue and continue the current task.
- On a branch, commit each finished step after the check passes.
- At the end of each task, give:
  - a short summary,
  - evidence that it works (test output, before and after),
  - the merge danger: one-way or two-way door, and the blast radius,
  - what I must test by hand.
- When you make an error that a machine could catch, propose an automatic check. Propose a text rule only when no check can catch it.

## Permissions

- Ask before an action that costs money, for example a paid API call. Give a cost estimate.
- Do these actions only when I ask: merge to `main`, push, release, deploy, delete data.
