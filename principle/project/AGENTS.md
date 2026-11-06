# AGENTS.md

<Project name>: <one sentence: what it does, and for whom>.
Scope: <pointer to the brief>. If a request is out of scope, say so before you start.

## Work loop

- Commands: `<task runner> --list`. A task is done when `<check>` passes.
- Git server: <GitHub | GitLab (self-hosted), <URL>>. CLI: <gh | glab>.
- Work on a branch. Push it, and open a PR: summary, evidence, merge danger, `Closes #<n>`.
- When CI passes and the reviewer says "merge": squash-merge with the server CLI, with the subject "<PR title> (<PR number>)" and the body below. Then update `main`, and delete the local branch.
- Each behavior change comes with a test at a public interface. For a bug, first write a test that goes red.
- For a new feature, propose the test seams and get approval before you write tests.
- Take expected values from the spec or a known example.
- Put I/O behind small interfaces, so tests use fakes and run offline.
- While you work, run the tests of the changed part. The pre-push hook runs `<check>` one time at the end.
- The PR title is the commit subject on `main`: `area: what the change does`. The area is the package or directory, in lowercase. No period at the end, 72 characters at most.
- The squash commit body: none when the subject says all of it. If not: the problem, the change, the effect on users or callers, and what does not change. Wrap at 72 columns.
- Commits on the branch are checkpoints. The squash merge removes their messages.

## Rules

- Secrets live only in `.env`. Add each new variable name to `.env.example`.
- Code that runs on user machines contains no secrets.
- Private data: <git-ignored folder>. Large files: <storage>, and git keeps the URL and the hash.
- A release is a SemVer tag `vX.Y.Z` on `main`, built from the tag on a clean machine. Each release gets a new number.
- Undo a change on `main` with `git revert`.

## Where things go

- Code: <layout>. Each module explains itself at the top of its main file.
- Tool config: at the root, in an existing file when the tool allows it.
- Decisions: `docs/adr/`. Domain words: `docs/glossary.md`. Review rules: `CODING_STANDARDS.md`.
- Tasks: <the server's issues | `.scratch/`, git-ignored>. Read a task only when the user names it. Delete a `.scratch/` file when its task is done.
- Add a file, a tool, a dependency, or a rule only for a problem that exists now.

## Project rules

<Rules that only this project has: safety limits, external services, costs, privacy, writing style.>
