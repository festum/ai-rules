---
name: review-pr
description: Review a teammate's GitHub PR against its Jira spec and current base branch. Sync the base first, read spec and diff yourself, produce numbered findings with ultra-short draft comments, ask which to post, then post only approved items via gh.
user-invocable: true
---

# Reviewing a GitHub PR

Use when asked to review **someone else's** pull request.

Do **not** change code unless explicitly asked. Do **not** post comments until the user picks which findings to publish.

Be fast. Review in this agent. Do not spawn subagents (no security / performance / correctness / readability lenses).

## Hard rules

1. Read the linked Jira ticket (and its attached docs) before judging the PR. Spec first.
2. Review priority: **consistency → business logic → code quality**.
3. Present numbered findings + draft comments; post only what the user selects.
4. Post with `gh` only (including `gh api`). No MCP / web UI for PR comments.
5. Write comments with skill `voice` **and** the ultra-short rules below. No AI markers. No code changes in already-approved PRs unless the issue is severe and the user confirms.
6. Sync the base before judging: `git fetch origin`, then judge against `origin/<base>`. Never flag a change as missing without checking the latest base (Main Code Re-evaluation).

## Workflow

1. **Spec** — Find the Jira key from the PR body or branch. Read acceptance criteria, requirements, edge cases, and linked docs.
2. **Sync** — `git fetch origin`, then use the PR's actual base from metadata (`gh pr view --json baseRefName`), default `main`. Judge against `origin/<base>`, never a stale local `main` or an old GitHub view; check `mergeStateStatus` (e.g. `BEHIND`). The PR diff is three-dot (merge-base), so a change already in base after divergence will not appear in it and is not a gap.
3. **Diff** — Read the PR diff and enough related-repo context to judge consistency.
4. **Judge** — Combine Jira/spec gaps + consistency + logic. Severity: `blocker` / `important` / `nit`.
5. **Draft** — Number every finding. For each: one-line English comment. Ask which numbers to post.
6. **Dedupe** — Before posting, check existing threads. Prefer reply-in-thread over a new inline comment. Resolve threads the author already fixed/acknowledged.
7. **Post** — Publish only selected items at the matching file/line via `gh`.
8. **Close out** — If no blockers remain after posting: approve. If nothing material to say: leave a short `"testing approved"` general comment.

Skip Jira only if it is unreachable after one try; then judge from PR body + diff and say so.

## CI

Ignore approval-gate jobs (change-record or sign-off checks that wait on a human-filled PR field) when judging CI health. They are not code-quality checks.

## Comment style

Ultra-short. Conclusion only.

- One sentence. Prefer 1–12 words (same as skill `voice` PR review replies).
- Lead with the conclusion. Do not restate the mechanism, the file, or what the code already shows.
- One reply per thread; cover every point in that single reply.
- Factual English. Team shorthand when unambiguous (`sync`, `tx`, `config`, …).
- Snippet/screenshot only when the point is otherwise unclear.
- Never prefix with “AI Review” or similar.
- Prefix with "nit: " for the nit level suggestions.

Good: `Full slug override, not a suffix. Pass e.g. \`${{ github.head_ref || github.ref_name }}-amd64\`.`

Bad: `This replaces the full ref-name/slug. Callers must pass the complete value, e.g. \`${{ github.head_ref || github.ref_name }}-amd64\`. Passing only \`amd64\` yields \`amd64-{sha}\` and drops the branch.`

## Related skills

- Your own work before merge: `ship` self-review or `/code-review`.
- Your own PR review/CI loop: `ship` (also for PRs without a ticket).
- Jira ticket execution and review-comment fixes: `ship`.
