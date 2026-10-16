---
name: dependabot
description: Find, approve and auto-merge dependabot PRs across the repos listed in PROJECT_REPOS, handle stale PRs, approve the final prod/sandbox deploy gates, and monitor each deploy. Use when merging dependabot PRs.
user-invocable: true
allowed-tools: read, write, edit, grep, bash, github, todo, ask
---

# dependabot

Runs one repo at a time: do steps 1-8 for the current repo, pause for the human signal, then repeat for the next repo.

## 0. Scope and state

- Read the target repos from `PROJECT_REPOS` in `~/.ai-rules.local.md`, format `PROJECT_REPOS=[owner/repo-a, owner/repo-b]`. If `PROJECT_REPOS` is missing, ask user for input and add it to `~/.ai-rules.local.md`.
- Missing or empty → ask the user for the list. Never guess, never scan parent folders.
- State: `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/STATE.md`, key `T-<YYYYMMDD>-dependabot` (no branch or worktree needed). On start, read STATE.md so already-merged PRs are not reprocessed; after each step update `## Status` / `## Verification` and append one `<UTC> dependabot <event>` line to `log.md`.

## 1. Find the PRs

- `gh pr list --author app/dependabot` in the current repo. Trust the author login, never the `[dependabot]` title alone.
- Handle them one at a time until none remain.
- No open PRs → record it, report the verdict in prose (no trailing `CLEAN`), and go straight to the pause in step 8.

## 2. Discover the repo's guards and deploy flow

- Find out whether this repo has an approval-gate job (a CI job that stays red until a human signs off in the pipeline) and a manual production deployment flow (a post-merge deploy workflow waiting for manual approval).
- If either exists, remember its exact job/workflow name in STATE.md; steps 3, 6 and 7 apply those names to this repo. If it does not exist, the step that needs it is skipped.

## 3. Pre-checks (any failure: do not approve)

- Changes are limited to dependency manifests / lockfiles. Anything else → leave the PR untouched, record it, and raise it at the pause point.
- A non-dependabot user pushed a commit → same: record it, raise it at the pause point, and continue to the next dependabot PR without blocking on the question.
- Real CI checks are green. The approval-gate job from step 2 (if any) is exempt: it stays red until a human signs off, so it is not a CI failure — ignore it when judging CI health and never `gh pr checks --watch` on it. A genuinely failing check → record it, raise it, do not approve.

## 4. Approve and auto-merge

- `gh pr merge <pr> --auto --squash`, then `gh pr review <pr> --approve`.
- Merge authority per `git-commit` §5: arming here is Hermes's call (or the human's when Hermes is absent) and still needs the human's go-ahead. A delegated executor stops and emits `BLOCKED` instead.
- Never merge manually. If auto-merge is disabled on the repo, or branch protection needs more approvals than this, stop and report instead.
- All comments and commands go through `gh`, never MCP.

## 5. Stale PRs

- Stale = `mergeStateStatus` is `BEHIND`/`DIRTY`, or dependabot asked for a rebase.
- Comment `@dependabot rebase`; if dependabot says the branch expired, comment `@dependabot recreate` instead.
- One open command per PR. Normally wait until one PR merges before commenting on another, but if every PR is stale and nothing is merging, command a single PR rather than deadlocking.

## 6. Deploy pipelines

- After the last dependabot PR merges: cancel the other runs of the manual production deployment flow discovered in step 2 (they sit at manual approval anyway), keeping only the run for the newest merged SHA. Before that last PR merges, cancel nothing. No such flow → nothing to cancel.
- Verify the kept run's SHA equals the last merged commit and its real checks are green.

## 7. Prod gates (human checkpoint)

- Report Done / Not done / Next and wait for the explicit go-ahead before touching any gate.
- On approval: approve the manual gate of every production environment in the flow discovered in step 2.

## 8. Monitor and hand off

- Watch the repo's logs/metrics for 15 minutes after the deploy.
- Abnormal (error-rate spike, deploy errors, failed post-deploy checks) → stop, investigate urgently, report; do not continue.
- Record the round verdict in STATE.md and append a `log.md` line; report it in prose, `ISSUES: <list>` only when failed, no trailing `CLEAN`.
- Pause and wait for the user's signal before moving to the next repo.
