---
name: ship
description: Inspect, design, and execute a Jira ticket, open the PR, then handle review comments, CI and Dev deploy until approved; ticketless PRs (dependabot, infra) run the same flow from step 4
user-invocable: true
allowed-tools: read, write, edit, grep, bash, github, todo, ask, open-pr, git-commit, omp
---

Read Jira ticket (via MCP); combine with Codebase/PRD/PR comment context to complete task design, implementation, PR creation, review fixes. Ticketless PRs (dependabot, infra): start at step 4, skip every Jira step.

## Priorities and principles
1. Weight: review comments > Jira ticket > PRD. PRD may be stale; conflict → decide by Jira + comments + existing implementation.
2. Cross-service contract / enum mapping:
   - Wire DTOs ≠ domain models. Never cast raw transport (Wire Payload) strings straight into enums; isolate wire protocol from internal domain logic via dedicated mapper layer.
   - Verifying producer code always includes serialization definitions (annotations, field names, kebab-case / snake_case conversions, enum custom text). Never guess transport strings from producer-internal constant names.
   - Polymorphic payloads (`type`/`kind` etc.) → dedicated Truth Table. Never force one struct onto them.
   - Mapping includes fallback for unknown enum values; future producer fields can't crash deserialization.
3. Raw payload HTTP tests (no pure unit interface stubs):
   - External API communication: never verify with client/interface mocks alone; they hide JSON deserialization and mapping errors.
   - Always HTTP-level mock (WireMock, MSW, MockWebServer) with real raw JSON response body from Producer/Postman/Log to test deserialization and mapping.
4. Minimal change and convergence: prefer reusing existing logic. Before change removes, replaces, or reverses existing behavior (in plan and while editing), trace what it was for (`git blame -w -M -L <range> <file>` for introducing commit, `git show -s --format=%B <sha>` for reasoning, `git log -L :<func>:<file> --no-merges` for evolution, linked issue, pinning tests) and whether defect or deliberate design; judge on merit: fixes known defect or measurably improves behavior → proceed; deliberate correct behavior the change doesn't improve → stays, or change becomes additive. Ticket gives goal, not verdict. Reasoning → plan. After every base-branch merge, re-scan codebase for newly reusable tools and spec changes to sync.
5. No out-of-scope changes; no unnecessary refactoring.
6. Repeat invocations: skip completed steps (branch made, PR opened: never redo), but always reload Jira ticket and PR comments for latest state.
7. Session continuity: mid-task follow-ups (from anyone, not only PR commenter) answered in current session; continue context via runtime session (OMP `-c` / `-r`). Restart investigation only when question is outside session context.

## Workflow

### 1. Prepare and branch
- Read or create shared state file `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/STATE.md` (key = ticket ID). Never rewrite existing `Scope & constraints`. Fill `repos:` on creation; ticketless task names branch after T- key. Name task's omp session after key; record in `## Sessions` as `<name> (<id>) (<cwd>)` when session starts (resume by id; see `omp` skill).
- Reload Jira ticket, fill missing spec.
- Project has snapshot → load in `snapshot` read mode (`arch`, `facts`, `defects`, `conflicts`) for orientation; verify any snapshot claim design relies on against its cited source. Never trigger sync.
- Locate repos: project map exists (parent `CLAUDE.md` / `AGENTS.md` listing repos, uses, aliases) → check map first, search only when map misses; once fixed, search only inside those repos and worktrees. Never scan whole parent folder.
- Team convention survey: target repo is new service, or pattern type (persistence layer, tests, migration, commit style) has < 3 precedents → first collect that pattern's conventions from active same-team repos; list "conventions to follow" with source files in plan. Never copy single recent precedent from target repo; every deviation = human decision.
- Built-in `plan` breaks task down; `todo` tracks state.
- Branch: none exists → bring base up to date per repo freshness (`rules.md` §2; dirty or in-use checkout not switched, worktree branches from `origin/<base>`), create worktree branch `<ticket-id>` (Jira ticket ID); already on it → continue.

### 2. Implement and verify
- External integration behavior changes → contract/enum alignment and raw payload tests first:
  1. Verify producer repo's serialization and enum definitions; produce Truth Table.
  2. Build HTTP-level raw payload tests from producer's real payload shape; failing test first to validate deserialization and mapping.
  3. Complete implementation, make test pass.
- Verification scope: during implementation, checks covering changed behavior and material risks; prose-only edits and routine operations start no test loop. Before delivery/push: satisfy repo's required CI-equivalent lint/tests and explicit acceptance criteria. Preserve security checks and HTTP raw-payload tests for changed integrations. Reuse valid unchanged evidence; no mandatory extra clean round or duplicate host run.
- Self code review (read `git diff`):
  1. No noise: no debug prints, debug code, unrelated formatting, unused imports.
  2. Defensive: null/empty checks, exception handling, boundary conditions present.
  3. Consistency: logic matches Truth Table and Jira spec 100%.
  (Don't proceed until all three pass.)
- Stage end: update STATE.md `## Status` and `## Verification` (one line each), append one line to `log.md`.

### 3. Push and PR creation (or direct merge)
- Push follows gate in `git-commit` §3. `unattended-auto` → continue after verify. Otherwise hand results to human (Done / Not done / Next), wait for "push", which also covers creating PR. Commits before that follow `git-commit` mode rule (checkpoints allowed in auto mode).
- Push authorized → per `git-commit`: merge base branch, resolve conflicts in favor of this branch, review base changes for reusable code and spec changes; rerun only checks invalidated by merge; squash unpushed work into one commit.
- `git-commit` §5 allows PR-free direct merge → merge per that section, skip PR and step 4. Otherwise create PR via `open-pr`: title, reviewers, linked issues compliant, template used; description = minimal English summary only, no AI markers.
- PR exists → URL into STATE.md `## Sessions`, update `## Status`.

### 4. Review, CI and Dev deploy loop
Loop: state -> collect unresolved threads -> judge -> fix locally -> lint/tests -> draft replies -> human approval of replies -> commit/push -> wait CI -> reply per thread -> deploy Dev -> repeat.
Stop conditions (both hold): no unresolved threads (including new reviewer replies on answered threads) and `reviewDecision` = `APPROVED`. Design disagreement → pause, ask human. Two unsuccessful fix rounds for same failure → backtrack, switch approach (`rules.md` §6); ask human only when every remaining path needs external input or 3 approaches failed.
Every round: STATE.md header `status: pr-loop`; `## Status` keeps PR URL and unresolved thread count; pause points (waiting on human approval, etc.) write Done / Not done / Next under `## Status`.

- State:
  - With ticket: reload Jira ticket for updates.
  - `gh pr view --json number,title,state,url,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,reviews` and `gh pr checks`; separate approval-gate jobs (change-record / sign-off, red until approved) from real failures; former ≠ CI failure: waits for human approver; never fix, comment on, or retrigger it. Failure logs: `gh run view <run-id> --log-failed`.
- Collect unresolved threads:
  - `gh api` reads inline and conversation comments; GraphQL for thread state:
    ```bash
    gh api graphql -f query='
      query($owner:String!,$repo:String!,$number:Int!) {
        repository(owner:$owner,name:$repo) {
          pullRequest(number:$number) {
            reviewThreads(first:100) {
              nodes { id isResolved isOutdated comments(first:50) { nodes { databaseId author { login } body createdAt } } }
            }
          }
        }
      }' -F owner=... -F repo=... -F number=...
    ```
  - To process: unresolved, and (last commenter ≠ me, or I never replied). Answered threads, no new reviewer reply: skip.
  - Check existing `todo` and `plan`; skip finished items; build numbered list + Truth Table: file/line, author, ask, related code.
  - Cross-check Jira and PRD: PRD contradicts `todo` -> mark `PRD-stale`; outside Jira scope -> mark `deferred`, not in this PR.
- Judge: classify each thread in-agent as accept / partial / reject / ask (product or design questions → ask; don't guess). Only when diff > 400 lines, or change touches security, payments, or external input parsing → additionally multi-lens review (Claude built-in `/code-review`, or read-only omp: `omp -p --tools=read,grep,glob --advisor --max-time=15m "<review prompt>"`; follow `omp` skill for preflight and liveness). Lenses **in parallel** (findings only; publish nothing). Never omp implementation mode for read-only review; it permits code writes.
  - Fix over argue: apply reasonable suggestions; reject only wrong or harmful ones; never silently ignore.
- Local fixes:
  - Fix with `edit`, reusing existing logic; conflict → merge base branch per `git-commit`, re-evaluate.
  - Tests for changed executable behavior; changed external integrations → raw-payload HTTP tests with representative real payload shapes. Prose-only fixes: no unrelated tests. Fix real CI failures (lint / types / tests / build) same round; never weaken tests to go green.
  - Behavior fixes → affected checks; at delivery satisfy repo-required CI-equivalent checks using valid evidence for unchanged code. Two unsuccessful fixes for same failure → backtrack, switch approach (`rules.md` §6); no automatic extra clean round. Review `git diff` for noise, defensive handling, contract/spec consistency.
- Draft replies, wait for human (hard gate, `unattended-auto` included):
  1. Rescan unresolved threads with `gh`; confirm every expected fix handled, nothing missed.
  2. Numbered table `# | Thread | Decision | Local change | Draft reply` + this round's CI/conflict fix summary.
  3. Pausing for human → state in three lines: Done / Not done / Next.
  4. Before human approves drafted replies: no PR comment or reply, ever. Commit and push follow push gate (`git-commit` §3); replies never do.
- After push gate opens:
  1. Per `git-commit`, commit (stage only this round's changes), push.
  2. Wait only for real CI checks (poll `statusCheckRollup` or named check). Never `gh pr checks --watch`: hangs on approval-gate jobs. Real check failure → back to local fix and re-ask.
  3. CI green, and only if human approved drafts → reply per thread via `gh` (inline reply / GraphQL `addPullRequestReviewThreadReply`).
  4. Deploy to Dev via repo's existing workflow/script automatically (repo's own pipeline, covered by push authorization; ask only when workflow unknown), report result, return to loop start.
- Reply rules:
  - Reply only with 100%-verified facts; pending items say "checking the producer repo"; never overpromise or declare done early.
  - One reply per thread covering every point; answered threads get no new comments, only edits to existing reply, unless reviewer replied again.
  - Accept / fixed: conclusion only, usually 1-5 English words (cap 12), e.g. `Fixed.` / `Done.` / `Out of scope.`; no mechanism, no file/line/numbers, no diff restatement.
  - Reject / not applying: one-sentence conclusion; judgment marked `IMO` / `I think`; one reason when needed; `WDYT?` only when truly open (see `voice` PR review replies).
  - Never Chinese, apology filler, commit/SHA, repeated info. `voice` skill for English replies (`voice` includes humanizer); `voice` = SSOT for reply wording, this doc keeps publish and workflow.
  - Publish only via `gh`, never MCP or web UI; never mark threads resolved yourself.
- Never force-push shared PR branch; never widen PR scope. Nothing to fix, no unresolved threads → report state, stop; resume next run.
- PR hygiene: never approve PR, comment to satisfy, trigger, or nudge approval gate or reviewer, or edit PR title, description, or template fields after creation (sign-off fields belong to approver). Human-approved per-thread replies = the only PR comments; approval-gate job belongs to human approver.
- Merge per `git-commit` §5 (merge authority, go-ahead or `unattended-auto`, Squash and merge).
