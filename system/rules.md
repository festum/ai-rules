# Execution-Layer Rules

Shared code and engineering rules for every coding agent. Bullets calling out `omp` or Hermes are no-ops on setups without those tools. Language settings and read-only system protection are owned by Hermes and not restated outside §7. When rules conflict, safety and explicit human instructions take priority, then this document.

Local overlay: if `~/.ai-rules.local.md` (or `$AI_RULES_LOCAL`) exists, read it as a second file and apply it on top of this document; it wins on conflict. It is never merged into this file.

## Session-Start Activation (task-observer)

Use `task-observer` for multi-step implementation, an explicit observation review, or a correction to how the agent works. Its local activation policy controls startup only; loading it does not authorize verification, installation, migration, or unrelated maintenance. Simple questions, read-only lookups, and clear low-risk operations do not trigger its startup protocol, scans, review offers, or observation summaries, even when tools are used. If a skipped interaction develops into multi-step work or receives a methodology correction, activate it then. Keep bookkeeping out of the reply unless relevant or requested.

Resolve the task-observer workspace from `TASK_OBSERVER_WORKSPACE` when configured; otherwise resolve the loaded rules file through its symlink and use the repository root containing `system/rules.md`, not the cwd or a temporary worktree. Derive `skill-observations/observation-log/`, `skill-observations/cross-cutting-principles.md`, and `skill-updates/` from that root. Sibling sweeps use only an explicitly configured repositories root; do not assume a home-directory layout. A subagent reports findings to its controller without running startup or writing observations. Create observation files only through the installed skill's `scripts/new-observation.sh`, passing the resolved workspace as its second argument; never copy another file's header. Resolve runtime paths locally; do not hardcode machine-specific paths in shared rules, skills, or examples.

## 1. Execution Authority and Ask Boundaries

- Explicit instruction beats ceremony: a clear direct human command (`merge`, `push`, `commit`, `run X`, `edit Y`) is itself the definition, plan, and authorization — execute it in the same turn with the fewest tool calls. Problem-first, plan critique, fresh-state re-reads, and investigation guard against ambiguity; they do not apply to an unambiguous command, and conditions the instruction already satisfies are not re-checked. A gate the instruction does not cover → one line, then stop.
- Verification trigger: run additional checks only when the user requests verification, executable behavior changes, a concrete material risk needs testing, or the available result leaves a consequential uncertainty. Tool use, being in a git repo, editing prose, or completing a command is not itself a trigger. Questions and lookups end with the answer; clear low-risk operations end with their direct result. Do not invent a verification round, investigation, plan, state entry, or reporting scaffold for them. This limits automatic workflow ceremony, not explicit acceptance criteria, repository-required checks, security controls, or contract tests for changed integrations. Those requirements remain binding; scope them to the affected behavior.
- Problem first: no implementation turn until the problem is defined (expected vs actual + command, log, or file:line proof). Record in STATE.md `## Findings` (or in plan/reply if no state folder). Applies across interactive, headless (`-p` / `--approval-mode=yolo`), and `unattended-auto`. Undefined problem with no path to define it → `BLOCKED` per §6.
- Default YOLO (prompt scope only): implement in-scope, reversible work, local debugging, refactoring convergence, and reasonable defaults directly without menu prompts. Incidental refactoring forbidden. Never end a turn with an offer for work you can do directly; offers are reserved for gates, out-of-scope tasks, or forks needing human decisions.
- Investigate once, then implement: one investigation per problem. Record root cause and proving command in `## Findings`, then implement. Re-investigate only when: (a) a genuinely new symptom appears, or (b) the recorded cause is falsified by a failing check or recurring symptom. Stop per §6 if information is missing.
- Plan critique is not investigation: plan-critique loops iterate plan text without re-opening diagnosed root causes. Challenged claims re-open investigation only if they falsify the recorded cause.
- Turn outcome: deliver the requested answer or operation result; for ongoing implementation, report the change, established finding, or blocker. Include verification results only when §5 requires checks. Do not run checks merely to satisfy an outcome format.
- Extend before adding: check whether an existing rule, section, or file covers the ground before adding new ones. Search concepts and synonyms across files (`grep -rni '<concept>' system/ skills/`), not newly coined names.

| File | Consumer | Note |
| --- | --- | --- |
| `system/rules.md` | every agent (Zed, Claude, OMP, opencode) | canonical owner of most rules; editors symlink directly |
| `system/sticky_rules.md` | OMP hard rules | linked as `~/.omp/agent/RULES.md` |
| `system/hermes.md` | Hermes contract | linked as `~/.hermes/SOUL.md`; self-contained |
| `skills/<name>/SKILL.md` | tool dispatch skills | Hermes/OMP prompt templates |

Per-consumer restatement is deliberate. Concept vocabulary:

| Term | Means |
| --- | --- |
| investigation | root-cause analysis for a problem; runs once, recorded in STATE.md `## Findings` |
| round | one iteration with a definite verdict: verify round (`CLEAN` / `ISSUES`) or plan-critique round |
| turn | one agent response cycle |
| gate | one of four ask-boundary cases requiring human authorization |

- Mandatory ask boundary (Hard Ask Boundary): confirm with human only for:
1. Irreversible or outbound actions: push (except under `unattended-auto`), creating/merging PRs, deleting remote branches/work, publishing externally.
2. Creating or modifying Data Model / DB Schema entities.
3. High-cost, mutually exclusive architecture forks (cross-service or large rewrites).
4. Writing to external services (MCP writes governed by §3).

- Gates vs blockers vs approach-uncertainty: the four cases above are exhaustive gates. Missing facts or credentials are blockers only when they prevent the requested action or a required safety decision; unread code is normally a reason for a targeted read, not an automatic blocker (`BLOCKED: <missing info + needed auth>`). Approach-uncertainty is resolved internally: walk the solution ladder (§4), lock the decision in `## Decisions locked`, and implement. Never try code changes to resolve uncertainty.
- Headless runs (`-p` / `--approval-mode=yolo`): emit `BLOCKED: <reason + needed auth>` at ask boundaries and halt.
- No Hermes fallback: the human owns scope and gates; agents may execute in-scope, reversible work directly. The same four ask boundaries apply. Do not require plans or confirmation menus for clear low-risk requests.
- Control signal: declared via `HERMES_CONTROL` (`unattended-auto` | `interactive` | `human`; unset = `interactive`). Headless flags (`-p`, `--auto-approve`, `--approval-mode=yolo`) are not the control signal. Only `unattended-auto` lifts the push gate; merge and every other boundary stay gated.
- Plan critique: for complex or high-risk changes, check requirements, omissions, contradictions, simplicity, and behavior history (§4). Stop when material findings are resolved; no mandatory clean rounds. Simple explicit operations need no separate plan critique.

## 2. Git Conventions and Base-Branch Sync

- Follow `git-commit` skill for commit messages, base-branch merging, push squashing, and safe stashing. Direct merge without PR permitted only on unprotected self-owned repos per skill conditions.
- Commit boundary: interactive sessions wait for human approval before committing; auto mode may commit checkpoints. Push requires explicit human instruction and must squash unpushed work into one commit.
- Branch/worktree cleanup: after a merge, remove only merged local branches and clean task worktrees; preserve uncommitted or unmerged work. Remote deletion needs explicit authorization covering that deletion. Finishing local work alone does not authorize deleting branches or worktrees.

## 3. Skill Routing and External-Service Control

- Skill unavailable or failing: stop and report; never substitute another process.
- Jira routing: Jira ticket work and related PR creation/review fixes use `ship`; plan-only work uses `delegate`. Ticketless PR workflows use their applicable skill, with `open-pr` required for creation.
- PR routing: creating PRs requires `open-pr` skill alongside task skills.
- MCP write restriction: write access via MCP is strictly limited to Jira and memory updates. All other external writes must use non-MCP paths or stop and report.
- Confluence: edit existing HTML minimally without rewriting pages. Preserve comment anchors and local IDs.

## 4. Surgical Code Maintenance (Minimal Diff Control)

- Solution ladder (stop at first fitting rung): 1. config/data change, 2. existing tool/skill/platform feature, 3. reuse/extend existing code, 4. new code as last resort. Name higher-rung exclusions in plan and `## Decisions locked`.
- Intent before overturning: before removing or altering existing behavior, trace its origin using bounded history commands (`git blame -w -M -L <range> <file>`, `git show -s --format='%h %ad %s%n%b' <sha>`, `git log -L :<func>:<file> --no-merges`). A ticket is context, not authority. Change deliberate behavior only to fix an evidenced defect, satisfy an explicit requested behavior change, or deliver an evidenced improvement; otherwise keep it or make the change additive (opt-in). Document reasoning in `## Findings`.
- Contract and enum alignment: inspect producer code serializers and annotations directly for external APIs. Decouple wire DTOs from domain models via a mapping layer. Provide truth tables for polymorphic fields and fallbacks for unknown enums. Stop if producer repo is inaccessible.
- Raw-payload HTTP testing: when changing external integration behavior, use HTTP mocks (WireMock, MSW, MockWebServer) with representative raw JSON to validate request serialization and response deserialization/mapping, as applicable; interface mocks alone do not cover the wire contract.
- Zero speculative code: no unrequested features, abstract wrappers, or unused logging/metric layers.
- Redundancy hygiene: merge duplicate definitions, obsolete versions, or temporary copies in touched scope into one canonical location during the same pass. Do not touch unrelated dead code outside task scope.
- Minimal diff: no incidental formatting or comment changes. Every edit must map directly to the task.
- Symlinks: re-point in place (`ln -sfn`). Never create `.bak` files for symlinks.
- Code comments: no new rationale comments in code. Place rationale in commit messages, PRs, or direct replies.

## 5. Pre-Completion Exit Criteria

For changes, review the affected diff proportionately; this review does not itself require commands:

1. No noise: clean of debug logs, temp prints, unused imports, or irrelevant formatting.
2. Defensive: null checks, exception handling, and edge cases addressed.
3. Consistency: matches the request and applicable contracts. When §1 triggers verification, run the smallest relevant lint/test/check; expand only for a concrete uncovered risk or failure, not automatically to the full suite. Stop when the identified risk is covered and required checks pass; no extra clean round.
4. No restatement: reply contains no repeated prompts, docs, or preceding text.

Reporting contract:

- Machine record: when a task already has `STATE.md`, log checks actually run under `## Verification` as `- <UTC> <command> → CLEAN|ISSUES: <list>`. Do not create state or a self-check trace just to report completion.
- Machine outputs: `omp -c` loop rounds must terminate with literal `CLEAN` or `ISSUES: <list>`.
- Chat replies: state prose verdict first; append `ISSUES: <list>` only on failure; omit trailing `CLEAN`.
- Task delivery: give a concise result; mention checks run, relevant limitations, and remaining work only when applicable. Use Done / Not done / Next for complex handoffs or when requested, not routine replies.
- Pasteable drafts: invoke `voice` skill and wrap in raw ```markdown code blocks.

## 6. When Stuck

- Dead-end brake: after two failed attempts on the same approach, stop and backtrack to last known-good state. Diagnose failure: (a) approach error → return to plan and solution ladder (§4); (b) problem definition error → re-verify expected vs actual evidence. Record verdict in `## Gotchas` (approach) or `## Findings` (definition). A third attempt without new evidence is forbidden.
- Recovery heuristics:
1. Collision thinking: connect unrelated concepts for new angles.
2. Reversal: invert constraints to test if the problem is artificial.
3. Simplification cascade: find the smallest fix that eliminates multiple downstream complexities.

- Missing required info (repos, specs, credentials) → stop and emit `BLOCKED`; do not guess.

## 7. Dependency and Degradation (No-Hermes Fallback)

When Hermes is absent, enforce these local defaults:

1. Language: conversational Traditional Chinese or English. PRs, Jira, docs, and comments in English. Rules, skills, and configs remain English-only.
2. State: maintain shared state per §8; todo lists remain session-local.
3. Plan control: use editor/agent native plan and todo features.
4. Read-only scope: only current working directory or worktree is writable; external paths are read-only.
5. OMP dispatch: preflight `omp --version`. Exit ≠ 0, empty stdout/stderr, or no session file in `~/.omp/agent/sessions/` within silence limit indicates dispatch failure; abort immediately. Use background execution only if host retains child ownership across turns with durable metadata; otherwise execute foreground.

## 8. Shared Task State

Single state directory per task across all agents: `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/`

### 8.1 Keys

- With ticket: ticket key (e.g. `MO-2278`).
- Git task without ticket: `T-<YYYYMMDD>-<kebab-name>`. Branch and worktree names match this key.
- Shared trackers: `<repo>-<number>`.
- Tasks requiring PRs from local IDs: obtain formal ticket, rename folder to ticket ID, and record previous ID under `aliases`.
- Questions, lookups, clear one-off operations (including git commands), and config edits: do not create state folders solely for bookkeeping. Multi-step implementation and delegated execution use shared task state.
- Search precedence: key, branch name, `aliases`, then cwd matches in `## Repos & worktrees`.

### 8.2 Files

- `STATE.md`: current state and active context.
- `plan-v<N>.md`: delegate plans; append new versions, do not overwrite.
- `log.md`: append-only event log (`<UTC> <agent> <event>`).

### 8.3 Timing

- Start: for a task with existing shared state, read `STATE.md` and reconcile only the systems relevant to the request. Simple questions and operations do not trigger state reconciliation.
- Sessions: record OMP sessions in `## Sessions` as `<name> (<id>) (<cwd>)`; resume via ID.
- Task progress: update existing `STATE.md` and `log.md` when findings, decisions, or task status change; skip conversational turns and unchanged status. Record identified root causes in `## Findings`.
- Incremental updates: write locked choices to `## Decisions locked`, unexpected pitfalls to `## Gotchas`, and unblocking unknowns to `## Open questions`.
- Mid-task interrupt: output Done / Not done / Next before stopping.

### 8.4 Section Authority

- `## Scope & constraints`: modified by Hermes or human only.
- `## Plan`: modified by delegate planner.
- `## Repos & worktrees` / `repos:` header: set by creator agent.
- Executors modify only: `## Status`, `## Decisions locked`, `## Gotchas`, `## Open questions`, `## Verification`, `## Findings`, `## Gates`, `## Sessions`, and headers (`status`, `updated`, `by`). `control` header is controller-owned.
- Conflict: external system (git, PR, Jira) overrides STATE.md. Reconcile and log.

### 8.5 Closeout

- Move completed/cancelled tasks to `_done/<YYYY>/<key>/`. Do not delete.
- Never write secrets (tokens, passwords, keys) to state files.

### 8.6 STATE.md Template

Copy `~/.ai-rules/STATE-template.md` (or resolve via `system/templates/STATE.md`) verbatim. Copy headers literally without inline descriptions.

## 9. Agent-Computer Interface (ACI) Discipline

- Tool batching: keep actions focused, batch independent reads, and sequence dependent operations. A simple request may finish in one turn; tool-call count is not a reason to create more turns.
- Windowed reads: locate targets via grep line numbers, then read bounded sections (`sed -n 'A,Bp'`, ≤100 lines). Never stream entire files.
- Output boundary: truncate command output at 100 lines. Interpret zero output using the tool result or exit status; follow up only if consequential uncertainty remains.
- Lint scope: run relevant lint/format checks only when §1 triggers verification. A baseline check is needed only to distinguish an existing failure from a regression; unrelated baseline failures do not require repair.
- Edit loop brake: after two unsuccessful fixes for the same check, stop and diagnose before another edit. Editing a prose file does not require lint to continue.
- Search cap: file listing commands must cap at 50 results (`find`, avoid `ls -R`).
- Ceilings: honor explicit runtime, turn, and cost limits; report when a configured limit is reached. Do not invent a budget or bookkeeping task for a simple request.

## 10. Evidence Discipline

- Check evidence: claim a personally run check passed only after observing its output this session. Attributed executor/CI results may be accepted after inspecting concrete command/output tied to unchanged code, inputs, and relevant environment. This constrains claims, not whether checks must run; use §1 to decide. Do not duplicate valid evidence merely because it came from another session.
- Operation results: use the tool's success/error result or command exit status to confirm routine operations. Silence without a reliable status is inconclusive; query again only if consequential uncertainty remains.
- Fact vs inference: ground technical claims in supplied material, inspected sources, or observed results; cite precise locations when needed to assess a finding. Mark unconfirmed deductions as `inference:` in prose. Machine verdict lines contain facts only; unverified items must use `UNVERIFIED: <what>`.
- No memory claims: past session logs do not prove current system state. If current state matters to the request, inspect the relevant source; do not rerun checks for an explanation of supplied material.
- Baseline code verification: only after §1 establishes a need for verification in a git repo, pull main (or the default branch) first using a fast-forward-only update in its checkout. Preserve dirty work; stop on conflicts or divergence rather than resetting, stashing, or switching branches blindly. On a feature branch, distinguish its results from the updated base. Syncing main is a prerequisite for verification, never a reason to start it.
- Unknowns: report unverified items as `UNVERIFIED: <what>` with blocker details. Never assume or report probable passes.
- Negative claims: state the scope actually searched. Do not turn a bounded lookup into an unbounded search to claim universal absence.
- Outbound claims: technical statements to humans must specify basis (test, documentation source, or `inference:`). Cross-team systems require confirmation from listed owners.
- External contracts: verify live contract schema before introducing modifications. Default to additive, non-breaking changes; a breaking change needs owner sign-off.
- Action verification: do not duplicate a reliable operation result with a separate check. Read back only when the result does not establish the required outcome, the operation is asynchronous, or a material risk remains.
- Challenged claims: inspect the disputed evidence and correct unsupported claims. Gather new evidence only if the existing source cannot settle the dispute; disagreement alone does not require a test loop.
- Fresh state inspection: re-read live PR, branch, or ticket state immediately before proposing modifications.
