# OMP Execution-Layer Rules

Code and engineering rules for the OMP execution layer. Language settings, the STATE.md contract, GSD phase control, and read-only system protection are owned by the Hermes system layer and are not repeated here; see §7 for fallbacks when Hermes is absent.

When rules conflict, safety and explicit human instructions take priority, then this document.

## 1. Execution Authority and Ask Boundaries

- Default YOLO: implement in-scope work, local debugging, refactoring convergence, and reasonable defaults directly, without a menu prompt. Refactoring is limited to the current task's scope; no incidental refactoring.
- Mandatory ask boundary (Hard Ask Boundary): pause and confirm with a human only in these cases:
  1. Irreversible or outbound actions: push, creating or merging PRs, deleting others' branches or remote work, publishing externally.
  2. Creating or modifying a Data Model / DB Schema entity.
  3. A high-cost, mutually exclusive architecture fork (spanning multiple services, or requiring a large rewrite, with mutually exclusive alternatives).
  4. Writing to an external service (MCP writes are covered in §3).
- Outside those four cases, when information is missing, the spec is contradictory, or the work cannot be verified: take the conservative default. Stop and report; do not self-approve.
- Headless runs (`-p` / `--approval-mode=yolo`) have no interactive prompt. On an ask boundary, stop and emit `BLOCKED: <reason>` plus the authorization needed, and hand off to the upper layer or a human.
- No Hermes: the default YOLO does not apply, and the ask boundary above applies to every action rather than only the four listed cases. Plan before executing; ask questions via a selectable menu.

## 2. Git Conventions and Main-Branch Sync

- Commit conventions: follow Conventional Commits; subject (description) ≤18 words; no `Co-Authored-By`.
- Push boundary: after implementing and verifying, wait for an explicit human "push" before committing and pushing.
- Squash on push: at push time, squash all not-yet-pushed commits (everything ahead of the upstream branch, or ahead of main before the first push) into a single commit with a Conventional Commits message. Never rewrite commits that are already pushed.
- Conflict resolution: when merging main, resolve conflicts in favor of this branch's changes.
- Re-check after main merge: after every pull or merge of main, re-compare against the codebase to see whether newly merged main changes add reusable tools or modules, or change the spec in ways that need matching adjustments.

## 3. Skill Routing and External-Service Control

- Mandatory Jira routing: any work on Jira tickets, related PR creation, or review-comment fixes must invoke and follow the jira-do skill. If the skill is unavailable, stop and report; do not substitute another process.
- Mandatory PR routing: creating a PR always requires invoking and following the creating-pr skill, on top of any task-level skill (e.g. jira-do). If the skill is unavailable, stop and report; do not create the PR another way.
- MCP write restriction: never write to external services through MCP. The only exceptions are Jira (via jira-actions) and memory (Hindsight/Memory) updates. Route all other writes through a non-MCP path; if none exists, stop and report.
- Confluence editing: never rewrite a whole page. Edit the existing structure in HTML, minimally and targeted, preserving inline comment anchors and local IDs. If no non-MCP write path exists, stop and report.

## 4. Surgical Code Maintenance (Minimal Diff Control)

- Contract and enum alignment: for cross-service or external APIs, check the Producer Code's serializers and annotations; never guess enums or JSON fields. Isolate Wire DTOs from Domain enums through a conversion layer. Produce a Truth Table for polymorphic fields, and include a defensive fallback for unknown enum values. If the Producer repo is inaccessible, stop and report; do not guess from internal constant names.
- Raw-payload HTTP testing: for external communication, do not test only with client or interface mocks. Use an HTTP-level mock (e.g. WireMock, MSW, MockWebServer) with real raw JSON response bodies to validate deserialization.
- Zero speculative code: do not add unrequested features, placeholder interfaces, kitchen-sink options, or unnecessary Log/Metrics/Tracing abstraction layers.
- Minimal diff: do not incidentally change nearby formatting, comments, or unrelated logic. Every changed line must trace to this task's request. Clean up orphaned code only when this change invalidates it; do not delete pre-existing dead code on your own.

## 5. Pre-Completion Exit Criteria

Before final confirmation, review the git diff (staged and unstaged) and confirm all three checks:
1. No noise: no debug prints, temporary logs, unrelated formatting, or unused imports.
2. Defensive: null/empty checks, network and exception handling, and boundary conditions are all present.
3. Consistency: the logic matches the Truth Table and the Jira or task spec exactly, and the project's lint and test commands pass in full.

Reporting contract: end each verification round with a single line, `CLEAN` or `ISSUES: <list>`. When delivering results or a PR, use three lines: Done / Not done / Next.

## 6. When Stuck

1. Collision thinking: deliberately connect unrelated concepts to find an entry point.
2. Reversal: flip the existing constraints and check whether the problem is a false one.
3. Simplification cascade: find the smallest entry point that removes several complexities at once.

If you still cannot make progress, or lack required information (Producer repo, spec, credentials), stop and report; do not guess and continue.

## 7. Dependency and Degradation (No-Hermes Fallback)

This document assumes the Hermes system layer exists. When Hermes is absent, use these minimal substitutes for the items it covers:
1. Language settings: converse in Traditional Chinese or English; use English for PRs, Jira, docs, and comments unless told otherwise.
2. STATE.md contract: without STATE.md, git status and the todo list are the single source of truth for state.
3. GSD phase control: without GSD, use the built-in plan and todo for breakdown and tracking.
4. Read-only system protection: without Hermes, only the current working directory or its worktree is writable; any path outside the plan is read-only.
5. OMP liveness: preflight `omp --version`; capture exit code + stderr (stdout may stay empty). Exit ≠ 0, empty result, or no new session file under `~/.omp/agent/sessions/` ⇒ OMP did not run; silence ≠ running. Never wait `--max-time` out on a silent dispatch. Background only when the host owns the child across turns and writes a durable record; else run foreground — never hand-roll `nohup` + poll.

Execution authority is covered in §1.
