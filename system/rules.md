# Execution-Layer Rules

Shared code and engineering rules for every coding agent. Bullets naming `omp` or Hermes are no-ops on setups without them. Language and read-only system protection are owned by Hermes and restated only in §7. On conflict: safety and explicit human instructions first, then this document.

Local overlay: if `~/.ai-rules.local.md` (or `$AI_RULES_LOCAL`) exists, read it as a second file and apply it on top; it wins on conflict and is never merged into this file.

## Session-Start Activation (task-observer)

Use `task-observer` for multi-step implementation, an explicit observation review, or a correction to how the agent works. Simple questions, read-only lookups, and clear low-risk operations do not trigger its startup protocol, scans, review offers, or summaries, even when tools are used; activate it later if the interaction grows into multi-step work or receives a methodology correction. Loading it authorizes nothing beyond its startup. Keep bookkeeping out of replies unless relevant or requested.

Workspace: `TASK_OBSERVER_WORKSPACE` when set; otherwise the repository root containing the symlink-resolved `system/rules.md`, never the cwd or a temporary worktree. `skill-observations/` and `skill-updates/` derive from that root. Sibling sweeps use only an explicitly configured repositories root. A subagent reports findings to its controller and writes no observations. Create observation files only with the installed skill's `scripts/new-observation.sh <slug> <workspace>`; never copy another file's header. Resolve runtime paths locally; never hardcode machine-specific paths in shared rules, skills, or examples.

## 1. Execution Authority and Ask Boundaries

| File | Consumer | Note |
| --- | --- | --- |
| `system/rules.md` | every agent (Zed, Claude, OMP, opencode) | canonical owner of most rules; editors symlink directly |
| `system/sticky_rules.md` | OMP hard rules | linked as `~/.omp/agent/RULES.md` |
| `system/hermes.md` | Hermes contract | linked as `~/.hermes/SOUL.md`; self-contained |
| `skills/<name>/SKILL.md` | tool dispatch skills | Hermes/OMP prompt templates |

Per-consumer restatement is deliberate; within one file, say each rule once.

| Term | Means |
| --- | --- |
| investigation | root-cause analysis for a problem; runs once, recorded in STATE.md `## Findings` |
| round | one iteration with a definite verdict: verify round (`CLEAN` / `ISSUES`) or plan-critique round |
| turn | one agent response cycle |
| gate | one of the four ask boundaries below |

- Explicit instruction beats ceremony: a clear direct command (`merge`, `push`, `commit`, `run X`, `edit Y`) is its own definition, plan, and authorization. Execute it in the same turn with the fewest tool calls; do not re-check conditions the instruction already settles. A gate it does not cover → one line, then stop.
- Verification trigger: run additional checks only for an explicit verification request, changed executable behavior, a concrete material risk, or a consequential uncertainty the available result leaves open. Tool use, a git repo, prose edits, or a completed command are not triggers. Questions end with the answer and low-risk operations with their result; invent no verification round, investigation, plan, state entry, or reporting scaffold for them. Explicit acceptance criteria, repository-required checks, security controls, and contract tests for changed integrations stay binding, scoped to the affected behavior.
- Problem first, investigate once: no implementation turn until the problem is defined (expected vs actual plus a proving command, log, or file:line), recorded in STATE.md `## Findings` (or the plan/reply without task state). This holds in every mode, headless and `unattended-auto` included. One investigation per problem: record the root cause and its proving command, then implement from that record. Re-investigate only for a genuinely new symptom or a cause falsified by a failing check or recurring symptom. Undefined problem with no path to define it → `BLOCKED` (§6).
- Plan critique: for complex or high-risk changes, check requirements, omissions, contradictions, simplicity, and behavior history (§4); stop when material findings are resolved, with no mandatory clean rounds. Critique iterates plan text and reopens a diagnosed cause only when a challenge falsifies it. Simple explicit operations need none.
- Bias to act: the human owns scope and gates; within scope, do reversible work, local debugging, refactoring convergence, and reasonable defaults directly, without plans or menus for clear low-risk requests. No incidental refactoring. Never end a turn offering work you can do directly; offers are for gates, out-of-scope work, or forks needing a human decision.
- Extend before adding: before adding a rule, section, or file, search concepts and synonyms across files (`grep -rni '<concept>' system/ skills/`), not newly coined names.

Gates (exhaustive) — confirm with the human only for:
1. Irreversible or outbound actions: push (except under `unattended-auto`), creating/merging PRs, deleting remote branches or work, publishing externally.
2. Creating or modifying Data Model / DB Schema entities.
3. High-cost, mutually exclusive architecture forks (cross-service or large rewrites).
4. Writing to external services (MCP writes per §3).

- Gates vs blockers vs uncertainty: missing facts or credentials block only when they prevent the requested action or a required safety decision; unread code calls for a targeted read. Approach-uncertainty is never a gate: walk the solution ladder (§4), lock the choice in `## Decisions locked`, implement. Never trial code changes to resolve uncertainty. Headless runs (`-p`, `--approval-mode=yolo`) halt at a gate or blocker with `BLOCKED: <reason + needed auth or info>`, the single blocker format.
- Control signal: `HERMES_CONTROL` = `unattended-auto` | `interactive` | `human` (unset = `interactive`). Headless flags are not the control signal. Only `unattended-auto` lifts the push gate; merge and every other gate stay.

## 2. Git Conventions and Repo Freshness

- Follow the `git-commit` skill for commit messages, base-branch merging, push squashing, and safe stashing. Direct merge without a PR only on unprotected self-owned repos per that skill.
- Commit and push: interactive sessions commit only on human approval; auto mode may commit checkpoints. Push needs an explicit human instruction unless `HERMES_CONTROL=unattended-auto` (§1), and squashes unpushed work into one commit.
- Repo freshness: before analyzing, answering from, or planning against a git repo's code, once per repo per task or session (again before dispatch, commit, or after a known remote change), `git fetch --prune origin`, then:
  - a clean checkout not in use → switch to the default branch and `pull --ff-only`;
  - a checkout in use or dirty → do not switch: answer base-state questions from `origin/<default>` and branch questions from the checked-out branch, saying which one you read;
  - a failed fast-forward or divergence → stop and report; never stash, reset, or force past it;
  - a failed fetch (offline, auth) → say so and continue from local refs, marked `UNVERIFIED: freshness`.
  In use = the cwd or worktree of a running task, or listed under `## Repos & worktrees` in a `STATE.md` not under `_done/`. Freshness is a prerequisite, never a trigger for verification.
- Branch/worktree cleanup: after a merge and during each freshness sync, delete local branches and remove clean worktrees whose branch is merged: a merged PR head equals the tip, or the tip is contained in the default branch and the branch carried its own work (its reflog records a commit, cherry-pick, or non-fast-forward merge, or it tracks an upstream other than the default branch). Keep branches in use, branches with no own-work evidence, and dirty or unmerged work. Remote deletion needs explicit authorization covering it. The `snapshot` skill's `prepare` script implements this section.

## 3. Skill Routing and External-Service Control

- Skill unavailable or failing: stop and report; never substitute another process.
- Routing: Jira ticket work and its PR creation/review fixes use `ship`; plan-only work uses `delegate`; every PR creation also uses `open-pr`. Ticketless PR workflows use their applicable skill.
- MCP writes: only Jira and memory. Other external writes use an authorized non-MCP path or stop and report.
- Confluence: edit existing HTML minimally; preserve comment anchors and local IDs.

## 4. Surgical Code Maintenance (Minimal Diff Control)

- Solution ladder (stop at the first fitting rung): 1. config/data change, 2. existing tool/skill/platform feature, 3. reuse/extend existing code, 4. new code. Name why higher rungs do not fit in the plan and `## Decisions locked`.
- Intent before overturning: before removing or altering behavior, trace its origin (`git blame -w -M -L <range> <file>`, `git show -s --format='%h %ad %s%n%b' <sha>`, `git log -L :<func>:<file> --no-merges`). A ticket is context, not authority. Change deliberate behavior only for an evidenced defect, an explicitly requested change, or an evidenced improvement; otherwise keep it or make the change additive (opt-in). Record the reasoning in `## Findings`.
- Contract and enum alignment: read producer serializers and annotations for external APIs; map wire DTOs to domain models; give polymorphic fields a truth table and unknown enums a fallback. Producer repo inaccessible → stop.
- Raw-payload HTTP testing: changed external integration behavior gets HTTP-mock tests (WireMock, MSW, MockWebServer) with representative raw JSON for serialization and deserialization/mapping; interface mocks alone do not cover the wire contract.
- Minimal diff: no speculative features, abstract wrappers, or unused logging/metrics; no incidental formatting or comment changes; every edit maps to the task. No new rationale comments in code; rationale goes in commits, PRs, or replies.
- Redundancy hygiene: merge duplicates, obsolete versions, or temporary copies in touched scope into one canonical place in the same pass; leave unrelated dead code alone.
- Symlinks: re-point in place (`ln -sfn`); never create `.bak` copies.

## 5. Pre-Completion Exit Criteria

Review the affected diff proportionately; the review itself needs no commands:

1. No noise: no debug logs, temp prints, unused imports, or irrelevant formatting.
2. Defensive: null checks, exception handling, and edge cases addressed.
3. Consistency: matches the request and applicable contracts. When §1 triggers verification, run the smallest relevant check, widen only for a concrete uncovered risk or failure, and stop once required checks pass.
4. No restatement: the reply repeats no prompt, doc, or earlier text.

Reporting:

- Turn outcome: deliver the requested answer or operation result; for ongoing implementation, the change, established finding, or blocker. Mention checks only when §1 required them, plus relevant limitations and remaining work. Done / Not done / Next only for complex handoffs or on request (mid-task interrupts: §8.3). Never run checks to fill a report format.
- Chat verdicts: prose first; append `ISSUES: <list>` only on failure; no trailing `CLEAN`.
- Machine records: with an existing `STATE.md`, log checks actually run under `## Verification` as `- <UTC> <command> → CLEAN|ISSUES: <list>`; never create state just to report. `omp -c` rounds end with literal `CLEAN` or `ISSUES: <list>`.
- Pasteable drafts: use the `voice` skill and wrap in raw ```markdown blocks.

## 6. When Stuck

- Dead-end brake: two failed attempts on the same approach, or two unsuccessful fixes for the same check → stop and backtrack to the last known-good state. Diagnose: approach error → back to the plan and solution ladder (§4), verdict in `## Gotchas`; problem-definition error → re-verify expected vs actual, verdict in `## Findings`. A third attempt without new evidence is forbidden.
- Recovery heuristics: collision thinking (connect unrelated concepts), reversal (invert constraints to test whether the problem is artificial), simplification cascade (the smallest fix removing several downstream complexities).
- Missing required info (repos, specs, credentials) → `BLOCKED: <reason + needed auth or info>`; never guess.

## 7. Dependency and Degradation (No-Hermes Fallback)

When Hermes is absent:

1. Language: converse in Traditional Chinese or English. PRs, Jira, docs, and comments in English; rules, skills, and configs English-only.
2. State: shared state per §8; todo lists stay session-local.
3. Plan control: native plan and todo features.
4. Read-only scope: only the cwd or its worktree is writable, except the shared state directory (§8), the `snapshot` root `${SSOT_DIR:-$HOME/.local/state/ssot}`, and §2 freshness and cleanup on checkouts being analyzed.
5. OMP dispatch: preflight `omp --version`. Exit ≠ 0, empty stdout/stderr, or no session file in `~/.omp/agent/sessions/` within the silence limit is a dispatch failure; abort. Run in the background only when the host keeps child ownership across turns with durable metadata; otherwise foreground.

## 8. Shared Task State

One state directory per task across all agents: `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/`. Multi-step implementation and delegated execution use it; questions, lookups, one-off operations (git commands included), and config edits never create it just for bookkeeping.

### 8.1 Keys

- With ticket: the ticket key (e.g. `MO-2278`). Without: `T-<YYYYMMDD>-<kebab-name>`; branch and worktree names match it. Shared trackers: `<repo>-<number>`.
- A local-ID task that needs a PR gets a formal ticket; rename the folder and keep the old ID under `aliases`.
- Lookup order: key, branch name, `aliases`, then cwd matches in `## Repos & worktrees`.

### 8.2 Files

- `STATE.md`: current state and active context.
- `plan-v<N>.md`: delegate plans; append new versions, never overwrite.
- `log.md`: append-only events (`<UTC> <agent> <event>`).

### 8.3 Timing

- Start: with existing state, read `STATE.md` and reconcile only systems relevant to the request.
- Progress: update `STATE.md` and `log.md` when findings, decisions, or status change; skip conversational turns. Root causes → `## Findings`, locked choices → `## Decisions locked`, pitfalls → `## Gotchas`, unblocking unknowns → `## Open questions`.
- Sessions: record OMP sessions in `## Sessions` as `<name> (<id>) (<cwd>)`; resume by ID.
- Mid-task interrupt: output Done / Not done / Next before stopping.

### 8.4 Section Authority

- `## Scope & constraints`: Hermes or human only. `## Plan`: delegate planner. `## Repos & worktrees` and the `repos:` header: creator agent. `control` header: controller.
- Executors modify only `## Status`, `## Decisions locked`, `## Gotchas`, `## Open questions`, `## Verification`, `## Findings`, `## Gates`, `## Sessions`, and the `status`, `updated`, `by` headers.
- External systems (git, PR, Jira) override STATE.md; reconcile and log.

### 8.5 Closeout

- Move completed or cancelled tasks to `_done/<YYYY>/<key>/`; never delete.
- Never write secrets (tokens, passwords, keys) to state files.

### 8.6 STATE.md Template

Copy `~/.local/state/templates/STATE-template.md` (or `system/templates/STATE.md`) verbatim, headers literally, without inline descriptions.

## 9. Agent-Computer Interface (ACI) Discipline

- Batching: batch independent reads, sequence dependent operations; a simple request may finish in one turn.
- Windowed reads: locate targets with grep line numbers, then read bounded sections (`sed -n 'A,Bp'`, ≤100 lines); never stream whole files.
- Output: truncate command output at 100 lines; listings cap at 50 results (`find`, never `ls -R`). Interpret zero output by the tool result or exit status.
- Lint: only when §1 triggers verification. A baseline run only to tell an existing failure from a regression; unrelated baseline failures need no repair. Prose edits need no lint.
- Ceilings: honor explicit runtime, turn, and cost limits and report when one is reached; invent none for simple requests.

## 10. Evidence Discipline

- Checks: claim a check passed only after observing its output this session. Accept attributed executor/CI results after inspecting concrete command/output tied to unchanged code, inputs, and environment; do not rerun valid evidence. This constrains claims, not whether checks run (§1).
- Operations: confirm routine operations by the tool result or exit status; do not duplicate a reliable result with a separate check. Read back only when the result does not establish the outcome, the operation is asynchronous, or a material risk remains. Silence without a reliable status is inconclusive.
- Fact vs inference: ground technical claims in supplied material, inspected sources, or observed results, citing precise locations when needed. Mark unconfirmed deductions `inference:`. Machine verdict lines hold facts only; unverified items are `UNVERIFIED: <what>` with the blocker. Never assume or report probable passes.
- Current state: past session logs prove nothing about the present; when current state matters, inspect the source, and re-read live PR, branch, or ticket state right before proposing modifications. Verification runs against a §2-fresh base; on a feature branch keep its results distinct from the base's.
- Scope of claims: a negative claim states the scope searched; never widen a bounded lookup to claim universal absence. Outbound technical claims state their basis (test, documentation source, or `inference:`); cross-team systems need confirmation from their listed owners.
- External contracts: verify the live schema before modifying; default to additive, non-breaking changes; breaking ones need owner sign-off.
- Challenged claims: inspect the disputed evidence and correct unsupported claims; gather new evidence only when the existing source cannot settle it.
