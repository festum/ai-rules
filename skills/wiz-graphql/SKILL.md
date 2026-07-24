---
name: wiz-graphql
description: >-
  Use when running Wiz GraphQL writes/queries with browser session auth, Chrome CDP
  cookie refresh, associateServiceTicket, requestContainerImageScan, reassessIssue,
  or when read-only Wiz MCP cannot perform the mutation.
---

# Wiz GraphQL

Agent-owned auth. **Never ask the user to export Cookie, source env, start Chrome manually, or remember CDP commands.**

## Auth (automatic)

`scripts/wiz_gql.py` handles auth end-to-end:

1. **Ensure debug Chrome/CDP** (`wiz_ensure_chrome.py`): if port `9222` is down, start Chrome in background with `~/.chrome-wiz-debug` and open `https://app.wiz.io`
2. Load `~/.wiz_session` if present
3. Refresh Cookie from CDP into `~/.wiz_session`
4. POST GraphQL
5. On 401/403 / GraphQL UNAUTHORIZED: ensure Chrome + CDP refresh once, retry

Default endpoint: `https://api.eu16.app.wiz.io/graphql`

User only intervenes when SSO login is required the first time (or after logout) in the auto-started Chrome window.

## Agent execution (mandatory)

Only call:

```bash
python3 ~/.cursor/skills/wiz-graphql/scripts/wiz_gql.py --file /tmp/wiz.graphql
# or stdin:
printf '%s' 'query { __typename }' | python3 ~/.cursor/skills/wiz-graphql/scripts/wiz_gql.py
```

Do **not** tell the user to run ensure/CDP/source commands.

If cookie export fails with missing `wiz-app`: ask user to finish SSO in the Chrome window that was opened, then **agent** retries `wiz_gql.py`.

Optional flags: `--variables-file`, `--allow-errors`, `--no-cdp-refresh` (rare).

Never print cookie / token values.

## Workflow

1. Prefer read-only Wiz MCP for listing when it works
2. For writes / MCP gaps: run `wiz_gql.py` (Chrome + auth automatic)
3. Mutations: [mutations.md](mutations.md); batch aliases ~8–10
4. Confirm before large write batches
5. Verify with follow-up query or MCP

## Common tasks

| Task | Mutation |
|------|----------|
| Link Jira to issue | `associateServiceTicket` |
| Rescan registry image | `requestContainerImageScan` |
| Re-evaluate issue | `reassessIssue` |
| Add issue note | `createIssueNote` |
| Bulk status/note | `updateIssues` (RESOLVED may be blocked by Wiz) |

## Reply style

Traditional Chinese to the user. English for GraphQL/public artifacts. Report what ran, counts, next step. Never paste secrets.
