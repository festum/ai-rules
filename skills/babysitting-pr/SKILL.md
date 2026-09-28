---
name: babysitting-pr
description: Keep your open PR merge-ready. Collect unreplied review threads, judge them with parallel-code-review, apply reasonable fixes without committing, draft ultra-short English replies for approval, then commit/push, wait for CI, reply once per thread, and deploy to Dev. Loop until no unreplied comments and the PR is Approved.
user-invocable: true
metadata:
  version: "1.0.1"
---

# Babysitting a PR

Use when **your** PR is open and you want the agent to drive review replies, CI/conflict fixes, and Dev deploy until the PR is Approved.

This is for the PR author flow. Teammate reviews use `reviewing-github-pr`.

## Hard rules

1. **No commit / push / post until the user approves** the draft reply set (or the CI-only change summary). Local fixes first. Same gate for comment rounds and CI/conflict-only rounds.
2. **One reply per thread.** Cover every point in that single reply. Do not post again in that thread unless the reviewer leaves a **new** reply.
3. Judge review comments with **`parallel-code-review`** (findings only; do not post from it).
4. Prefer fixing code over arguing. Reasonable suggestions → apply locally. Design / speculative / wrong comments → draft a short disagreement or ask; do not silent-ignore. Reject only when wrong or harmful.
5. Before asking the user: **tests + lint must pass** locally (repo’s usual commands; ask if unclear).
6. Draft numbered English replies via **`eng`** (PR review reply voice) then **`humanizer`**. Outcome only, keep to **1–12 words**: no mechanism, file/line, values, reason, commit/SHA, or restating the diff. Chat may be Traditional Chinese; draft reply text is English.
7. Post PR replies with **`gh` only**. No MCP / web UI for comments.
8. Never force-push a shared PR branch. Don’t weaken tests just to go green. Don’t expand scope beyond the PR intent.
9. Ignore approval-gated jobs (e.g. `validate-and-record-change`) when judging CI health: they stay red until a reviewer approves, so they are not a code failure.
10. After successful replies: **deploy to Dev** via the repo’s existing script/command/workflow. If unclear, ask. Report the result.
11. Stop only when **both** are true: no unreplied review threads (including no new reviewer replies on answered threads), and `reviewDecision` is `APPROVED`. Pause and ask on design forks, or after ~3 failed fix→CI cycles.

## Loop

```
Status → Collect unreplied → Judge (parallel-code-review) → Fix locally
  → Tests/lint green → Draft numbered replies → Ask user
  → (approve) Commit+push → Wait CI (skip approval gate) → Reply once/thread → Deploy Dev → Repeat
```

### 1. Status

```bash
gh pr view --json number,title,state,url,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,reviews
gh pr checks
```

Note conflicts (`mergeStateStatus`) and failing checks. Separate approval-gated jobs from real failures. Fetch failing logs with `gh run view <run-id> --log-failed` when needed.

### 2. Collect unreplied threads

Fetch review discussion (inline + conversation) so you can see thread replies and resolve state:

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments
gh api repos/{owner}/{repo}/issues/{pr}/comments
gh api graphql -f query='
  query($owner:String!,$repo:String!,$number:Int!) {
    repository(owner:$owner,name:$repo) {
      pullRequest(number:$number) {
        reviewThreads(first:100) {
          nodes {
            id isResolved isOutdated comments(first:50) {
              nodes { databaseId author { login } body createdAt }
            }
          }
        }
      }
    }
  }' -F owner=... -F repo=... -F number=...
```

**Actionable** when unresolved **and** (latest comment is not from you, **or** you have never replied). Skip threads you already answered with no newer reviewer reply.

Organize into a numbered working set: file/line, author, ask, related code.

### 3. Judge with `parallel-code-review`

On the actionable set + current PR diff / changed files:

1. Pull `parallel-code-review` and run the multi-lens pass.
2. Classify each comment: **accept** / **partial** / **reject** / **ask** (product/design → include in the user ask, do not guess).

### 4. Fix locally

- Apply accepted / partial fixes on the PR branch.
- Resolve merge conflicts if present (`git fetch` + merge/rebase per repo norm). Ask when both sides are ambiguous.
- After merging base, re-check it for reusable helpers or spec changes (Main Code Re-evaluation).
- Fix real CI failures the same way (lint / types / tests / build). Skip approval-gated jobs.
- Re-run lint + tests until green.

### 5. Draft numbered replies → ask user

Present one list:

| # | Thread | Decision | Local change | Draft reply |
|---|--------|----------|--------------|-------------|
| 1 | `file:line` | accept | what changed | `Done.` / `Fixed.` |
| 2 | … | reject | none | ultra-short why |

Ask whether the draft replies are OK (edit numbers / wording as needed). Summarize CI/conflict fixes included in the pending commit.

### 6. On approval: commit → push → wait CI → reply → deploy

1. **Commit** with `writing-commit-messages` (Conventional Commits). Stage only babysitting-related fixes.
2. **Push** the PR branch.
3. **Wait for pipeline** on the real checks only. `gh pr checks --watch` blocks on every check, including the approval gate (`validate-and-record-change`), which stays red until a reviewer approves; so watch only the real checks (poll `statusCheckRollup`, or watch named checks) instead of the raw `--watch`. If a real check fails: fix locally and re-ask before the next commit/push. Post review replies once the real checks are green for this round.
4. **Reply** on each approved thread via `gh` (inline reply / GraphQL `addPullRequestReviewThreadReply`). Resolve when done and tooling allows.
5. **Deploy to Dev**; report result.
6. Re-enter from step 1.

## Related skills

- `parallel-code-review` — judgment pass (step 3)
- `writing-commit-messages` — commit text after approval (step 6)
- `eng` + `humanizer` — public English reply drafts
- Teammate PRs: `reviewing-github-pr` (no `parallel-code-review`; that skill forbids subagents)

## Notes

- If nothing to change and no unreplied threads: report status and keep watching until Approved (or ask whether to nudge reviewers).
- `gh pr ready` only if the user wants it unmarked from draft after green + clean threads.
