---
name: omp
description: Delegate implementation to the Oh My Pi (`omp`) CLI with conditional, risk-scoped checks and same-session follow-ups. Used by Hermes/OpenClaw, and by `ship` / `delegate` when Hermes is absent.
user-invocable: true
---

# omp — Delegating Work to Oh My Pi

Hand work to local `omp` CLI ([can1357/oh-my-pi](https://github.com/can1357/oh-my-pi)). Linked for Hermes / OpenClaw; `ship` / `delegate` load it for dispatch.

## Boundaries (CLI help)

| Flag | Meaning |
|---|---|
| `--max-time=<dur>` | Hard stop (`600`, `10m`, `1h`) |
| `-p` / `--print` | Non-interactive: process prompt, exit |
| `--auto-approve` / `--approval-mode=yolo` | Unattended tool approval |
| `--plan-yolo` | Plan→implement in one process |
| `--advisor` | Passive per-turn review notes |
| `-c` / `--continue`, `-r` / `--resume` | Same-session follow-ups |

Multi-round verify = continue same omp session (`-c` / `-r`), not outer N-round shell.

`--auto-approve` / `--approval-mode=yolo` govern only OMP's internal tool approval; not the control signal (`HERMES_CONTROL`); never authorize push (see `git-commit` §3).

Default unattended base:

```bash
omp -p --auto-approve --approval-mode=yolo --advisor --max-time=1h
```

Override `--max-time` / models when specified. `--cwd` when needed.

## Shared task state

- Delegated implementation (not read-only one-shots), before dispatch: resolve key (ticket ID → current branch → aliases → STATE.md worktree match); read or create `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/STATE.md` (fill `repos:`; ticketless task: create branch named after key); put state folder path into prompt.
- One session per task, named after key. Before dispatch, read `## Sessions` for this task's session name and id. Id present → continue that session (`omp -p -r <id> …`), never fresh one. No id → run base command, record new session as `<name> (<id>) (<cwd>)` in `## Sessions`, `<name>` = task key. Reset to new session only deliberately, reason in `log.md`; `-r <id>` fails (session gone) → start fresh, record new session.
- After progress: update session/task status when changed; record only checks actually run in `## Verification` (`<UTC> <command or check> → CLEAN|ISSUES: …`). Never invent verify round for bookkeeping. Read-only one-shots: no state folder or task branch.

## Liveness & failure detection

`omp -p` fails loudly: non-zero exit, message on **stderr**, stdout may stay empty. Caller reading only stdout sees nothing; treat as failure, not success.

- Preflight before dispatch: `command -v omp`, then `omp --version`. Missing or non-zero → read stderr, repair or install per https://omp.sh/, recheck `omp --version`; also fix in-scope cause (PATH, cwd, rejected flag). Still failing → `BLOCKED: omp unavailable` with stderr. Never assume OMP ran.
- Capture **exit code and stderr**, not just stdout. Exit ≠ 0, empty stdout, or no result → failure.
- Proof it started: new `~/.omp/agent/sessions/<slugified-cwd>/*.jsonl` after dispatch (no file → OMP never ran). `omp ps --json` adds daemon-supervised state.
- Silence rule: no first output within 30s and no session file → kill; don't wait for `--max-time`. Retry once by another route: `PI_DEBUG_STARTUP=1`, drop any rejected host option, foreground if background failed. Still silent → `BLOCKED: omp not dispatched` with stderr startup phase.
- `BLOCKED` report also written into STATE.md `## Gates`: reason + authorization needed. Stdout lost when session ends.
- Stream watchdog: `providers.streamFirstEventTimeoutSeconds` / `providers.streamIdleTimeoutSeconds` (config, seconds; target 120s) bound first-event and inter-event silence so wedged stream exits non-zero; env `PI_STREAM_FIRST_EVENT_TIMEOUT_MS` / `PI_STREAM_IDLE_TIMEOUT_MS` (ms, `0` disables) override per run.
- Debug hang: `PI_DEBUG_STARTUP=1` (stderr `[startup] <phase>` markers survive hard hang), `PI_TIMING=1`.

## Background dispatch & completion

Default **foreground** (blocking). Long dispatch (plan-yolo implement + verify loop, > 5 min expected) → prefer **background host-as-parent** below; foreground long run risks host tool-call timeout killing child mid-run. Background only when host can own child process and record it durably; else foreground. Never hand-roll `nohup` + poll: no reaper, no restart survival.

- Host process options: only parameters host tool documents. Rejected one (e.g. notify option) → rerun without it, or foreground; never abandon dispatch.
- Ownership: track child by pid and session file until exit + final result; never end host turn with untracked child. Foreground keeps `--max-time` below host tool timeout, continues via `-r <id>`.

**Host-as-parent (preferred):** spawn OMP as **child**, read its stream asynchronously; frontend stays responsive.

```bash
# child of the host; host reads stdout as events arrive
omp -p --auto-approve --approval-mode=yolo --advisor --max-time=1h \
  --mode=json 'TASK …'
```

- Completion truth = child's **exit status** (OS-guaranteed, even on crash/signal) + final event. `--mode=rpc` when explicit `session_settled` frame needed: session truly done, no live run, no queued steer, **no pending background job** (`prompt_result` alone = agent yielded only). Late attach: `get_state` → `isSettled` / `hasPendingAsyncWork`.
- Parent reaps child: no zombie; stream + exit: no silence.
- Harden so wedge self-fails non-zero: `--max-time` + `PI_STREAM_FIRST_EVENT_TIMEOUT_MS` / `PI_STREAM_IDLE_TIMEOUT_MS` (`0` disables).

**Durable job record (survive host restart):** pick durable run dir (`RUN=$(mktemp -d)`); before dispatch write `$RUN/meta.json` (`pid`, `cmd`, `started-at`, run dir, session dir); durable, not in-memory.

- After restart: `pid` alive → re-attach (tail log / reopen session). `pid` dead + result → done. `pid` dead + no result → session file exists: resume `omp -p -r <id>` with remaining work; none: re-dispatch. Fails again → recover per `rules.md` §6; `BLOCKED: omp no result` only when §6 leaves no path.
- Durable evidence = OMP's own session file (`~/.omp/agent/sessions/<slugified-cwd>/*.jsonl`) + exit status. No invented marker file.

**Fallback, no background:** host can't hold child across turns, or no durable record writable → OMP **foreground (blocking)**.

- Hooks/extensions (`pi.on("agent_end"|"session_shutdown")`, `--hook`) fire **inside** OMP process; kill/timeout skips them. Optional best-effort notify only, never completion signal.
- Long-running services OMP starts itself: prefer its supervision over `nohup`: `bash`/service call with `name` is daemon-supervised (`omp ps list|info|logs|stop|kill|restart`), stays observable, gets reaped; no zombie.

## Prompt-paired built-ins

Standalone lowercase words in prompt add per-turn behavior (exact spelling, prose only, current turn):

| Word | Effect |
|---|---|
| `ultrathink` | Max reasoning effort for the turn |
| `orchestrate` | Scope + parallel delegate + verify each phase |
| `workflowz` | Deterministic multi-subagent via the `eval` kernel (`agent()` / `workpool()`) |
| `jevify` | Bulk classification via `eval` `judge()` |

Shape run without prompt text: `--model` / `--smol` / `--slow` / `--plan`, `--thinking=off…max`, `--prewalk`, `--advisor`. Persist via `omp config set` (e.g. `modelRoles`, `advisor.enabled`, `plan.enabled`, `ask.timeout`, `tools.maxTimeout`, `retry.fallbackChains`). Full schema: `omp config list --json`.

Two model switches, don't confuse. `--plan-yolo`: forces read-only plan mode at start, auto-approves plan on model's first resolve call, implements on `--plan-yolo-into` (default `smol` role). `--prewalk`: not a planning stage; switches to fast/cheap model at first edit/write once plan's todo list exists; cheaper implementation, not more certain. Planner and implementer may differ; implementer reads plan's decisions, never re-derives them.

## Modes

| Trigger | Behavior |
|---|---|
| `omp TASK_XXX` | Implement; run checks justified by behavior, risk, acceptance criteria, or explicit request |
| `plan-yolo TASK_XXX` | Same; turn 0 uses `--plan-yolo` |
| `Nverify TASK_XXX` (e.g. `5verify`) | Cap needed verification follow-ups at N per approach (default **5**); ceiling, not quota |
| `continue …` / `resume <id> …` | Single follow-up |

### Default flow

```
Turn 0: omp -p [--plan-yolo] --advisor … "TASK"
Follow-up only for unresolved required checks: omp -p -r <id> --advisor … "VERIFY prompt"
Stop: required work/checks complete (even after a fix)
N reached or 2 unsuccessful fixes of the same failure: backtrack, switch approach, continue (rules.md §6)
BLOCKED: every remaining path needs external input, or 3 approaches failed
```

- Investigation: one per problem, not per turn. Cause/evidence → STATE.md `## Findings`; implementation requested and no gate/blocker → continue to in-scope fix same turn. Read-only and plan-only requests end with requested deliverable. Re-investigate only on new symptom or falsified cause; never "investigating further" with same method. No cause after one investigation → switch method once (reproduce, logs/trace, bisect); still none → `BLOCKED: <missing required information>`. Setup turn re-deriving already recorded cause → stop deriving, implement from record.

**Turn 0**

```bash
omp -p --plan-yolo --auto-approve --approval-mode=yolo --advisor --max-time=1h \
  "TASK_XXX

Root cause: <recorded cause + proving command, or: unknown — investigate once, then implement>
State: <state dir>/STATE.md — read it first; write root cause to ## Findings when found.

Deliver requested change, finding, plan, or blocker. Two unsuccessful fixes for same failure → backtrack, switch approach, continue; BLOCKED only when every remaining path needs external input or 3 approaches failed, listing them. Run extra checks for executable behavior changes, concrete material risk, consequential uncertainty, or explicit verification request. Preserve acceptance criteria, required repository/security checks, raw-payload integration tests. Clear low-risk operations and prose edits: no invented verification round; reliable operation result suffices. Required checks → include actual evidence; never claim unrun check passed. Executors never push, open PRs, merge PRs. Only four ask-boundary cases (irreversible/outbound action, schema change, high-cost architecture fork, external write) justify stopping to ask. Approach uncertainty is not one: this round runs --plan-yolo; resolve it in plan phase, record decision in one line, implement. Plan and implementation may run on different model roles (plan vs --plan-yolo-into, default @smol): re-read plan's decisions before writing code. Change removing, replacing, or reversing existing behavior: first trace what it was for (git blame -w -M -L <range> <file> for introducing commit, git show -s --format=%B <sha> for reasoning, git log -L :<func>:<file> --no-merges for evolution, linked issue, pinning tests) and whether defect or deliberate design; judge on merit: fixes known defect or measurably improves behavior → proceed; otherwise keep it or make change additive; task text = context, not verdict.

Done when: requested scope and acceptance criteria met, required checks pass. Smallest relevant checks during implementation; delivery checkpoint runs repository-required CI-equivalent checks. Before analysis and required verification, apply repo freshness (rules.md §2): never switch this task's worktree; read origin/<default> for base state. Reuse unchanged evidence; no extra clean round. Summarize result."
```

Tiny one-shots: skip `--plan-yolo` if user only said `omp TASK`.

**Optional follow-up, only for remaining verification need**

```bash
omp -p -r <session-id> --auto-approve --approval-mode=yolo --advisor --max-time=30m \
  "VERIFY round k/N (independent of your last self-report):
1. Re-read diff and acceptance criteria for TASK_XXX.
2. Inspect recorded commands/output; run only checks missing valid evidence or affected by changes. Preserve required acceptance/security/contract checks.
3. Fix real issues found.
4. End with exactly one line: CLEAN or ISSUES: <short list>.
Rule: CLEAN = no required work/checks unresolved, including after fixes whose affected checks passed. ISSUES = unresolved findings or failed/missing required checks. List fixes separately; they don't force another round.
Fix from recorded root cause in STATE.md ## Findings. Failing check = fix task, not new investigation; start one only if it falsifies recorded cause. Fix needs approach decision → decide inside this round with --thinking raised, using recorded cause and plan in session context; don't stop to ask. Only four ask-boundary cases (irreversible/outbound action, schema change, high-cost architecture fork, external write) justify stopping; approach uncertainty is not a gate. Two unsuccessful fixes for same failure → backtrack, switch approach; BLOCKED only when every remaining path needs external input or 3 approaches failed."
```

- `CLEAN` → stop; fixes with passing affected checks need no separate unchanged round.
- `ISSUES` → fix known in-scope cause, rerun affected checks same turn; continue only for unresolved work.
- `k == N` or two unsuccessful fixes for same failure, even if files changed → backtrack, switch approach, restart round budget for new approach (`rules.md` §6). `BLOCKED: verify loop fail` only when every remaining path needs external input or 3 approaches failed, listing them.
- Controller review inspects concrete commands/output and scope. Host reruns need environment difference, incomplete evidence, or remaining material risk; not routine distrust.
- `-c` misses session → `-r <id>` from turn 0 output.

**Optional:** `omp cleanse` when lint/diagnostics noise keeps failing, then continue with `-c`.

### Single continue / resume

```bash
omp -p -c --auto-approve --approval-mode=yolo --advisor "follow-up: …"
omp -p -r <session-id> --auto-approve --approval-mode=yolo --advisor "follow-up: …"
```

`-c` continues current session (not necessarily verification). `-r <id>` resumes specific session by id; use it to continue task's session across dispatches.

## Done

Report requested result, actual required-check evidence, any blocker. Round counts only when verification loop ran; no loop added to fill report format.
