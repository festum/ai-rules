---
name: reviewing-github-pr
description: Review a teammate's GitHub PR against its Jira spec, present numbered findings for approval before posting, and reply to PR threads in a clean human style.
user-invocable: true
---

# Reviewing a GitHub PR

Use when asked to review someone else's pull request.

Review with a code-review mindset: bugs, behavioral regressions, security issues, and missing tests are the priority, ordered by severity. Do not make code changes yourself unless explicitly asked. Pull in the `requesting-code-review` skill and the brainstorming skill for extra context gathering (the `/brainstorm` slash command is deprecated — use the brainstorming skill instead).

## Workflow

1. Find the Jira link from the PR description or branch name; read the acceptance criteria, requirements, and edge cases. Digging into the documents in the Jira ticket is mandatory before reviewing the PR.
2. Read the PR diff and code in related repos for full context.
3. Review as a senior engineer across the project and related repos. Priority order: consistency > business logic > code quality — use the `reviewing-code` skill's checklist (correctness, maintainability, performance, type safety, testing) for the code-quality pass.
4. Flag any spec mismatch or missing requirement from the Jira ticket.
5. Number every finding. Present the numbered list with a draft reply for each (concise, professional English) and ask the user which ones to post.
6. Before posting a new inline comment, check existing threads for the same issue — reply there instead of duplicating; resolve threads the author already acknowledged.
7. Post only the findings the user selects, at the matching file/line.
8. After posting, approve the PR if there are no blockers; leave a `"testing approved"` general comment if there is nothing else to add.

## CI Status

`validate-and-record-change` job failures are not CI failures — they only mean the PR isn't approved yet. Ignore this job when judging CI health.

## Comment Style

- Post with `gh` CLI only — no web UI, no raw API calls.
- One reply per thread, ever — cover every point in that single reply.
- Plain English, short and factual — no "I think/feel", no long paragraphs.
- Never prefix comments with "AI Review" or any AI marker; write like a human reviewer.
- Attach code snippets or screenshots when they clarify the point.
