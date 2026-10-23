# Execution-Layer Rules

Shared code and engineering rules for every coding agent. A few bullets call out `omp` (a headless executor CLI) or the Hermes layer; on setups that do not have those tools these bullets are no-ops. Language settings and read-only system protection are owned by the Hermes system layer and are not restated outside §7, which carries the no-Hermes fallbacks.

When rules conflict, safety and explicit human instructions take priority, then this document.

Local overlay: if `~/.ai-rules.local.md` (or `$AI_RULES_LOCAL`) exists, read it as a second file and apply it on top of this document; it wins on conflict. It is never merged into this file.

## 1. Execution Authority and Ask Boundaries

- Default YOLO: implement in-scope work, local debugging, refactoring convergence, and reasonable defaults directly, without a menu prompt. Refactoring is limited to the current task's scope; no incidental refactoring. Bias to act, not to offer: an in-scope fix, cleanup, or follow-up you judge correct gets a quick sanity check and is done in the same pass — never end a turn with an offer for work you could have just done (offers are only for the ask boundary, out-of-scope items, or a genuine fork needing a human decision).
- Investigate once, then implement: one investigation per problem, not one per turn. Record the root cause and the command that proves it in STATE.md `## Findings` (when the task has a state folder), then implement. Investigate again only when (a) a genuinely new symptom appears, or (b) the recorded cause is falsified by a failing check, or by the same symptom recurring after a fix landed. Otherwise implement from the recorded cause. Having no cause yet is not a reason to keep investigating: stop per §6 with the missing required information.
- Plan critique is not investigation: the plan-critique loop in this section iterates the plan text (no new evidence) and must not re-open a diagnosed root cause. §10 "Challenged claims get new evidence" is trigger (b) above: a challenge that falsifies the cause re-opens investigation, a challenge that does not, does not.
- Turn outcome: every turn ends in exactly one of — (1) a code/config change plus the verify output that proves it, (2) a root cause recorded in STATE.md `## Findings`, (3) a verify round that ends CLEAN with no code change (already verified, nothing to change), (4) `BLOCKED: <missing required information>` per §6. "Still investigating", "need more time", "let me check a few more things" are not outcomes: a turn that ends without one of the four is a failed turn and the next turn must end in one of them.
- Extend before adding: read the existing docs and structure first, then check whether an existing item (bullet, section, rule, file) already covers the ground; extend that instead of adding a new one. Add a new item only when nothing existing fits. A rule usually lives in several files by design (one consumer per file), so search all of them, not just the file you have open (in the rules repo: `grep -rni '<concept>' system/ skills/`). Search the concept and its synonyms, not the name you plan to introduce: a name you just coined is exactly what the existing rule does not contain.

| File | Consumer | Note |
|---|---|---|
| `system/rules.md` | every agent (Zed, Claude, OMP, opencode) | canonical owner of most rules; editors symlink this file directly, so edits are live immediately; the overlay is read separately |
| `system/sticky_rules.md` | OMP hard rules | linked as `~/.omp/agent/RULES.md` |
| `system/hermes.md` | Hermes contract | linked as `~/.hermes/SOUL.md`; self-contained by design (no cross-file references), so a rule it needs is stated in full |
| `skills/<name>/SKILL.md` | that tool's dispatch skill | where Hermes/OMP prompt templates live |

Per-consumer restatement is deliberate. A second name for an existing concept is not: reuse the existing name and section, then add the new facet there. Canonical vocabulary, one name per concept:

| Term | Means |
|---|---|
| investigation | the root-cause analysis for a problem; runs once per problem, result in STATE.md `## Findings` |
| round | one iteration with a definite verdict: verify round (`CLEAN` / `ISSUES`), plan-critique round (zero findings / fixes) |
| turn | one agent response cycle: the unit the turn outcome (§1) and the turn/cost ceiling (§9) bound |
| gate | one of the four ask-boundary cases |

- Mandatory ask boundary (Hard Ask Boundary): pause and confirm with a human only in these cases:
  1. Irreversible or outbound actions: push (except under the control signal `unattended-auto`, below), creating or merging PRs, deleting others' branches or remote work, publishing externally.
  2. Creating or modifying a Data Model / DB Schema entity.
  3. A high-cost, mutually exclusive architecture fork (spanning multiple services, or requiring a large rewrite, with mutually exclusive alternatives).
  4. Writing to an external service (MCP writes are covered in §3).
- Outside those four cases, when information is missing, the spec is contradictory, or the work cannot be verified: take the conservative default. Stop and report; do not self-approve. This covers a missing external fact that would change the outcome — scope, contract, safety, an unavailable producer repo. Uncertainty about the approach is not a missing fact: for in-scope, reversible work, resolve it inside the run (re-plan, raise thinking, take the advisor/plan model's answer), record the decision in one line in `STATE.md` `## Decisions locked`, then implement. The four ask-boundary cases above are the exhaustive list of actions that need human authorization. A missing external fact is a blocker, not a gate: stop per §6 and report.
- Headless runs (`-p` / `--approval-mode=yolo`) have no interactive prompt. On an ask boundary, stop and emit `BLOCKED: <reason>` plus the authorization needed, and hand off to the upper layer or a human.
- No Hermes: the default YOLO does not apply, and the ask boundary above applies to every action rather than only the four listed cases. Plan before executing; ask questions via a selectable menu.
- Control signal: the controller declares itself with env var `HERMES_CONTROL` (`unattended-auto` | `interactive` | `human`; unset = interactive). `--auto-approve` / `--approval-mode=yolo` are not the control signal. Only `unattended-auto` lifts the push gate (case 1) for the controller; merge and every other boundary stay gated.
- Plan critique: while planning, interrogate the plan each round: correct vs requirement? anything missing? contradiction or redundancy? simpler? overturning existing behavior without a traced reason (§4)? Fix material findings, ignore style nitpicks, re-run; exit after two consecutive zero-finding rounds. Cap 5 rounds: no convergence = major problem (contradictory task or wrong approach): re-check the premise, surface the unresolved contradiction and open questions for human decision; never present a non-converged plan as ready.

## 2. Git Conventions and Base-Branch Sync

- Follow the `git-commit` skill for commit messages, merging the base branch (conflicts in favor of this branch, then re-check the base branch for reusable modules or spec changes), squash on push, and safe stashing. A PR-free direct merge is allowed for unprotected self-owned repos; the conditions and the unchanged authorization gate are in the git-commit skill.
- Commit boundary: interactive sessions wait for the human's instruction before committing; auto mode (dispatched runs, e.g. Hermes→OMP) may commit checkpoints. Push waits for an explicit human "push" (see §1), and every push first squashes all not-yet-pushed work (commits plus uncommitted changes) into one commit (`git-commit` skill).
- Branch and worktree cleanup is immediate and unasked: once a branch has merged into its base, or the work is concluded, delete the local branch, the remote branch, and the task's worktree in the same pass (`git branch -d <name>`, `git push origin --delete <name>`, `git worktree rm <path>` followed by `git worktree prune`); never offer it as a follow-up.

## 3. Skill Routing and External-Service Control

Below: what to invoke. If a skill is unavailable or fails, stop and report; never substitute another process.

- Mandatory Jira routing: any work on Jira tickets, related PR creation, or review-comment fixes must invoke and follow the `ship` skill; plan-only work (plan, then review another agent's implementation) uses `delegate` instead.
- Mandatory PR routing: creating a PR always requires invoking and following the `open-pr` skill, on top of any task-level skill (e.g. `ship`).
- MCP write restriction: never write to external services through MCP. The only exceptions are Jira and memory (Hindsight/Memory) updates. Route all other writes through a non-MCP path; if none exists, stop and report.
- Confluence editing: never rewrite a whole page. Edit the existing structure in HTML, minimally and targeted, preserving inline comment anchors and local IDs. If no non-MCP write path exists, stop and report.

## 4. Surgical Code Maintenance (Minimal Diff Control)

- Reuse first: before writing code, search for an existing function / class / method / helper that already does the job and use it. Add new code only when nothing existing fits. When you must add, extend or inherit rather than duplicate.
- Intent before overturning: at plan time, at edit time, and in review, a change that removes, replaces, or reverses existing behavior must first establish what the old behavior was for and whether the new one is an improvement. Trace the origin with bounded, de-noised history queries: `git blame -w -M -L <range> --ignore-revs-file <file>` finds the introducing commit (bound the region to the code you change; `-w` ignores reformat noise; `-M`/`-C` fix moved lines, `-C` is the slowest flag, drop it on large repos); `git show -s --format='%h %ad %s%n%b' --date=short <sha>` gives the message body, where the reasoning lives; `git log --reverse --oneline -S<str> -- <path> | head -1` gives the first appearance, `-L :<func>:<file> --no-merges` the behavior's evolution, `--grep='<issue>' --all` the linked work, and `--grep='^Revert' -- <path>` prior reversals. Cap every query with `-n`, `--since`, `--first-parent`, and `--oneline`/`--format='%h %ad %s' --date=short`; read the tests that pin it. Note the pickaxe `-S` is `git log`'s (`git blame -S <file>` is a different flag: a revisions file), and `-S` counts occurrences, so it misses a move without a copy — `-G<regex>` catches the pattern, `-M`/`-C` catch the copy. Read the ticket or spec for the intended goal — it is context, not authority: a ticket can be wrong, and a ticket that asks for a change does not make the change right. Judge the change on its merits: a change that fixes a known defect, or that makes the behavior measurably better, proceeds; a deliberate and correct behavior that the change does not improve stays, or the change becomes additive (new path, opt-in flag) instead of replacing it, and the plan says why. Record what the old behavior was for and the conclusion (in the plan, plus `STATE.md ## Findings` when the task has a state folder; in review, the finding and its basis). One check per overturned decision, not a re-investigation of the root cause (§1).
- Contract and enum alignment: for cross-service or external APIs, check the Producer Code's serializers and annotations; never guess enums or JSON fields. Isolate Wire DTOs from Domain enums through a conversion layer. Produce a Truth Table for polymorphic fields, and include a defensive fallback for unknown enum values. Producer repo inaccessible → stop and report (no guessing from internal constant names).
- Raw-payload HTTP testing: for external communication, do not test only with client or interface mocks. Use an HTTP-level mock (e.g. WireMock, MSW, MockWebServer) with real raw JSON response bodies to validate deserialization.
- Zero speculative code: do not add unrequested features, placeholder interfaces, kitchen-sink options, or unnecessary Log/Metrics/Tracing abstraction layers.
- Redundancy hygiene: the other half of "zero speculative code". When the scope you touch already holds the same rule, entry, or code twice (under different names), an obsolete version a newer one replaced, or a backup copy, merge them into the one canonical place and remove the rest; never keep both. A turn that leaves a known duplicate in the scope it edited is not finished: do it in the same pass, never offer it as a follow-up. Duplication means two statements in the same file; the deliberate per-consumer restatement across the rule layers (§1) is not duplication. Scope is what this change touched — this does not license deleting unrelated pre-existing dead code (see Minimal diff).
- Minimal diff: do not incidentally change nearby formatting, comments, or unrelated logic. Every changed line must trace to this task's request. Clean up orphaned code only when this change invalidates it; do not delete pre-existing dead code on your own.
- Symlink is a pointer, not user content: re-point it in place (`ln -sfn`). Never back it up, move it, or leave a `.bak` of it. Back up only a real user file.
- No new comments in code. Put required rationale in the commit message, PR description, or direct reply instead.

## 5. Pre-Completion Exit Criteria

Before final confirmation, review the git diff (staged and unstaged) and the reply you will send; confirm all four checks:
1. No noise: no debug prints, temporary logs, unrelated formatting, or unused imports.
2. Defensive: null/empty checks, network and exception handling, and boundary conditions are all present.
3. Consistency: the logic matches the Truth Table and the Jira or task spec exactly, and the project's lint and test commands pass in full.
4. No restatement (reply): the reply repeats nothing already covered — the question, existing docs or code, or an earlier part of the reply; it adds information. Delete any restating line before sending.

Reporting contract: `CLEAN` / `ISSUES: <list>` is a machine verdict, not a chat signature.
- Record: every verification round writes `- <UTC> <command or check> → CLEAN|ISSUES: <list>` to `STATE.md` `## Verification`.
- Self-check trace: record the pre-completion self-check (#1-4, incl. no restatement) as one `## Verification` line, `- <UTC> pre-completion self-check → CLEAN` (skip if the task has no STATE.md).
- Machine outputs: verify loop rounds (omp `-c`, only when you run that loop) still end with exactly one line `CLEAN` or `ISSUES: <list>` for the parser.
- Chat replies to a human: lead with the verdict in prose; append `ISSUES: <list>` only when something failed; no trailing `CLEAN`.
- When delivering results or a PR: three lines Done / Not done / Next, verdict first in prose.
- Reply drafts for the human to paste (Slack, PR comments): invoke `voice` first, then hand over raw markdown in a ```markdown fenced block so it copies as-is (never a rendered `>` quote).

## 6. When Stuck

1. Collision thinking: deliberately connect unrelated concepts to find an entry point.
2. Reversal: flip the existing constraints and check whether the problem is a false one.
3. Simplification cascade: find the smallest entry point that removes several complexities at once.

If you still cannot make progress, or lack required information (Producer repo, spec, credentials), stop and report; do not guess and continue.

## 7. Dependency and Degradation (No-Hermes Fallback)

This document assumes the Hermes system layer exists. When Hermes is absent, use these minimal substitutes for the items it covers:
1. Language settings: converse in Traditional Chinese or English; use English for PRs, Jira, docs, and comments unless told otherwise. Rule files, skill files, contracts, and configs are English artifacts: never put a quoted user phrase or a sample in another language inside them, even as a gloss.
2. State: shared task state per §8; the todo list is session-only.
3. Plan control: without Hermes, use the built-in plan and todo for breakdown and tracking.
4. Read-only system protection: without Hermes, only the current working directory or its worktree is writable; any path outside the plan is read-only.
5. OMP liveness (only when you dispatch omp): preflight `omp --version`; capture exit code + stderr (stdout may stay empty). Exit ≠ 0, empty result, or no new session file under `~/.omp/agent/sessions/` → OMP did not run; silence ≠ running. Never wait `--max-time` out on a silent dispatch. Background only when the host owns the child across turns and writes a durable record; else run foreground — never hand-roll `nohup` + poll.

Execution authority is covered in §1.

## 8. Shared Task State

One state folder per task at a neutral location, shared by every agent (Hermes, omp, Claude, Cursor, opencode). It survives worktree removal, session changes, and agent switches. The todo list and session files stay session-only; they are not shared state.

Location: `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/`

### 8.1 Keys

- With a ticket: the ticket ID (e.g. `MO-2278`). Jira keys stay as-is.
- Git task without a ticket: `T-<YYYYMMDD>-<kebab-short-name>`, created by the first agent that acts. The branch name equals the key; when the agent creates the task it also creates the branch (or worktree) with that name.
- Trackers whose numbers repeat across repos (e.g. GitHub Issues): key = `<repo>-<number>`, e.g. `awesomerepo-42`.
- A local-ID task that must open a PR: propose a formal ticket first (external write, wait for human approval). Once it exists, rename the folder to the ticket ID and record the old ID under `aliases` in STATE.md.
- Non-git one-offs, Q&A, and config changes: create no folder.

Finding an existing task, in order: the key, the current branch name, `aliases`, then every STATE.md `## Repos & worktrees` entry that contains the current working directory. The fallback scans cover only top-level folders and skip `_done/`. Only if none of those matches: create a new folder.

### 8.2 Files

- `STATE.md` — current state; whole-file rewrite allowed, but who may change which section is §8.4.
- `plan-v<N>.md` — delegate plans; add new versions only, never overwrite.
- `log.md` — append-only, one line per event: `<UTC> <agent> <event>`.

### 8.3 Timing

- Before starting work on a task: read `STATE.md`, then check it against git, PR, and Jira.
- One omp session per task, named after the key: record it in `## Sessions` as `<name> (<session id>) (<cwd>)`; resume by the id.
- Before ending each turn: update `STATE.md` and append one line to `log.md`. When the turn found the root cause, write it to `## Findings` (cause + the command that proves it) in that same turn — that record is what stops the next turn from re-investigating.
- Trigger each block at its own moment, not at closeout: a decision resolved by plan critique or by the §1 in-run judgement goes to `## Decisions locked` (one line, with why, marked do not reopen) in the turn it lands; a trap that cost diagnosis time but is not this task's root cause goes to `## Gotchas` (symptom + guard), while the task's own root cause stays in `## Findings`; an unknown that does not block the current turn goes to `## Open questions` with a resolve-by marker. A gotcha that recurs across tasks graduates to the observation log rather than growing this file. Resolved open questions move out (into `## Decisions locked` or closed) so the blocks stay lean.
- Interrupted mid-task: at least write Done / Not done / Next once.

### 8.4 Who writes which section

- `## Scope & constraints`: Hermes or a human only.
- `## Plan`: the delegate planner. `## Repos & worktrees` and the `repos:` header: set at creation, by Hermes or the agent that creates the worktree.
- Executors may change only `## Status`, `## Decisions locked`, `## Gotchas`, `## Open questions`, `## Verification`, `## Findings`, `## Gates`, `## Sessions`, and the header lines status, updated, by; `control` is controller-owned and never executor-changed.
- Every write updates `updated` and `by`.
- STATE.md disagrees with git, PR, or Jira: the external system wins. Correct STATE.md and append a `reconcile` line to `log.md`.

### 8.5 Closeout

- PR merged or task cancelled → move the folder to `_done/<YYYY>/<key>/` (year of closeout). Never delete automatically.
- Never store secrets: no tokens, passwords, or MCP credentials.

### 8.6 STATE.md template

Creating STATE.md: copy `~/.ai-rules/STATE-template.md` verbatim into `<state dir>/<key>/STATE.md`. The link is created by `scripts/setup.sh` from the source of truth `system/templates/STATE.md`. If the link does not resolve, locate the repo through the rules file itself: `readlink` on the rules path you loaded rules.md from reveals `system/`'s parent directory; read `system/templates/STATE.md` beside it. Headings are literal: copy them without annotation text. `## Gates` holds pending human decisions and BLOCKED reasons (with the authorization needed); who writes each section is §8.4.

Find tasks touching a repo: `grep -l '^repos:.*\b<repo>\b' <state dir>/*/STATE.md`.

## 9. Agent-Computer Interface (ACI) Discipline

Interface contract for every tool call. Source: Yang et al., SWE-agent (arXiv:2405.15793). Applies to every agent (Hermes, omp executor, delegate, host editor). Machine contract: loaded by default, not skill-triggered.

- One command per turn: one primary tool call (a tight read/edit batch is still one action); narration minimal. Prefer fixing by config/data over source edits.
- Line-number windows, no continuous scroll: locate first with grep (line numbers), then read one bounded window (`sed -n 'A,Bp'`, ≤100 lines); never consecutive scroll of a whole file.
- Bounded output: any command output truncates at 100 lines (`head -100` or editor tool limit); zero output means explicit success line, never silence.
- Lint before edit: run the file's lint/format gate before an edit to it; lint-gate fail → abort the edit, address the failure first, do not push through; no lint gate defined for that file type → say so once and proceed.
- Edit loop brake: after 3 turns editing the same file without passing the lint gate, stop and emit `BLOCKED: aci edit-loop`.
- Search breadth cap: one listing command lists only file names, hard cap 50 hits (`find`, not `ls -R`); per-file content read falls to the line window rule above.
- Turn / cost ceiling: for multi-turn tasks, set max turns and max cost up front; exceeded → emit `BLOCKED: aci budget`.

## 10. Evidence Discipline

Anti green-lie: every `done / pass / fixed / CLEAN / works` claim must trace to evidence, not intent. Applies to every agent.

- Ran-this-session rule: a pass claim is valid only if you ran the check in the current session and saw its output; the claim names that command. The claim must match its `STATE.md ## Verification` record (format per §5) — record applies to task rounds; Q&A answers cite the output inline.
- Silence is not success: zero-output commands confirm success by exit code, artifact existence, or a follow-up probe — state which one proved it.
- Fact vs inference: factual claims cite file:line or command output; speculation carries the explicit marker `inference:` and lives in prose only, never inside a machine verdict. Verdict lines (`CLEAN` / `ISSUES: <list>` / `UNVERIFIED` / Done-Notdone-Next) are fact-only: anything unverified goes to `UNVERIFIED: <what>`, never disguised as fact.
- Not-memory rule: a previous session's success, tool defaults, or doc trust never verify current state; re-run what you claim.
- Fresh code before code claims: before reading a repo to claim how it behaves, update it to the latest default branch: `git pull --ff-only` when on that branch with a clean tree, otherwise `git fetch` and read `origin/<default>` (`git show`, `git grep`). Never claim behavior from a local feature branch. For a claim about a deployed environment, also confirm the deployed version contains that code.
- Unknown stays unknown: cannot verify → write `UNVERIFIED: <what>` and the blocker reason; never fold an unverified item into a pass, never soften with "probably fine".
- Negative claims need full coverage: a claim that something does not exist, does not happen, or is unused holds only if the search covered every place it could be. Otherwise `UNVERIFIED`. An empty search result proves nothing.
- Outbound claims carry their basis: every technical claim sent to humans states how it is known: tested, cited source, or `inference:`. A claim about another team's system or about product intent names the owner who can confirm it. It does not drive a design decision until that owner confirms.
- Contract changes start from live reality: before changing anything consumed outside the repo, capture its current live form and known consumers. Default to additive, non-breaking changes. A breaking change needs owner sign-off.
- Action claims are evidence claims: never report an action as done (saved, posted, updated, sent, recorded) unless it ran this session and its output confirmed it.
- Challenged claims get new evidence: when a claim is disputed or questioned again, gather evidence the challenger can check (live data, a reproducible test, the owner's answer) before replying. Do not re-assert the same basis.
- Read state before deciding: before advising on or changing shared state (PR, thread, ticket, branch), re-read its latest version. Do not act on a snapshot from earlier in the session.
