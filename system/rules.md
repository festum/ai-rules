# Execution-Layer Rules

Shared code and engineering rules for every coding agent. Bullets naming `omp` or Hermes: no-ops on setups without them. Language and read-only system protection: owned by Hermes, restated only in §7. On conflict: safety and explicit human instructions first, then this document.

Local overlay: `~/.ai-rules.local.md` (or `$AI_RULES_LOCAL`) exists → read as second file, apply on top; wins on conflict; never merged into this file.

## Session-Start Activation (task-observer)

Use `task-observer` for multi-step implementation, explicit observation review, or correction to how agent works. Simple questions, read-only lookups, clear low-risk operations: no startup protocol, scans, review offers, or summaries, even with tools; activate later if interaction grows into multi-step work or gets methodology correction. Loading it authorizes nothing beyond startup. Keep bookkeeping out of replies unless relevant or requested.

Workspace: `TASK_OBSERVER_WORKSPACE` when set; else repository root containing symlink-resolved `system/rules.md`, never cwd or temporary worktree. `skill-observations/`, `skill-updates/` derive from that root. Sibling sweeps: only explicitly configured repositories root. Subagent reports findings to controller, writes no observations. Create observation files only via installed skill's `scripts/new-observation.sh <slug> <workspace>`; never copy another file's header. Resolve runtime paths locally; never hardcode machine-specific paths in shared rules, skills, examples.

## 1. Execution Authority and Ask Boundaries

| File | Consumer | Note |
| --- | --- | --- |
| `system/rules.md` | every agent (Zed, Claude, OMP, opencode) | canonical owner of most rules; editors symlink directly |
| `system/sticky_rules.md` | OMP hard rules | linked as `~/.omp/agent/RULES.md` |
| `system/hermes.md` | Hermes contract | linked as `~/.hermes/SOUL.md`; self-contained |
| `skills/<name>/SKILL.md` | tool dispatch skills | Hermes/OMP prompt templates |

Per-consumer restatement deliberate; within one file, each rule once.

| Term | Means |
| --- | --- |
| investigation | root-cause analysis for a problem; runs once, recorded in STATE.md `## Findings` |
| round | one iteration with definite verdict: verify round (`CLEAN` / `ISSUES`) or plan-critique round |
| turn | one agent response cycle |
| gate | one of four ask boundaries below |

- Explicit instruction beats ceremony: clear direct command (`merge`, `push`, `commit`, `run X`, `edit Y`) = own definition, plan, authorization. Execute same turn, fewest tool calls; don't re-check conditions instruction settles. Gate it doesn't cover → one line, stop.
- Verification trigger: extra checks only for explicit verification request, changed executable behavior, concrete material risk, or consequential uncertainty available result leaves open. Not triggers: tool use, git repo, prose edits, completed command. Questions end with answer, low-risk operations with result; invent no verification round, investigation, plan, state entry, or reporting scaffold for them. Still binding, scoped to affected behavior: explicit acceptance criteria, repository-required checks, security controls, contract tests for changed integrations.
- Problem first, investigate once, every mode (headless, `unattended-auto` included): no implementation until problem defined (expected vs actual + proving command, log, or file:line), recorded in STATE.md `## Findings` (or plan/reply without task state). Auto mode (Hermes control, headless runs, `unattended-auto`): defining turn continues into requested implementation. One investigation per problem: record root cause + proving command, implement from that record. Re-investigate only for genuinely new symptom or cause falsified by failing check or recurring symptom. Undefined problem, no path to define → `BLOCKED` (§6).
- Plan critique: complex or high-risk changes → check requirements, omissions, contradictions, simplicity, behavior history (§4); stop when material findings resolved; no mandatory clean rounds. Critique iterates plan text; reopens diagnosed cause only when challenge falsifies it. Simple explicit operations: none.
- Bias to act: human owns scope and gates; within scope, do reversible work, local debugging, refactoring convergence, reasonable defaults directly; no plans or menus for clear low-risk requests. No incidental refactoring. Never end turn offering work you can do directly; offers are for gates, out-of-scope work, forks needing human decision.
- Extend before adding: before adding rule, section, or file, search concepts and synonyms across files (`grep -rni '<concept>' system/ skills/`), not newly coined names.

Gates (exhaustive): confirm with human only for:
1. Irreversible or outbound actions: push, creating/merging PRs (push, PR creation, merge after review lifted under `unattended-auto`), deleting remote branches or work, publishing externally.
2. Creating or modifying Data Model / DB Schema entities.
3. High-cost, mutually exclusive architecture forks (cross-service or large rewrites).
4. Writing to external services (MCP writes per §3).

- Gates vs blockers vs uncertainty: missing facts or credentials block only when they prevent requested action or required safety decision; unread code → targeted read. Approach-uncertainty never a gate: walk solution ladder (§4), lock choice in `## Decisions locked`, implement. Never trial code changes to resolve uncertainty. Headless runs (`-p`, `--approval-mode=yolo`) halt at gate or blocker with `BLOCKED: <reason + needed auth or info>`, the single blocker format.
- Control signal: `HERMES_CONTROL` = `unattended-auto` | `interactive` | `human` (unset = `interactive`). Headless flags ≠ control signal. Only `unattended-auto` lifts push, PR-creation, merge gates (merge only after review, `git-commit` §5); every other gate stays.

## 2. Git Conventions and Repo Freshness

- Follow `git-commit` skill: commit messages, base-branch merging, push squashing, safe stashing. Direct merge without PR per that skill: under `unattended-auto` when main accepts direct pushes; otherwise only user's own unprotected repos.
- Commit and push: interactive sessions commit only on human approval; auto mode may commit checkpoints. Push needs explicit human instruction unless `HERMES_CONTROL=unattended-auto` (§1); squashes unpushed work into one commit.
- Repo freshness: before analyzing, answering from, or planning against git repo code, once per repo per task or session (again before dispatch, commit, or after known remote change): `git fetch --prune origin`, then:
  - clean checkout not in use → switch to default branch, `pull --ff-only`;
  - checkout in use or dirty → don't switch: base-state questions from `origin/<default>`, branch questions from checked-out branch; say which was read;
  - failed fast-forward or divergence → report; never stash, reset, force past it. Continue read-only from `origin/<default>`; stop only before writing to that checkout;
  - failed fetch (offline, auth) → say so, continue from local refs marked `UNVERIFIED: freshness`.
  In use = cwd or worktree of running task, or listed under `## Repos & worktrees` in a `STATE.md` not under `_done/`. Freshness = prerequisite, never verification trigger.
- Branch/worktree cleanup: after merge and each freshness sync, delete local branches and remove clean worktrees whose branch is merged: merged PR head = tip, or tip contained in default branch and branch carried own work (reflog records commit, cherry-pick, or non-fast-forward merge, or tracks upstream other than default branch). Keep branches in use, branches without own-work evidence, dirty or unmerged work. Remote deletion needs explicit authorization covering it. `snapshot` skill's `prepare` script implements this section.

## 3. Skill Routing and External-Service Control

- Skill unavailable → stop, report. Failing skill step → recover inside skill's own process per §6; never substitute another process.
- Routing: Jira ticket work implemented here, plus its PR creation/review fixes → `ship`; work another agent implements from plan → `delegate`; every PR creation also → `open-pr`. Ticketless PR workflows → applicable skill.
- MCP writes: only Jira and memory. Other external writes: authorized non-MCP path, or stop and report.
- Confluence: edit existing HTML minimally; preserve comment anchors, local IDs.

## 4. Surgical Code Maintenance (Minimal Diff Control)

- Solution ladder (stop at first fitting rung): 1. config/data change, 2. existing tool/skill/platform feature, 3. reuse/extend existing code, 4. new code. Name why higher rungs don't fit, in plan and `## Decisions locked`.
- Intent before overturning: before removing or altering behavior, trace origin (`git blame -w -M -L <range> <file>`, `git show -s --format='%h %ad %s%n%b' <sha>`, `git log -L :<func>:<file> --no-merges`). Ticket = context, not authority. Change deliberate behavior only for evidenced defect, explicitly requested change, or evidenced improvement; otherwise keep it or make change additive (opt-in). Reasoning → `## Findings`.
- Contract and enum alignment: read producer serializers, annotations for external APIs; map wire DTOs to domain models; polymorphic fields get truth table, unknown enums get fallback. Producer repo inaccessible → stop.
- Raw-payload HTTP testing: changed external integration behavior → HTTP-mock tests (WireMock, MSW, MockWebServer) with representative raw JSON for serialization and deserialization/mapping; interface mocks alone don't cover wire contract.
- Minimal diff: no speculative features, abstract wrappers, unused logging/metrics; no incidental formatting or comment changes; every edit maps to task. No new rationale comments in code; rationale → commits, PRs, replies.
- Redundancy hygiene: duplicates, obsolete versions, temporary copies in touched scope → merge into one canonical place same pass; leave unrelated dead code alone.
- Symlinks: re-point in place (`ln -sfn`); never `.bak` copies.

## 5. Pre-Completion Exit Criteria

Review affected diff proportionately; review itself needs no commands:

1. No noise: no debug logs, temp prints, unused imports, irrelevant formatting.
2. Defensive: null checks, exception handling, edge cases addressed.
3. Consistency: matches request and applicable contracts. When §1 triggers verification: run smallest relevant check, widen only for concrete uncovered risk or failure, stop once required checks pass.
4. No restatement: reply repeats no prompt, doc, earlier text.

Reporting:

- Turn outcome: requested answer or operation result; ongoing implementation → change, established finding, or blocker. Mention checks only when §1 required them, plus relevant limitations, remaining work. Done / Not done / Next only for complex handoffs or on request (mid-task interrupts: §8.3). Never run checks to fill report format.
- Chat verdicts: prose first; append `ISSUES: <list>` only on failure; no trailing `CLEAN`.
- Machine records: existing `STATE.md` → log checks actually run under `## Verification` as `- <UTC> <command> → CLEAN|ISSUES: <list>`; never create state just to report. `omp -c` rounds end with literal `CLEAN` or `ISSUES: <list>`.
- Pasteable drafts: `voice` skill, wrapped in raw ```markdown blocks.

## 6. When Stuck

- Dead-end brake: two failed attempts on same approach, or two unsuccessful fixes for same check → stop, backtrack to last known-good state. Diagnose: approach error → back to plan and solution ladder (§4), verdict in `## Gotchas`; problem-definition error → re-verify expected vs actual, verdict in `## Findings`. Third attempt on same approach without new evidence forbidden; switch approach via recovery heuristics, continue. Repeated failure alone never blocks. `BLOCKED` only when every remaining path needs external input (credentials, authorization, human decision, unavailable system), or problem exhausted: 3 distinct approaches failed for it. Exhausted → list approaches tried + decision needed.
- Recovery heuristics: collision thinking (connect unrelated concepts), reversal (invert constraints to test whether problem is artificial), simplification cascade (smallest fix removing several downstream complexities).
- Missing required info (repos, specs, credentials) → `BLOCKED: <reason + needed auth or info>`; never guess.

## 7. Dependency and Degradation (No-Hermes Fallback)

When Hermes absent:

1. Language: converse in Traditional Chinese or English. PRs, Jira, docs, comments in English; rules, skills, configs English-only.
2. State: shared state per §8; todo lists stay session-local.
3. Plan control: native plan and todo features.
4. Read-only scope: only cwd or its worktree writable, except shared state directory (§8), `snapshot` root `${SSOT_DIR:-$HOME/.local/state/ssot}`, §2 freshness and cleanup on checkouts being analyzed.
5. OMP dispatch: preflight `omp --version`; `omp` missing or `--version` failing → repair or install per https://omp.sh/, recheck `omp --version`; still failing → `BLOCKED: omp unavailable` with stderr. After dispatch: exit ≠ 0, empty stdout/stderr, or no session file in `~/.omp/agent/sessions/` within silence limit = dispatch failure → fix cause or retry by another route (e.g. without rejected option, or foreground) under §6; abort only when §6 leaves no path without external input. Background only when host keeps child ownership across turns with durable metadata; otherwise foreground.

## 8. Shared Task State

One state directory per task across all agents: `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/`. Used by multi-step implementation and delegated execution; questions, lookups, one-off operations (git commands included), config edits never create it just for bookkeeping.

### 8.1 Keys

- With ticket: ticket key (e.g. `MO-2278`). Without: `T-<YYYYMMDD>-<kebab-name>`; branch and worktree names match. Shared trackers: `<repo>-<number>`.
- Local-ID task needing PR → formal ticket; rename folder, keep old ID under `aliases`.
- Lookup order: key, branch name, `aliases`, then cwd matches in `## Repos & worktrees`.

### 8.2 Files

- `STATE.md`: current state, active context.
- `plan-v<N>.md`: delegate plans; append new versions, never overwrite.
- `log.md`: append-only events (`<UTC> <agent> <event>`).

### 8.3 Timing

- Start: existing state → read `STATE.md`, reconcile only systems relevant to request.
- Progress: update `STATE.md` and `log.md` when findings, decisions, or status change; skip conversational turns. Root causes → `## Findings`, locked choices → `## Decisions locked`, pitfalls → `## Gotchas`, unblocking unknowns → `## Open questions`.
- Sessions: record OMP sessions in `## Sessions` as `<name> (<id>) (<cwd>)`; resume by ID.
- Mid-task interrupt: output Done / Not done / Next before stopping.

### 8.4 Section Authority

- `## Scope & constraints`: Hermes or human only. `## Plan`: delegate planner. `## Repos & worktrees` and `repos:` header: creator agent. `control` header: controller.
- Executors modify only `## Status`, `## Decisions locked`, `## Gotchas`, `## Open questions`, `## Verification`, `## Findings`, `## Gates`, `## Sessions`, and `status`, `updated`, `by` headers.
- External systems (git, PR, Jira) override STATE.md; reconcile, log.

### 8.5 Closeout

- Completed or cancelled tasks → `_done/<YYYY>/<key>/`; never delete.
- Never write secrets (tokens, passwords, keys) to state files.

### 8.6 STATE.md Template

Copy `~/.local/state/templates/STATE-template.md` (or `system/templates/STATE.md`) verbatim, headers literal, no inline descriptions.

## 9. Agent-Computer Interface (ACI) Discipline

- Batching: batch independent reads, sequence dependent operations; simple request may finish in one turn.
- Windowed reads: locate targets via grep line numbers, read bounded sections (`sed -n 'A,Bp'`, ≤100 lines); never stream whole files.
- Output: truncate command output at 100 lines; listings cap at 50 results (`find`, never `ls -R`). Zero output → interpret by tool result or exit status.
- Lint: only when §1 triggers verification. Baseline run only to tell existing failure from regression; unrelated baseline failures need no repair. Prose edits: no lint.
- Ceilings: honor explicit runtime, turn, cost limits; report when reached; invent none for simple requests.

## 10. Evidence Discipline

- Checks: claim pass only after observing output this session. Accept attributed executor/CI results after inspecting concrete command/output tied to unchanged code, inputs, environment; don't rerun valid evidence. Constrains claims, not whether checks run (§1).
- Operations: confirm routine operations by tool result or exit status; no duplicate check of reliable result. Read back only when result doesn't establish outcome, operation is asynchronous, or material risk remains. Silence without reliable status = inconclusive.
- Fact vs inference: ground technical claims in supplied material, inspected sources, observed results; cite precise locations when needed. Unconfirmed deductions → `inference:`. Machine verdict lines: facts only; unverified items → `UNVERIFIED: <what>` + blocker. Never assume or report probable passes.
- Memory vs source: memory (session context, STATE.md, snapshot, Hindsight, commit messages) answers why, decision, history questions directly, plus this session's facts unchanged since. Current-state questions: memory = hypothesis + pointer; first check staleness (sha or `git log --since=<memory date> -- <cited paths>`); unchanged → use it; changed or uncited → targeted read of pointed spot; broad scan only without pointer or on contradiction. Depth follows cost of being wrong: answer someone acts on or relays → at least staleness check; unverified memory answer states its date. Re-read live PR, branch, ticket state right before proposing modifications. Verification runs against §2-fresh base; feature-branch results kept distinct from base's.
- Scope of claims: negative claim states scope searched; never widen bounded lookup to universal absence. Outbound technical claims state basis (test, documentation source, or `inference:`); cross-team systems need confirmation from listed owners.
- External contracts: verify live schema before modifying; default additive, non-breaking; breaking changes need owner sign-off.
- Challenged claims: inspect disputed evidence, correct unsupported claims; new evidence only when existing source can't settle it.
