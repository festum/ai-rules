---
name: delegate
description: ship without implementing. Investigate all related repos and docs, reconcile conflicting sources, produce plans that a cheaper agent (omp, opencode, Cursor, smaller Claude model) executes, verify the result, then push, open the PR, and turn review comments and CI failures into new plans until the PR is approved.
user-invocable: true
allowed-tools: read, write, edit, grep, bash, github, todo, ask, agent, omp
---

# delegate

Skill never writes production code. Same lifecycle as `ship` (plan, verify, push, PR, review comments, CI, Dev deploy), but every code change is planned in ticket's worktree and executed by another agent.

Terms:
- **Ticket**: work item in any tracker (Jira, Linear, GitHub Issues, …). `<TICKET>` = its ID, e.g. `ABC-123`.
- **Tracker tool**: whatever integration is available for that tracker (CLI, MCP server, or dedicated skill).
- **Plan file**: `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/plan-v<N>.md`. Plan file holds plan; current state lives beside it in `STATE.md`.

## How to use it

First run: `/delegate <ticket URL>`. URL identifies tracker; goes into `STATE.md`. Afterwards, run `/delegate` again on each return. Optional words steer the run, e.g. `replan` (redo Stage 2 after spec change) or a note like "executor stopped at task 3".

### Resolving the ticket

1. Argument, if given (URL or ID).
2. Ticket already handled in this session.
3. Current directory: worktree whose branch is a ticket ID.
4. `STATE.md` whose key, branch, or aliases match.
5. Nothing resolvable → ask for ticket URL.

Never assume a tracker host.

### Plan file

Header of every plan file:

```
version: v<N> | updated: <UTC>
```

Review round log and verification notes live in `STATE.md` `## Verification`.

### Detecting the stage

Every run reloads ticket, then gathers:
- `STATE.md` (status, Verification, Plan) and ticket's plan files `plan-v<N>.md`.
- Worktree changes vs base: `git status`, `git log <base>..HEAD`, and whether newer than last verification notes.
- PR: `gh pr list --head <TICKET> --json number,url,reviewDecision`.
- Unreplied review threads, via GraphQL query and "actionable" rule from `ship` §4.
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

Read-only stage detection → short plan (which stage, which files this run touches) → ExitPlanMode → run stages.

## Principles

1. Authority order: reviewer comments > ticket > PRD/RFC, unless timestamps prove otherwise (1.3).
2. Contracts and enums: read producer's serializers/annotations; never guess JSON fields or enum text. Plan wire DTO → mapper → domain enum layer, Truth Table for polymorphic fields, unknown-value fallback. Producer code inaccessible → stop, report.
3. Raw-payload HTTP tests: changed external integration behavior → HTTP-level mock test (WireMock, MockWebServer, MSW, …) with real raw JSON.
4. Team conventions mandatory (1.4).
5. No out-of-scope work, incidental refactoring, speculative code. Ambiguity → open questions, never vague tasks.

## Hard rules

- Never skip a stage on vague wish for speed; clear direct command overrides stage ceremony (`rules.md` §1).
- Blocking dependencies → report `BLOCKED: <reason + needed auth or info>` with options; never decide to wait.
- Stage done only when its artifacts exist (plan file `plan-v<N>.md`, plus review round log and verification notes in `STATE.md`).

## Workflow

### Stage 1 — Prepare

#### 1.1 Set up the worktree

1. Find touched repos from user's project map if provided (e.g. `CLAUDE.md` / `AGENTS.md` in parent folder listing repos, purposes, aliases); search only when map has no match. Then search only inside those repos and worktrees, never whole parent folder. Update every touched repo to latest base branch. Reuse existing worktree/branch for ticket if one exists (`git worktree list`, `git branch -a | grep -i <TICKET>`).
2. Otherwise create worktree on branch `<TICKET>` from base branch. Ticketless task: `T-` key as branch name: `T-<YYYYMMDD>-<kebab-short-name>`.
3. Creating `STATE.md`: fill `repos:` header with touched repos; name task's omp session after key; record in `## Sessions` as `<name> (<id>) (<cwd>)` when session starts (resume by id; see `omp` skill).

#### 1.2 Gather sources and ingest

1. Load ticket via tracker tool: description, acceptance criteria, comments, linked issues, attachments, last-updated time.
   - Project has snapshot → load in `snapshot` read mode (`arch`, `facts`, `conflicts`, `plan` sections relevant to ticket) for orientation. Verify every snapshot claim plan relies on against its cited source; never trigger sync.
2. Follow every link (RFC, wiki pages, PRD, design docs, chat excerpts). Record each with URL, author, last-modified time; list goes into plan in Stage 2.
3. Read producer code paths and related repos ticket touches; record findings with full_file_path:line evidence. Parallel read-only subagents for broad sweeps.
4. Read project docs (README, agent/spec files); note every conflicting statement for 1.3.

#### 1.3 Reconcile inconsistencies

Re-judge **every** conflicting pair, including any a tool flagged as auto-resolved, with these rules; record verdict per row in Inconsistency Register (written into plan in Stage 2):

- Evidence: ticket updated/comment dates, wiki version dates, `git log -1 --format=%cI -- <path>`, PR merge dates.
- Newest deliberate statement wins; merged code on base branch beats doc older than the merge; reviewer/owner comment beats ticket body it postdates.
- Timestamps don't settle it, or newest source looks accidental → `NEEDS-HUMAN`; ask before planning.
- Sync every stale source: stale code or repo docs → ticket's requirements in plan; stale ticket → draft exact edit, apply via tracker tool after approval; stale wiki/RFC/PRD → draft minimal edit to existing structure (preserve comment anchors and element IDs, never rewrite page), apply only after approval via write path user allows.

#### 1.4 Team conventions

Each concern the change touches (persistence, migrations, tests, DTO/mapping, config, messaging, error handling): find ≥3 precedents. Target repo has < 3 → survey team's most actively developed sibling repo instead of copying nearest single example. Write list (convention → source path) into plan's Conventions section; planner and reviewers treat it as binding. Deviations → user.

### Stage 2 — Plan and review the plan

1. Write `v<N>` to `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/plan-v<N>.md`. `N` = highest existing version + 1; never overwrite existing version. Self-contained template: goal and acceptance criteria, sources, Inconsistency Register, conventions, repos/worktrees, contracts and Truth Tables, ordered tasks (files, tests, done-when), verification commands, open questions, out of scope, executor rules (no push, no PR; keep `HANDOFF-NOTES.md` in worktree updated with what changed and what was verified). Every task removing, replacing, or reversing existing behavior: add what that behavior was for (commit and message, linked issue, pinning tests), whether history shows defect or deliberate design, whether task fixes or improves it; deliberate correct behavior the task doesn't improve → task keeps it or makes change additive. Ticket gives goal, not verdict.
2. Complex or high-risk plans: dual review, **cap 5 rounds**; straightforward plans: only requirements/consistency review. Dual review warranted → run (a) and (b) **in parallel**:
   - (a) omp read-only review: `omp -p --tools=read,grep,glob --advisor --max-time=15m --cwd <worktree> "<review prompt with the plan path>"`; round 2+ continues with `-c`.
   - (b) Independent Claude subagent (`agent` tool) given only plan path and repo paths.

   Stop when material findings resolved. After plan edit, review affected decisions and dependencies; no automatic pair of clean rounds. Gap-plan reviews: same rule; keep five-round ceiling, never round quota.
   Re-verify each finding, fix plan, append round to `STATE.md` `## Verification`, end round with `CLEAN` or `ISSUES`.
3. Check final plan yourself against ticket's acceptance criteria, 1.3 verdicts, 1.4 conventions. Record verdict in `STATE.md` `## Verification`; lead report with it in prose.

### Stage 3 — Hand off

End the run with this message (absolute paths filled in):

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

- Inspect executor changes and concrete check evidence. Continue same session only for unresolved required work/checks; no verify loop just because first turn ended.
- Gap rounds: executor runs against `v<N+1>` gap plan.
- `agent -p` = Cursor CLI, not Claude's `agent` subagent tool.
- omp liveness rules: `omp` skill. Executors never push, merge PRs, or open PRs. Push stays with controller (push gate: `git-commit` §3; Stage 5).
- Session continuity: one omp session per task. Before hand-off read `STATE.md ## Sessions`; task already has session → resume it (`omp -p -r <id> …`), no fresh session (see `omp` skill).
- Add `<TICKET>` to come-back command only when it will run from different session or directory.
- Then three lines Done / Not done / Next.

### Stage 4 — Verify the implementation

1. Reload ticket and PR comments; read `STATE.md` (status, Verification, Plan) and plan file.
2. Check delivered change against plan's goal and acceptance criteria (UAT).
3. Independently assess delivered artifacts and concrete command/output evidence; never accept bare success claim:
   - `git diff <base>...HEAD` + uncommitted changes; nothing outside scope; 1.4 conventions followed.
   - Changed external integrations: Truth Tables, unknown-enum fallback, raw-payload HTTP tests present. All changes: no debug noise; relevant defensive checks present.
   - During fixes: checks for affected behavior/risk. At delivery: satisfy repository-required CI-equivalent lint/tests and acceptance criteria; reuse valid evidence for unchanged code. Host rerun only for environment differences, incomplete evidence, remaining material risk. No extra unchanged CLEAN round.
   - Base moved → check new base code for reusable helpers or spec changes.
4. Change needs runtime proof (API behavior, messaging, migrations) → deploy to Dev via repo's existing deploy workflow; check logs, endpoints, monitoring against acceptance criteria. Workflow needs pushed branch → defer to Stage 5 step 3, note as pending in `STATE.md` `## Verification`.
5. Gaps found → record each in `STATE.md` `## Verification`, write `v<N+1>` containing only delta (findings, corrective tasks, pointer to `v<N>`), repeat Stage 2 dual review, then Stage 3 with `v<N+1>` as executor's plan.
6. No gaps → `CLEAN`; continue with Stage 5 (no PR yet) or push + reply part of Stage 6 (PR open).
7. Lead report with verdict in prose (`ISSUES: <list>` only when gaps remain; no trailing `CLEAN`); Done / Not done / Next only when pausing for human.

### Stage 5 — Deliver

1. Push follows gate in `git-commit` §3. `unattended-auto` → straight to step 2 after verify. Otherwise report (Done / Not done / Next), wait for human "push", which also covers opening PR. Before gate opens: no push; commits follow `git-commit` mode rule.
2. Push gate open → follow `git-commit` (merge base, review what changed, rerun invalidated required checks, squash into one commit). `git-commit` §5 allows PR-free direct merge → merge and push per that section, clean up, stop; otherwise push, open PR with `open-pr`.
3. Wait for real checks; failures → Stage 6. Green → auto-deploy to Dev via repo's existing deploy workflow (repo's own pipeline, covered by push authorization), report result.

### Stage 6 — PR loop

Follow `ship` §4 for collecting threads, judging comments (accept / partial / reject / ask; multi-lens review per `ship` §4 — `/code-review` or read-only bounded omp, never omp's default task mode — only for diffs > 400 lines or security/payment-sensitive changes), reply wording, CI handling, Dev deploy. Difference: code changes go to executor.

1. Collect unreplied threads and failing real checks. Product/design questions (`ask`) → user.
2. Every accepted item and real CI failure → gap in `STATE.md` `## Verification` → write `v<N+1>` → Stage 2 review → Stage 3 hand-off with `v<N+1>` as executor's plan.
3. Next run, after executor: Stage 4 verify. Then draft numbered replies (`# | Thread | Decision | Change | Draft reply`), wait for human to approve replies (push follows `git-commit` §3; replies never auto-post, `unattended-auto` included).
4. Push gate open → `git-commit` → push → wait for real checks → reply once per thread via `gh` → auto-deploy to Dev → back to step 1.
5. Never auto-resolve threads; PR hygiene per `ship` §4 (no approvals, no gate-nudging comments, no description edits). Stop when no unreplied threads remain and `reviewDecision` = `APPROVED`. Pause on design forks. Two unsuccessful fix rounds for same failure → new plan with different approach (`rules.md` §6); pause only when every remaining path needs external input or 3 approaches failed.

## Related skills (if installed)

- `ship`: same lifecycle with Claude implementing; owns PR-loop rules referenced in Stage 6.
- `open-pr`: PR title, template, reviewers.
- `git-commit`: commit, merge, push rules.
- `omp`: dispatching and verifying omp runs.
