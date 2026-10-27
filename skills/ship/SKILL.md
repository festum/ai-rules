---
name: ship
description: Inspect, design, and execute a Jira ticket, open the PR, then handle review comments, CI and Dev deploy until approved; ticketless PRs (dependabot, infra) run the same flow from step 4
user-invocable: true
allowed-tools: read, write, edit, grep, bash, github, todo, ask, open-pr, git-commit, omp
---

Read the Jira ticket (via MCP); combine with Codebase/PRD/PR comment context to complete the task design, implementation, PR creation and review fixes. Ticketless PRs (dependabot, infra) start at step 4 and skip every Jira step.

## Priorities and principles
1. Weight: review comments > Jira ticket > PRD. PRD may be stale; on conflict decide by Jira + comments + existing implementation.
2. Cross-service contract / enum mapping:
   - Wire DTOs differ from domain models. Never cast raw transport (Wire Payload) strings straight into enums; isolate the wire protocol from internal domain logic through a dedicated mapper layer.
   - Verifying producer code always includes the serialization definitions (annotations, field names, kebab-case / snake_case conversions, enum custom text). Never guess transport strings from producer-internal constant names.
   - Polymorphic payloads (`type`/`kind` etc.) get a dedicated Truth Table. Never force one struct onto them.
   - Mapping includes a fallback for unknown enum values so future producer fields cannot crash deserialization.
3. Raw payload HTTP tests (no pure unit interface stubs):
   - External API communication: never verify with client/interface mocks alone; they hide JSON deserialization and mapping errors.
   - Always use an HTTP-level mock (WireMock, MSW, MockWebServer) with the real raw JSON response body from Producer/Postman/Log to test deserialization and mapping.
4. Minimal change and convergence: prefer reusing existing logic. Before a change removes, replaces, or reverses existing behavior (in the plan and while editing), trace what that behavior was for (`git blame -w -M -L <range> <file>` for the introducing commit, `git show -s --format=%B <sha>` for the reasoning, `git log -L :<func>:<file> --no-merges` for the evolution, the linked issue, the tests that pin it) and whether it was a defect or a deliberate design, then judge the change on merit: a change that fixes a known defect, or makes the behavior measurably better, proceeds; a deliberate and correct behavior the change does not improve stays, or the change becomes additive. The ticket gives the goal, not the verdict. Record the reasoning in the plan. After every merge of the base branch, re-scan the codebase for newly reusable tools and spec changes that must be synced.
5. No out-of-scope changes; no unnecessary refactoring.
6. Repeat invocations: skip completed steps (branch already made, PR already opened, never redo them), but always reload the Jira ticket and PR comments to confirm latest state.
7. Session continuity: mid-task follow-ups (from anyone, not only the PR commenter) are answered in the current session; continue context via the runtime session (OMP `-c` / `-r`). Restart investigation only when the question is outside session context.

## Workflow

### 1. Prepare and branch
- Read or create the shared state file `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/STATE.md` (key = ticket ID). Never rewrite an existing `Scope & constraints`. Fill `repos:` on creation; a ticketless task names the branch after the T- key. Name the task's omp session after the key; record it in `## Sessions` as `<name> (<id>) (<cwd>)` when the session starts (resume by id; see the `omp` skill).
- Reload the Jira ticket and fill any missing spec.
- Locate repos: when a project map exists (a parent `CLAUDE.md` / `AGENTS.md` listing repos, uses, aliases) check the map first and search only when the map misses; once fixed, search only inside those repos and their worktrees. Never scan the whole parent folder.
- Team convention survey: when the target repo is a new service, or a pattern type (persistence layer, tests, migration, commit style) has fewer than 3 precedents, first collect that pattern's conventions from active same-team repos; list the "conventions to follow" with source files in the plan. Never copy a single recent precedent from the target repo; list every deviation as a human decision.
- Use the built-in `plan` to break the task down; track state with `todo`.
- Branch: if none exists, update the base checkout with `git pull --ff-only origin <base>` without disturbing dirty work, then create the worktree branch `<ticket-id>` (the Jira ticket ID); if already on that branch, continue.

### 2. Implement and verify
- When external integration behavior changes, contract/enum alignment and raw payload tests come first:
  1. Verify the producer repo's serialization and enum definitions; produce the Truth Table.
  2. Build HTTP-level raw payload tests from the producer's real payload shape; write the failing test first to validate deserialization and mapping.
  3. Complete the implementation and make the test pass.
- Verification scope: during implementation, run checks covering changed behavior and material risks; prose-only edits and routine operations do not start a test loop. Before delivery/push, satisfy the repo's required CI-equivalent lint/tests and explicit acceptance criteria. Preserve security checks and HTTP raw-payload tests for changed integrations. Reuse valid unchanged evidence; no mandatory extra clean round or duplicate host run.
- Self code review (read `git diff`):
  1. No noise: no debug prints, debug code, unrelated formatting, or unused imports.
  2. Defensive: null/empty checks, exception handling, and boundary conditions all present.
  3. Consistency: logic matches the Truth Table and Jira spec 100%.
  (Do not proceed until all three pass.)
- At stage end update STATE.md: `## Status` and `## Verification` (one line each) and append one line to `log.md`.

### 3. Human confirmation, push and PR creation
- Hand the results and state (three lines: Done / Not done / Next) to the human for final confirmation. Never push before the human explicitly says "push" (push gate: `git-commit` §3); before that, commits follow the `git-commit` mode rule (checkpoints allowed in auto mode).
- After push is authorized, per `git-commit`: merge the base branch and resolve conflicts in favor of this branch, review base changes for reusable code and spec changes; rerun only checks invalidated by that merge, then squash unpushed work into one commit.
- Create the PR via `open-pr`: title, reviewers, linked issues compliant, template used; the description is a minimal English summary only, no AI markers.
- After the PR exists: put the URL in STATE.md `## Sessions` and update `## Status`.

### 4. Review, CI and Dev deploy loop
Loop: state -> collect unresolved threads -> judge -> fix locally -> lint/tests -> draft replies -> human confirmation -> commit/push -> wait CI -> reply per thread -> deploy Dev -> repeat.
Stop conditions (both hold): no unresolved threads (including new replies from the reviewer on answered threads) and `reviewDecision` = `APPROVED`. On design disagreement, or about 3 fix rounds with CI still failing, pause and ask the human.
Every round: set STATE.md header `status: pr-loop`; `## Status` keeps the PR URL and unresolved thread count; pause points (waiting on human approval, etc.) write Done / Not done / Next under `## Status`.

- State:
  - With a ticket: reload the Jira ticket for updates.
  - `gh pr view --json number,title,state,url,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,reviews` and `gh pr checks`; separate approval-gate jobs (change-record / sign-off, always red until approved) from real failures; the former is not a CI failure. Failure logs: `gh run view <run-id> --log-failed`.
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
  - To process: unresolved, and (the last commenter is not me, or I never replied). Answered threads with no new reviewer reply: skip.
  - Check existing `todo` and `plan`; skip finished items; build the numbered list plus Truth Table: file/line, author, ask, related code.
  - Cross-check Jira and PRD: PRD contradicting `todo` -> mark `PRD-stale`; outside Jira scope -> mark `deferred`, not in this PR.
- Judge: classify each thread in-agent as accept / partial / reject / ask (product or design questions go to ask; do not guess). Only when the diff exceeds 400 lines, or the change touches security, payments, or external input parsing, additionally run a multi-lens review (Claude built-in `/code-review`, or read-only omp: `omp -p --tools=read,grep,glob --advisor --max-time=15m "<review prompt>"`; follow the `omp` skill for preflight and liveness). Run lenses **in parallel** (take findings only; publish nothing from them). Never use omp's implementation mode for a read-only review; it permits code writes.
  - Fix over argue: apply reasonable suggestions; reject only wrong or harmful ones; never silently ignore.
- Local fixes:
  - Fix with `edit`, reusing existing logic; on conflict merge the base branch per `git-commit` and re-evaluate.
  - Add tests for changed executable behavior; for changed external integrations, include raw-payload HTTP tests with representative real payload shapes. Prose-only fixes need no unrelated tests. Fix real CI failures (lint / types / tests / build) in the same round; never weaken tests to go green.
  - Run affected checks for behavior fixes; at delivery satisfy repo-required CI-equivalent checks using valid evidence for unchanged code. Stop after two unsuccessful fixes for the same failure; no automatic extra clean round. Review `git diff` for noise, defensive handling, and contract/spec consistency.
- Draft replies and wait for the human (hard gate):
  1. Rescan unresolved threads with `gh`; confirm every expected fix is handled with nothing missed.
  2. List the numbered table `# | Thread | Decision | Local change | Draft reply` plus this round's CI/conflict fix summary.
  3. Report state in three lines: Done / Not done / Next.
  4. Before the human approves the replies and says "push": no commit, no push, no comment. The push gate is `git-commit` §3; replies and comments still wait for the human.
- After approval:
  1. Per `git-commit`, commit (stage only this round's changes) and push.
  2. Wait only for real CI checks (poll `statusCheckRollup` or a named check). Never `gh pr checks --watch`: it hangs on approval-gate jobs. A real check failure goes back to local fix and re-ask.
  3. After CI green, reply per thread via `gh` (inline reply / GraphQL `addPullRequestReviewThreadReply`).
  4. Deploy to Dev through the repo's existing workflow/script automatically (no extra ask; ask only when the workflow is unknown), report the result, then return to the loop start.
- Reply rules:
  - Reply only with 100%-verified facts; pending items say "checking the producer repo"; never overpromise or declare done early.
  - Reply once per thread and cover every point; answered threads never get new comments, only edits to the existing reply, unless the reviewer replied again.
  - Accept / fixed: conclusion only, usually 1-5 English words (cap 12), e.g. `Fixed.` / `Done.` / `Out of scope.`; no mechanism, no file/line/numbers, no diff restatement.
  - Reject / not applying: one-sentence conclusion; mark judgment with `IMO` / `I think`; add one reason when needed; end with `WDYT?` only when truly open (see `voice` PR review replies).
  - Never Chinese, apology filler, commit/SHA, or repeated info. Use the `voice` skill for English replies (`voice` includes humanizer); `voice` is SSOT for reply wording, this doc keeps publish and workflow.
  - Publish only via `gh`, never MCP or the web UI; never mark threads resolved yourself.
- Never force-push a shared PR branch; never widen PR scope. Nothing to fix and no unresolved threads: report state and keep watching until Approved (or ask the human whether to nudge the reviewer).
- Merge the PR only on the human's explicit go-ahead, and only by whoever holds merge authority (Hermes, or the human when Hermes is absent); prefer Squash and merge (`git-commit` skill §5).
