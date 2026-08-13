---
name: reviewing-github-pr
description: Review a teammate's GitHub PR against its Jira spec. Gather context, run parallel-code-review, produce numbered findings with draft comments, ask which to post, then post only approved items via gh.
user-invocable: true
---

# Reviewing a GitHub PR

Use when asked to review **someone else's** pull request.

Do **not** change code unless explicitly asked. Do **not** post comments until the user picks which findings to publish.

## Hard rules

1. Read the linked Jira ticket (and its attached docs) before judging the PR. Spec first.
2. Review priority: **consistency → business logic → code quality**.
3. Run `parallel-code-review` for the multi-lens code pass, then merge with spec findings.
4. Present numbered findings + draft comments; post only what the user selects.
5. Post with `gh` only. No MCP / web UI / raw API for PR comments.
6. Write comments with `eng` (then `humanizer`). No AI markers. No code changes in already-approved PRs unless the issue is severe and the user confirms.

## Workflow

1. **Spec** — Find the Jira key from the PR body or branch. Read acceptance criteria, requirements, edge cases, and linked docs.
2. **Diff** — Read the PR diff and enough related-repo context to judge consistency. Build the changed-file list for reviewers.
3. **Parallel review** — Pull and run `parallel-code-review` on that change set (security / performance / correctness / readability). Keep it read-only; do not post from subagents.
4. **Merge judgment** — Combine Jira/spec gaps + consistency notes + parallel findings. Priority remains consistency → business logic → code quality. Severity: `blocker` / `important` / `nit`.
5. **Draft** — Number every finding. For each: short rationale + draft English comment (or thread reply). Ask which numbers to post.
6. **Dedupe** — Before posting, check existing threads. Prefer reply-in-thread over a new inline comment. Resolve threads the author already fixed/acknowledged.
7. **Post** — Publish only selected items at the matching file/line via `gh`.
8. **Close out** — If no blockers remain after posting: approve. If nothing material to say: leave a short `"testing approved"` general comment.

## CI

Ignore `validate-and-record-change` failures when judging CI health. That job is an approval gate (often empty Functional tester), not a code-quality check.

## Comment style

- One reply per thread; cover every point in that single reply.
- Very short, factual English. Lead with the conclusion.
- Prefer team shorthand when unambiguous (`WG`, `GL`, `sync`, `tx`, `config`, …).
- Attach a snippet/screenshot only when it clarifies the point.
- Never prefix with “AI Review” or similar.

## Related skills

- `parallel-code-review` — required multi-lens pass (step 3). Direction: `reviewing-github-pr` → `parallel-code-review`.
- Your own work before merge: `requesting-code-review`.
- New design / product exploration: `brainstorming` only when the review turns into designing something new.
