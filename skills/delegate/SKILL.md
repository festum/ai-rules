---
name: delegate
description: ship without implementing. Investigate all related repos and docs, reconcile conflicting sources, produce plans that a cheaper agent (omp, opencode, Cursor, smaller Claude model) executes, verify the result, then push, open the PR, and turn review comments and CI failures into new plans until the PR is approved.
user-invocable: true
allowed-tools: read, write, edit, grep, bash, github, todo, ask, agent, omp
---

# delegate

This skill never writes production code. It covers the same lifecycle as `ship` (plan, verify, push, PR, review comments, CI, Dev deploy), but every code change is planned in the ticket's worktree and executed by another agent.

Terms:
- **Ticket**: the work item in any tracker (Jira, Linear, GitHub Issues, …). `<TICKET>` is its ID, e.g. `ABC-123`.
- **Tracker tool**: whatever integration is available for that tracker (CLI, MCP server, or a dedicated skill).
- **Plan file**: `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/plan-v<N>.md`. The plan file holds the plan; current state lives beside it in `STATE.md`.

## How to use it

First run: `/delegate <ticket URL>`. The URL identifies the tracker; it goes into `STATE.md`. After that, just run `/delegate` again whenever you come back. Optional words steer the run, e.g. `replan` (redo Stage 2 after a spec change) or a note such as "executor stopped at task 3".

### Resolving the ticket

1. The argument, if given (URL or ID).
2. The ticket already handled in this session.
3. The current directory: a worktree whose branch is a ticket ID.
4. The `STATE.md` whose key, branch, or aliases match.
5. Nothing resolvable → ask for the ticket URL.

Never assume a tracker host.

### Plan file

Header of every plan file:

```
version: v<N> | updated: <UTC>
```

The review round log and the verification notes live in `STATE.md` `## Verification`.

### Detecting the stage

Every run reloads the ticket, then gathers:
- `STATE.md` (status, Verification, Plan) and the plan files `plan-v<N>.md` for the ticket.
- Worktree changes vs the base: `git status`, `git log <base>..HEAD`, and whether they are newer than the last verification notes.
- The PR: `gh pr list --head <TICKET> --json number,url,reviewDecision`.
- Unreplied review threads, using the GraphQL query and "actionable" rule from `ship` §4.
- Real CI checks from `statusCheckRollup`, excluding approval-gate jobs (change-record / sign-off).

| State | Stage |
|---|---|
| No worktree or no plan file | 1 Prepare → 2 Plan → 3 Hand off |
| Plan handed off, no new changes | Executor hasn't run; repeat the hand-off message |
| Changes newer than the last verification notes | 4 Verify |
| Gap plan handed off, no new changes | Waiting on the executor; repeat the hand-off message |
| Verified CLEAN, no PR | 5 Deliver |
| PR open with unreplied threads or failing real checks | 6 PR loop |
| PR open, verified fixes not yet pushed | 6 PR loop (push + reply part) |
| PR approved, no unreplied threads, real checks green | Done; report status |

## Plan mode

Read-only stage detection → short plan (which stage, which files this run touches) → ExitPlanMode → run the stages.

## Principles

1. Authority order: reviewer comments > ticket > PRD/RFC, unless timestamps prove otherwise (1.3).
2. Contracts and enums: read the producer's serializers/annotations; never guess JSON fields or enum text. Plan a wire DTO → mapper → domain enum layer, a Truth Table for polymorphic fields, and an unknown-value fallback. Producer code inaccessible → stop and report.
3. Raw-payload HTTP tests: changed external integration behavior gets an HTTP-level mock test (WireMock, MockWebServer, MSW, …) with real raw JSON.
4. Team conventions are mandatory (1.4).
5. No out-of-scope work, incidental refactoring, or speculative code. Ambiguity goes to open questions, never into vague tasks.

## Hard rules

- Do not skip a stage on a vague wish for speed; a clear direct command overrides stage ceremony (`rules.md` §1).
- Blocking dependencies → report `BLOCKED: <reason + needed auth or info>` with the options, never decide to wait.
- A stage is done only when its artifacts exist (plan file `plan-v<N>.md`, plus the review round log and verification notes in `STATE.md`).

## Workflow

### Stage 1 — Prepare

#### 1.1 Set up the worktree

1. Find the touched repos from the user's project map if one is provided (e.g. a `CLAUDE.md` / `AGENTS.md` in the parent folder listing repos, purposes, and aliases); fall back to searching only when the map has no match. From then on, search only inside those repos and their worktrees, never across the whole parent folder. Update every touched repo to the latest base branch. Reuse an existing worktree/branch for the ticket if one exists (`git worktree list`, `git branch -a | grep -i <TICKET>`).
2. Otherwise create a worktree on branch `<TICKET>` from the base branch. A task without a ticket uses the `T-` key as the branch name: `T-<YYYYMMDD>-<kebab-short-name>`.
3. When creating `STATE.md`, fill the `repos:` header with the touched repos, and name the task's omp session after the key; record it in `## Sessions` as `<name> (<id>) (<cwd>)` when the session starts (resume by id; see the `omp` skill).

#### 1.2 Gather sources and ingest

1. Load the ticket via the tracker tool: description, acceptance criteria, comments, linked issues, attachments, last-updated time.
   - If the project has a snapshot, load it in `snapshot` read mode (`arch`, `facts`, `conflicts`, `plan` sections relevant to the ticket) for orientation. Verify every snapshot claim the plan relies on against its cited source; never trigger a sync.
2. Follow every link (RFC, wiki pages, PRD, design docs, chat excerpts). Record each with its URL, author, and last-modified time; the list goes into the plan in Stage 2.
3. Read the producer code paths and the related repos the ticket touches; record findings with full_file_path:line evidence. Use parallel read-only subagents for broad sweeps.
4. Read the project docs (README, agent/spec files) and note every conflicting statement for 1.3.

#### 1.3 Reconcile inconsistencies

Re-judge **every** conflicting pair, including any a tool flagged as auto-resolved, with these rules, and record the verdict per row in the Inconsistency Register (written into the plan in Stage 2):

- Evidence: ticket updated/comment dates, wiki version dates, `git log -1 --format=%cI -- <path>`, PR merge dates.
- The newest deliberate statement wins; merged code on the base branch beats a doc older than the merge; a reviewer/owner comment beats the ticket body it postdates.
- Timestamps don't settle it, or the newest source looks accidental → `NEEDS-HUMAN`; ask before planning.
- Sync every stale source: stale code or repo docs → the ticket's requirements in the plan; stale ticket → draft the exact edit, apply via the tracker tool after approval; stale wiki/RFC/PRD → draft a minimal edit to the existing structure (preserve comment anchors and element IDs, never rewrite the page), apply only after approval through a write path the user allows.

#### 1.4 Team conventions

For each concern the change touches (persistence, migrations, tests, DTO/mapping, config, messaging, error handling), find ≥3 precedents. If the target repo has fewer than 3, survey the team's most actively developed sibling repo instead of copying the nearest single example. Write the list (convention → source path) into the plan's Conventions section so the planner and reviewers treat it as binding. Deviations go to the user.

### Stage 2 — Plan and review the plan

1. Write `v<N>` to `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/plan-v<N>.md`. `N` = highest existing version + 1; never overwrite an existing version. Self-contained template: goal and acceptance criteria, sources, Inconsistency Register, conventions, repos/worktrees, contracts and Truth Tables, ordered tasks (files, tests, done-when), verification commands, open questions, out of scope, executor rules (no push, no PR; keep `HANDOFF-NOTES.md` in the worktree updated with what changed and what was verified). For every task that removes, replaces, or reverses existing behavior, add what that behavior was for (commit and message, linked issue, pinning tests), whether that history shows a defect or a deliberate design, and whether the task fixes or improves it; a deliberate and correct behavior the task does not improve → the task keeps it or makes the change additive. The ticket gives the goal, not the verdict.
2. For complex or high-risk plans, use dual review, **cap 5 rounds**; straightforward plans need only a requirements/consistency review. Run (a) and (b) **in parallel** when dual review is warranted:
   - (a) omp read-only review: `omp -p --tools=read,grep,glob --advisor --max-time=15m --cwd <worktree> "<review prompt with the plan path>"`; round 2+ continues with `-c`.
   - (b) An independent Claude subagent (`agent` tool) given only the plan path and repo paths.

   Stop when material findings are resolved. After a plan edit, review the affected decisions and dependencies, not an automatic pair of clean rounds. Gap-plan reviews follow the same rule; keep the five-round ceiling, never a round quota.
   Re-verify each finding, fix the plan, append the round to `STATE.md` `## Verification`, and end the round with `CLEAN` or `ISSUES`.
3. Check the final plan yourself against the ticket's acceptance criteria, 1.3 verdicts, and 1.4 conventions. Record the verdict in `STATE.md` `## Verification`; lead the report with it in prose.

### Stage 3 — Hand off

End the run with this message (fill in absolute paths):

```
Plan: <state dir>/plan-v<N>.md (list every plan file for the ticket)
State: <state dir>/STATE.md
Worktree: <worktree> | Branch: <TICKET>
Pending: <sync edits awaiting approval, NEEDS-HUMAN items, or "none">

Run one executor inside the worktree:
  omp -p --plan-yolo --advisor --auto-approve --approval-mode=yolo --max-time=1h --cwd <worktree> "Implement <plan> exactly. Follow its Executor rules. Task state: <state dir>/STATE.md; read it first, update it after each round."
  claude --model sonnet "Implement <plan> exactly. Follow its Executor rules. Task state: <state dir>/STATE.md; read it first, update it after each round."
  opencode run "Implement <plan> exactly. Follow its Executor rules. Task state: <state dir>/STATE.md; read it first, update it after each round."
  agent -p "Implement <plan> exactly. Follow its Executor rules. Task state: <state dir>/STATE.md; read it first, update it after each round."

When it finishes, come back and run: /delegate
```

- Inspect executor changes and concrete check evidence. Continue the same session only for unresolved required work/checks; do not start a verify loop merely because the first turn ended.
- For gap rounds the executor runs against the `v<N+1>` gap plan.
- `agent -p` is the Cursor CLI, not Claude's `agent` subagent tool.
- omp liveness rules are in the `omp` skill. Executors must not push, must not merge PRs, and must not open PRs. Push stays with the controller (push gate: `git-commit` §3; Stage 5).
- Session continuity: one omp session per task. Before hand-off read `STATE.md ## Sessions`; if this task already has a session, resume it (`omp -p -r <id> …`) instead of starting a fresh session (see the `omp` skill).
- Add `<TICKET>` to the come-back command only when it will run from a different session or directory.
- Then the three lines Done / Not done / Next.

### Stage 4 — Verify the implementation

1. Reload the ticket and PR comments; read `STATE.md` (status, Verification, Plan) and the plan file.
2. Check the delivered change against the plan's goal and acceptance criteria (UAT).
3. Independently assess the delivered artifacts and concrete command/output evidence, rather than accepting a bare success claim:
   - `git diff <base>...HEAD` plus uncommitted changes; nothing outside scope; 1.4 conventions followed.
   - For changed external integrations: Truth Tables, unknown-enum fallback, and raw-payload HTTP tests present. For all changes: no debug noise; relevant defensive checks present.
   - During fixes, run checks for affected behavior/risk. At delivery, satisfy repository-required CI-equivalent lint/tests and acceptance criteria; reuse valid evidence for unchanged code. Rerun on the host only for environment differences, incomplete evidence, or remaining material risk. No extra unchanged CLEAN round.
   - If the base moved, check new base code for reusable helpers or spec changes.
4. When the change needs runtime proof (API behavior, messaging, migrations), deploy to Dev with the repo's existing deploy workflow and check logs, endpoints, and monitoring against the acceptance criteria. If the workflow needs a pushed branch, defer this to Stage 5 step 3 and note it as pending in `STATE.md` `## Verification`.
5. Gaps found → record each in `STATE.md` `## Verification`, write `v<N+1>` containing only the delta (findings, corrective tasks, pointer to `v<N>`), repeat Stage 2's dual review, then Stage 3 with `v<N+1>` as the executor's plan.
6. No gaps → `CLEAN`; continue with Stage 5 (no PR yet) or the push + reply part of Stage 6 (PR open).
7. Lead the report with the verdict in prose (append `ISSUES: <list>` only when gaps remain; no trailing `CLEAN`); add Done / Not done / Next only when pausing for the human.

### Stage 5 — Deliver

1. Push follows the gate in `git-commit` §3. Under `unattended-auto`, go straight to step 2 after verify. Otherwise report (Done / Not done / Next) and wait for the human to say "push", which also covers opening the PR. Before the gate opens, do not push; commits follow the `git-commit` mode rule.
2. After the push gate opens: follow `git-commit` (merge the base, review what changed, rerun invalidated required checks, squash into one commit). When `git-commit` §5 allows a PR-free direct merge, merge and push per that section, clean up, and stop; otherwise push and open the PR with `open-pr`.
3. Wait for the real checks; failures go to Stage 6. Green → auto-deploy to Dev with the repo's existing deploy workflow (the repo's own pipeline, covered by the push authorization), report the result.

### Stage 6 — PR loop

Follow `ship` §4 for collecting threads, judging comments (accept / partial / reject / ask; multi-lens review per `ship` §4 — `/code-review` or read-only bounded omp, never omp's default task mode — only for diffs over 400 lines or security/payment-sensitive changes), reply wording, CI handling, and Dev deploy. The difference: code changes go to the executor.

1. Collect unreplied threads and failing real checks. Put product/design questions (`ask`) to the user.
2. Record every accepted item and real CI failure as a gap in `STATE.md` `## Verification` → write `v<N+1>` → Stage 2 review → Stage 3 hand-off with `v<N+1>` as the executor's plan.
3. Next run, after the executor: Stage 4 verify. Then draft numbered replies (`# | Thread | Decision | Change | Draft reply`) and wait for the human to approve the replies (push follows `git-commit` §3; replies never auto-post, `unattended-auto` included).
4. After the push gate opens: `git-commit` → push → wait for the real checks → reply once per thread via `gh` → auto-deploy to Dev → back to step 1.
5. Never auto-resolve threads; PR hygiene per `ship` §4 (no approvals, no gate-nudging comments, no description edits). Stop when no unreplied threads remain and `reviewDecision` is `APPROVED`. Pause on design forks. Two unsuccessful fix rounds for the same failure → new plan with a different approach (`rules.md` §6); pause only when every remaining path needs external input or 3 approaches failed.

## Related skills (if installed)

- `ship`: same lifecycle with Claude implementing; owns the PR-loop rules referenced in Stage 6.
- `open-pr`: PR title, template, reviewers.
- `git-commit`: commit, merge, and push rules.
- `omp`: dispatching and verifying omp runs.
