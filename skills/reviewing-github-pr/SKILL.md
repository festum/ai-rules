---
name: reviewing-github-pr
description: Review a teammate's GitHub PR against its Jira spec. Read spec and diff yourself, produce numbered findings with ultra-short draft comments, ask which to post, then post only approved items via gh.
user-invocable: true
---

# Reviewing a GitHub PR

Use when asked to review **someone else's** pull request.

Do **not** change code unless explicitly asked. Do **not** post comments until the user picks which findings to publish.

Be fast. Review in this agent. Do not spawn subagents (no security / performance / correctness / readability lenses, no `/parallel-code-review`).

## Hard rules

1. Read the linked Jira ticket (and its attached docs) before judging the PR. Spec first.
2. Review priority: **consistency → business logic → code quality**.
3. Present numbered findings + draft comments; post only what the user selects.
4. Post with `gh` only. No MCP / web UI / raw API for PR comments.
5. Write comments with `/eng` **and** the ultra-short rules below. No AI markers. No code changes in already-approved PRs unless the issue is severe and the user confirms.

## Workflow

1. **Spec** — Find the Jira key from the PR body or branch. Read acceptance criteria, requirements, edge cases, and linked docs.
2. **Diff** — Read the PR diff and enough related-repo context to judge consistency.
3. **Judge** — Combine Jira/spec gaps + consistency + logic. Severity: `blocker` / `important` / `nit`.
4. **Draft** — Number every finding. For each: one-line English comment. Ask which numbers to post.
5. **Dedupe** — Before posting, check existing threads. Prefer reply-in-thread over a new inline comment. Resolve threads the author already fixed/acknowledged.
6. **Post** — Publish only selected items at the matching file/line via `gh`.
7. **Close out** — If no blockers remain after posting: approve. If nothing material to say: leave a short `"testing approved"` general comment.

Skip Jira only if it is unreachable after one try; then judge from PR body + diff and say so.

## CI

Ignore `validate-and-record-change` failures when judging CI health. That job is an approval gate (often empty Functional tester), not a code-quality check.

## Comment style

Ultra-short. Conclusion only.

- One sentence. Prefer under 20 words.
- Lead with the conclusion. Do not restate the mechanism, the file, or what the code already shows.
- One reply per thread; cover every point in that single reply.
- Factual English. Team shorthand when unambiguous (`WG`, `GL`, `sync`, `tx`, `config`, …).
- Snippet/screenshot only when the point is otherwise unclear.
- Never prefix with “AI Review” or similar.

Good: `Full slug override, not a suffix. Pass e.g. \`${{ github.head_ref || github.ref_name }}-amd64\`.`

Bad: `This replaces the full ref-name/slug. Callers must pass the complete value, e.g. \`${{ github.head_ref || github.ref_name }}-amd64\`. Passing only \`amd64\` yields \`amd64-{sha}\` and drops the branch.`

## Related skills

- Your own work before merge: `/requesting-code-review`.
- New design / product exploration: `/brainstorming` only when the review turns into designing something new.
