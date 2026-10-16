---
name: git-commit
description: Single source for git rules — commit message format (Conventional Commits, no scope, ≤18 words), syncing the base branch, the human push gate, PR merge authority, squash-on-push, and safe stashing. Use whenever committing, merging the base branch, merging a PR, or pushing.
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

Interactive sessions: commit only when the human explicitly asks; "push" means commit then push. Until then, leave changes in the working tree.

Auto mode (dispatched runs: Hermes direct rule/config edits, OMP executing a delegated task): checkpoint commits are allowed. Pushing still waits for the explicit human "push"; at push time all not-yet-pushed commits squash into one (§4), so the branch never accumulates garbage commits.

Mode is determined by invocation, never by guessing who typed: headless flags (`-p`, `--auto-approve`, `--approval-mode=yolo`) = `auto`; interactive TTY without them = human session. A dispatch prompt carrying the shared STATE.md path confirms delegation. Misclassification is low-stakes: worst case is extra local commits, squashed at push.

## 4. Squash on push

Every push: first squash ALL not-yet-pushed work into exactly one commit (message per §1), then push. Scope: every commit ahead of the upstream (or ahead of the base before the first push) plus any uncommitted working-tree changes. Applies to every push, not only the first. Never rewrite commits that are already pushed, unless the user has given standing authorization to amend and force-push on their own feature branch.

## 5. Merging a PR

Merge authority belongs to Hermes only (the human when Hermes is absent). Executors (OMP, `claude`, `opencode`, the `agent` tool) never merge and never enable auto-merge: on reaching a mergeable PR, stop and emit `BLOCKED: <reason>` plus the authorization needed, and let Hermes act.

- Hermes merges, or enables auto-merge, only after an explicit human go-ahead. Enabling auto-merge is still that same authorization, not a shortcut past it.
- Interactive: merge only on the human's instruction.
- Auto mode (Hermes only): same gate. Arming is not merging: prefer `gh pr merge <pr> --auto --squash`, then `gh pr review <pr> --approve`, so the merge fires on its own once the repo's required checks and reviews pass. Never run a manual merge (`gh pr merge <pr> --squash`, the web UI) that lands the PR immediately and skips that gate.
- Preconditions before arming: real CI checks green (approval-gate jobs are exempt, they stay red until a human signs off), no unresolved review threads, `reviewDecision` = `APPROVED`.
- Stop and report instead of arming when: auto-merge is disabled on the repo, or branch protection requires more approvals than this session can give. The merge still needs the human's go-ahead in either case, so never work around it.
- When the merge lands on GitHub, prefer **Squash and merge** so the PR lands as one commit with a message per §1. Use a merge commit only when the human explicitly asks.

## 6. Setting work aside

The stash stack is shared across worktrees and sessions, so never use bare `git stash` / `git stash pop`. Prefer a temporary WIP commit. If you must stash: `git stash push -u -m "<unique-tag>"`, record its SHA from `git stash list --format='%H %gs'`, restore with `git stash apply <sha>`, then drop that entry after finding it again by tag.

## 7. Committer identity and signing

- Committer identity comes from git config (`user.name`, `user.email`). Never override it per commit: no `--author`, no `GIT_AUTHOR_*` / `GIT_COMMITTER_*` env, no ad-hoc config override. If the commit needs an identity that differs from git config, stop and ask the human.
- If the repo or machine already has commit signing configured (`commit.gpgsign`, SSH signing, or CI signature checks), keep signing on every commit. Never pass `--no-gpg-sign` or disable signing to make a commit go through; if signing fails, report and stop instead of bypassing.
