---
name: git-commit
description: Single source for git rules — commit message format (Conventional Commits, no scope, ≤18 words), syncing the base branch, the human push gate, squash-on-push, and safe stashing. Use whenever committing, merging the base branch, or pushing.
user-invocable: true
---

# git-commit

Other skills (`ship`, `open-pr`, `delegate`) defer to this skill for every commit, merge, and push.

## 1. Commit message

```
<type>: <subject>

<optional body>
```

- Conventional Commits, **no scope**: `feat: add OAuth2 login flow`, not `feat(auth): ...`.
- Subject ≤18 words, imperative mood ("add", not "added"), lowercase after the type, no trailing period.
- Never add a `Co-Authored-By` trailer.
- Body only when needed; explain **why**, not what (the diff shows what).
- Breaking change: `feat!: change auth token format` plus a `BREAKING CHANGE:` footer with migration steps.

| Type | When |
|---|---|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `refactor` | Restructuring without behavior change |
| `docs` | Documentation only |
| `test` | Adding or updating tests |
| `chore` | Build, tooling, deps |
| `perf` | Performance improvement |
| `style` | Formatting, whitespace |
| `ci` | CI/CD pipeline changes |
| `revert` | Reverting a previous commit |

Good: `fix: resolve race condition in WebSocket reconnect`, `chore: upgrade TypeScript to 5.4`.
Bad: `fixed stuff`, `WIP`, `update`, `feat(api): ...` (has a scope).

Each commit is one logical change; don't mix refactoring with feature work.

## 2. Syncing the base branch

- `git fetch origin`, then **merge** the base branch (default `main`). Do not rebase.
- Resolve conflicts in favor of this branch's changes.
- After every merge, re-check what the base brought in: reusable helpers or modules that should replace local code, or spec changes that need matching adjustments. Re-run lint and tests afterwards.

## 3. Push gate

Commit and push only after the human explicitly says "push". Until then, leave changes in the working tree.

Exception: Hermes direct edits to system rule/config docs (hermes.md File Governance B) commit immediately; pushing still waits for the human.

## 4. Squash on push

At push time, squash all not-yet-pushed commits (everything ahead of the upstream, or ahead of the base before the first push) into one commit with a message per §1. Never rewrite commits that are already pushed, unless the user has given standing authorization to amend and force-push on their own feature branch.

## 5. Setting work aside

The stash stack is shared across worktrees and sessions, so never use bare `git stash` / `git stash pop`. Prefer a temporary WIP commit. If you must stash: `git stash push -u -m "<unique-tag>"`, record its SHA from `git stash list --format='%H %gs'`, restore with `git stash apply <sha>`, then drop that entry after finding it again by tag.
