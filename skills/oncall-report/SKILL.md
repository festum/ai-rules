---
name: oncall-report
description: Produce the weekly on-call report — investigate Datadog for incidents across the past Monday-to-Sunday window, apply root-cause analysis (not just firefighting), consolidate findings, and post them into the team's On-Call Review Google Doc with key points annotated. Use when asked to write/update the weekly on-call report, prep for the on-call review meeting, or summarize last week's incidents.
user-invocable: true
---

# Weekly On-Call Report

Team standard (decided week of 2026-07-13, confirmed 2026-07-20 in #C05QY5WESBG by
Secil Ozdemir): on-call is not done once the immediate issue is mitigated.
Firefighting stops the bleeding; root-cause work is what raises the quality bar
and prevents recurrence. The weekly report is where that root-cause thinking
gets written down and shared.

Target doc: `1A5HtoI9qneJ7jmaYFpXWTZFPgMWAYLdqcosQqHQ1oLE` (On-Call Review notes,
one dated heading per week, newest at the top).

## Workflow

1. **Determine the window.** Past Monday through Sunday relative to today.
2. **Find this week's heading in the doc.** Use `inspect_doc_structure` /
   `get_doc_as_markdown` on the doc above. Each week has a heading
   `## <D MMM YYYY> | On-Call Review` (linked to the recurring calendar event),
   followed by an attendee list and a `Weekly update (prepared by previous
   on-call person):` bullet list — often pre-seeded with stub bullets from the
   meeting invite. If the current week's heading already exists, fill in /
   expand its stub bullets. If it doesn't exist yet, add a new heading at the
   top following the exact same pattern as the most recent entries.
3. **Investigate Datadog for that window:**
   - Error tracking (wp-logs) and warn-logs saved views linked in the doc's
     "If time" section — reuse those saved queries/dashboards, just shift the
     time range to the report window.
   - Any monitors that fired (`datadoghq.eu/monitors/manage`) for the boarding
     services (`pl-b-*`, `girolink*`).
   - Datadog access here is browser-only (no DD API/MCP tool configured) — use
     `claude-in-chrome` to open the saved links and read them. If the browser
     extension isn't connected, ask the user to paste the relevant Datadog
     views/exports instead of guessing at incident data.
   - Cross-check Slack (`slack_search_public`/`slack_read_channel`) and Jira
     for incidents already discussed or ticketed that week.
4. **For each incident found, capture:** what happened, root cause (not just
   the trigger), current status (fixed / in progress / needs long-term fix),
   and links (Slack thread, Jira ticket, Datadog view).
5. **Annotate key points** when writing into the doc — bold the root cause and
   any action-required item, same as the existing doc's emphasis style (e.g.
   `**Alert:**`, bolded queries). Don't bury the root cause in a wall of text.
6. **File or link Jira tickets** for anything needing a long-term fix, per
   [[feedback_jira_one_ticket]]: one ticket per root cause, not one per
   affected service. Link the ticket in the bullet.
7. **Write into the Google Doc** using the Google Workspace MCP tools
   (`inspect_doc_structure` for safe insertion indices, then the batch update
   tool) — match the existing formatting exactly (heading level, bullet
   nesting, inline links) rather than reformatting the doc.
8. Keep the "If time" section's saved Datadog links intact for the next
   on-call person — don't remove them when adding this week's content.

## What to avoid

- Reporting an incident with only the immediate patch and no root-cause note.
- Filing a separate Jira ticket per affected service for the same root cause.
- Reformatting or restructuring the doc's existing weeks — only add/fill the
  current week's section.
- Guessing at Datadog data when it can't actually be fetched — say so and ask
  for it instead.
