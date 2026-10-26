# Execution-Layer Rules

Shared code and engineering rules for every coding agent. Bullets calling out `omp` or Hermes are no-ops on setups without those tools. Language settings and read-only system protection are owned by Hermes and not restated outside §7. When rules conflict, safety and explicit human instructions take priority, then this document.

Local overlay: if `~/.ai-rules.local.md` (or `$AI_RULES_LOCAL`) exists, read it as a second file and apply it on top of this document; it wins on conflict. It is never merged into this file.

## 1. Execution Authority and Ask Boundaries

- Explicit instruction beats ceremony: a clear direct human command (`merge`, `push`, `commit`, `run X`, `edit Y`) is itself the definition, plan, and authorization — execute it in the same turn with the fewest tool calls. Problem-first, plan critique, fresh-state re-reads, and investigation guard against ambiguity; they do not apply to an unambiguous command, and conditions the instruction already satisfies are not re-checked. A gate the instruction does not cover → one line, then stop.
- Problem first: no implementation turn until the problem is defined (expected vs actual + command, log, or file:line proof). Record in STATE.md `## Findings` (or in plan/reply if no state folder). Applies across interactive, headless (`-p` / `--approval-mode=yolo`), and `unattended-auto`. Undefined problem with no path to define it → `BLOCKED` per §6.
- Default YOLO (prompt scope only): implement in-scope, reversible work, local debugging, refactoring convergence, and reasonable defaults directly without menu prompts. Incidental refactoring forbidden. Never end a turn with an offer for work you can do directly; offers are reserved for gates, out-of-scope tasks, or forks needing human decisions.
- Investigate once, then implement: one investigation per problem. Record root cause and proving command in `## Findings`, then implement. Re-investigate only when: (a) a genuinely new symptom appears, or (b) the recorded cause is falsified by a failing check or recurring symptom. Stop per §6 if information is missing.
- Plan critique is not investigation: plan-critique loops iterate plan text without re-opening diagnosed root causes. Challenged claims re-open investigation only if they falsify the recorded cause.
- Turn outcome contract: every turn must end in exactly one of: (1) problem definition or root cause recorded in `## Findings` (or plan/reply), (2) code/config change plus proving verify output, (3) CLEAN verify round with no code changes, or (4) `BLOCKED: <reason>`. Non-committal updates ("still investigating") are failed turns.
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

- Gates vs blockers vs approach-uncertainty: the four cases above are exhaustive gates. Missing external facts (specs, credentials, unverified code) are blockers (`BLOCKED: <missing info + needed auth>`). Approach-uncertainty is resolved internally: walk the solution ladder (§4), lock the decision in `## Decisions locked`, and implement. Never try code changes to resolve uncertainty.
- Headless runs (`-p` / `--approval-mode=yolo`): emit `BLOCKED: <reason + needed auth>` at ask boundaries and halt.
- No Hermes fallback: default YOLO does not apply; the ask boundary applies to every action, not only the four listed cases. Plan before executing; request input via selectable menus.
- Control signal: declared via `HERMES_CONTROL` (`unattended-auto` | `interactive` | `human`; unset = `interactive`). Headless flags (`-p`, `--auto-approve`, `--approval-mode=yolo`) are not the control signal. Only `unattended-auto` lifts the push gate; merge and every other boundary stay gated.
- Plan critique: check plan for requirements match, omissions, contradictions, simplicity, and behavior history (§4). Exit after two consecutive zero-finding rounds. Cap at 5 rounds; failure to converge indicates fundamental premise errors—stop and report open questions.

## 2. Git Conventions and Base-Branch Sync

- Follow `git-commit` skill for commit messages, base-branch merging, push squashing, and safe stashing. Direct merge without PR permitted only on unprotected self-owned repos per skill conditions.
- Commit boundary: interactive sessions wait for human approval before committing; auto mode may commit checkpoints. Push requires explicit human instruction and must squash unpushed work into one commit.
- Branch/worktree cleanup: once merged or finished, immediately delete local branch, remote branch, and worktree (`git branch -d <name>`, `git push origin --delete <name>`, `git worktree rm <path> && git worktree prune`) in the same pass.

## 3. Skill Routing and External-Service Control

- Skill unavailable or failing: stop and report; never substitute another process.
- Jira routing: ticket work, PR creation, and review fixes must use `ship` skill; plan-only work uses `delegate`.
- PR routing: creating PRs requires `open-pr` skill alongside task skills.
- MCP write restriction: write access via MCP is strictly limited to Jira and memory updates. All other external writes must use non-MCP paths or stop and report.
- Confluence: edit existing HTML minimally without rewriting pages. Preserve comment anchors and local IDs.

## 4. Surgical Code Maintenance (Minimal Diff Control)

- Solution ladder (stop at first fitting rung): 1. config/data change, 2. existing tool/skill/platform feature, 3. reuse/extend existing code, 4. new code as last resort. Name higher-rung exclusions in plan and `## Decisions locked`.
- Intent before overturning: before removing or altering existing behavior, trace its origin using bounded history commands (`git blame -w -M -L <range> <file>`, `git show -s --format='%h %ad %s%n%b' <sha>`, `git log -L :<func>:<file> --no-merges`). A ticket is context, not authority. If behavior reflects deliberate design without defect, keep it or make the change additive (opt-in). Document reasoning in `## Findings`.
- Contract and enum alignment: inspect producer code serializers and annotations directly for external APIs. Decouple wire DTOs from domain models via a mapping layer. Provide truth tables for polymorphic fields and fallbacks for unknown enums. Stop if producer repo is inaccessible.
- Raw-payload HTTP testing: test external integrations using HTTP mocks (WireMock, MSW, MockWebServer) with raw JSON payloads to validate serialization.
- Zero speculative code: no unrequested features, abstract wrappers, or unused logging/metric layers.
- Redundancy hygiene: merge duplicate definitions, obsolete versions, or temporary copies in touched scope into one canonical location during the same pass. Do not touch unrelated dead code outside task scope.
- Minimal diff: no incidental formatting or comment changes. Every edit must map directly to the task.
- Symlinks: re-point in place (`ln -sfn`). Never create `.bak` files for symlinks.
- Code comments: no new rationale comments in code. Place rationale in commit messages, PRs, or direct replies.

## 5. Pre-Completion Exit Criteria

Review diff and reply against these four checks:

1. No noise: clean of debug logs, temp prints, unused imports, or irrelevant formatting.
2. Defensive: null checks, exception handling, and edge cases addressed.
3. Consistency: matches spec/truth tables; linter and test suite pass completely.
4. No restatement: reply contains no repeated prompts, docs, or preceding text.

Reporting contract:

- Machine record: log each verification to `STATE.md ## Verification` as `- <UTC> <command> → CLEAN|ISSUES: <list>`.
- Self-check trace: record pre-completion check as `- <UTC> pre-completion self-check → CLEAN`.
- Machine outputs: `omp -c` loop rounds must terminate with literal `CLEAN` or `ISSUES: <list>`.
- Chat replies: state prose verdict first; append `ISSUES: <list>` only on failure; omit trailing `CLEAN`.
- Task delivery: state Done / Not done / Next in three lines, verdict first.
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
- Non-git one-offs, Q&A, and config edits: do not create state folders.
- Search precedence: key, branch name, `aliases`, then cwd matches in `## Repos & worktrees`.

### 8.2 Files

- `STATE.md`: current state and active context.
- `plan-v<N>.md`: delegate plans; append new versions, do not overwrite.
- `log.md`: append-only event log (`<UTC> <agent> <event>`).

### 8.3 Timing

- Start: read `STATE.md` and reconcile with git, PR, and Jira.
- Sessions: record OMP sessions in `## Sessions` as `<name> (<id>) (<cwd>)`; resume via ID.
- Turn end: update `STATE.md` and append to `log.md`. Record identified root causes in `## Findings` immediately.
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

- One command per turn: issue one primary tool action per turn with minimal narration.
- Windowed reads: locate targets via grep line numbers, then read bounded sections (`sed -n 'A,Bp'`, ≤100 lines). Never stream entire files.
- Output boundary: truncate command output at 100 lines. Zero output requires explicit confirmation of success.
- Lint before edit: run project lint/format check before modifying a file. If check fails, resolve it before proceeding.
- Edit loop brake: stop and emit `BLOCKED: aci edit-loop` if editing the same file exceeds 3 turns without clean linting.
- Search cap: file listing commands must cap at 50 results (`find`, avoid `ls -R`).
- Ceilings: multi-turn tasks must track max turns and cost; abort with `BLOCKED: aci budget` when breached.

## 10. Evidence Discipline

- Ran-this-session rule: validation claims require running checks in the active session and observing output. Reference the exact command and match `## Verification` entries.
- Silence is not success: zero-output actions require proof via exit code, file existence, or direct query.
- Fact vs inference: factual claims must cite line numbers or command output. Mark unconfirmed deductions as `inference:` in prose. Machine verdict lines contain facts only; unverified items must use `UNVERIFIED: <what>`.
- No memory claims: past session logs or docs do not validate active state; re-run checks.
- Baseline code verification: check current behavior against latest default branch (`git fetch && git show origin/<default>`). Do not make claims based on stale local feature branches.
- Unknowns: report unverified items as `UNVERIFIED: <what>` with blocker details. Never assume or report probable passes.
- Negative claims: claims of non-existence or lack of usage require comprehensive search proof across all possible scopes; otherwise mark `UNVERIFIED`.
- Outbound claims: technical statements to humans must specify basis (test, documentation source, or `inference:`). Cross-team systems require confirmation from listed owners.
- External contracts: verify live contract schema before introducing modifications. Default to additive, non-breaking changes; a breaking change needs owner sign-off.
- Action verification: confirm file operations, status changes, and network updates via post-action checks before reporting completion.
- Challenged claims: when output is challenged, gather new reproducible evidence rather than re-stating previous results.
- Fresh state inspection: re-read live PR, branch, or ticket state immediately before proposing modifications.
