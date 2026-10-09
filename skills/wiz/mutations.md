# Wiz GraphQL mutations (session)

## associateServiceTicket

Link a Jira (or other) ticket to a Wiz issue.

```graphql
mutation AssociateTicket($issueId: ID!, $ticketId: String!, $ticketUrl: String!) {
  associateServiceTicket(
    input: { issueId: $issueId, ticketId: $ticketId, ticketUrl: $ticketUrl }
  ) {
    serviceTicket {
      id
      externalId
      url
    }
  }
}
```

Variables:

```json
{
  "issueId": "<wiz-issue-uuid>",
  "ticketId": "ABC-123",
  "ticketUrl": "https://<your-tracker>/browse/ABC-123"
}
```

Batch (aliases; keep ~8–10 per request):

```graphql
mutation {
  a0: associateServiceTicket(input: {issueId: "<id0>", ticketId: "ABC-123", ticketUrl: "https://<your-tracker>/browse/ABC-123"}) {
    serviceTicket { id externalId }
  }
  a1: associateServiceTicket(input: {issueId: "<id1>", ticketId: "ABC-123", ticketUrl: "https://<your-tracker>/browse/ABC-123"}) {
    serviceTicket { id externalId }
  }
}
```

## requestContainerImageScan

Trigger a scan for a **docker image reference** (not the Wiz inventory UUID).

```graphql
mutation RequestScan($imageReference: String!) {
  requestContainerImageScan(input: { imageReference: $imageReference }) {
    success
  }
}
```

Example `imageReference`:

```text
<registry-host>/<project>/<image>@sha256:<digest>
```

If schema returns a different payload shape, introspect or adjust selection set from API Console errors.

## reassessIssue

Ask Wiz to re-evaluate an existing issue after a scan / fix.

Payload on eu16 currently only exposes `_stub`:

```graphql
mutation Reassess($issueId: ID!) {
  reassessIssue(input: { issueId: $issueId }) {
    _stub
  }
}
```

Batch:

```graphql
mutation {
  r0: reassessIssue(input: { issueId: "<id0>" }) { _stub }
  r1: reassessIssue(input: { issueId: "<id1>" }) { _stub }
}
```

Same control may rate-limit to one on-demand run / 10 minutes (`RATE_LIMIT_EXCEEDED`).

## Session smoke test

```graphql
query {
  issuesV2(first: 1) {
    totalCount
    nodes {
      id
    }
  }
}
```

If `issuesV2` is unavailable on the tenant schema, fall back to whatever the API Console suggests, or a minimal introspection:

```graphql
query { __typename }
```

## Notes

- Runtime / KEV issues may stay OPEN until the **running** workload image is replaced; registry rescan alone is often not enough.
- `requestContainerImageScan` may fail with `on-demand container image scan is not enabled` on some tenants; fall back to `reassessIssue` and/or redeploy a fixed image.
- Prefer MCP for bulk listing; use session GraphQL for writes.
- Selection sets vary by Wiz schema version; on field errors, shrink the selection set to `{ __typename }` under the mutation root or match API Console examples.
