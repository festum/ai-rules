---
name: omp
description: Delegate implementation to the Oh My Pi (`omp`) CLI with conditional, risk-scoped checks and same-session follow-ups. Used by Hermes/OpenClaw, and by `ship` / `delegate` when Hermes is absent.
user-invocable: true
---

# omp — Delegating Work to Oh My Pi

Hand work to the local `omp` CLI ([can1357/oh-my-pi](https://github.com/can1357/oh-my-pi)). Linked for Hermes / OpenClaw; `ship` / `delegate` load it for dispatch.

## Boundaries (CLI help)

| Flag | Meaning |
|---|---|
| `--max-time=<dur>` | Hard stop (`600`, `10m`, `1h`) |
| `-p` / `--print` | Non-interactive: process prompt and exit |
| `--auto-approve` / `--approval-mode=yolo` | Unattended tool approval |
| `--plan-yolo` | Plan→implement in one process |
| `--advisor` | Passive per-turn review notes |
| `-c` / `--continue`, `-r` / `--resume` | Same-session follow-ups |

Multi-round verify = continue the same omp session (`-c` / `-r`), not an outer N-round shell.

`--auto-approve` / `--approval-mode=yolo` only govern OMP's internal tool approval; they are not the control signal (`HERMES_CONTROL`) and never authorize a push (see `git-commit` §3).

Default unattended base:

```bash
omp -p --auto-approve --approval-mode=yolo --advisor --max-time=1h
```

Override `--max-time` / models when specified. Use `--cwd` when needed.

## Shared task state

- For delegated implementation (not read-only one-shots), before dispatch: resolve the key (ticket ID → current branch → aliases → STATE.md worktree match), read or create `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/STATE.md` (fill `repos:`; task without a ticket: create the branch named after the key), and put the state folder path into the prompt.
- One session per task, named after the key. Before dispatch, read `## Sessions` for this task's session name and id. An id is present → continue that session (`omp -p -r <id> …`), never start a fresh one. No id → run the base command, then record the new session as `<name> (<id>) (<cwd>)` in `## Sessions`, `<name>` = the task key. Reset to a new session only deliberately, with the reason in `log.md`; if `-r <id>` fails (session gone), start fresh and record the new session.
- After progress: update session/task status when changed; record only checks actually run in `## Verification` (`<UTC> <command or check> → CLEAN|ISSUES: …`). Never invent a verify round for bookkeeping. Read-only one-shots need no state folder or task branch.

## Liveness & failure detection

`omp -p` fails loudly: non-zero exit, message on **stderr**, stdout can stay empty. A caller that reads only stdout sees nothing — treat that as failure, not success.

- Preflight before dispatch: `command -v omp`, then `omp --version`. Missing or non-zero → read stderr and repair or install it per https://omp.sh/, then recheck `omp --version`; also fix an in-scope cause (PATH, cwd, a rejected flag). Still failing → `BLOCKED: omp unavailable` with stderr. Never assume OMP ran.
- Capture **exit code and stderr**, not just stdout. Exit ≠ 0, empty stdout, or no result → failure.
- Proof it started: a new `~/.omp/agent/sessions/<slugified-cwd>/*.jsonl` after dispatch (no file → OMP never ran). `omp ps --json` adds daemon-supervised state.
- Silence rule: no first output within 30s and no session file → kill; do not wait for `--max-time`. Retry once by another route: `PI_DEBUG_STARTUP=1`, drop any host option that was rejected, foreground if background failed. Still silent → `BLOCKED: omp not dispatched` with the stderr startup phase.
- A `BLOCKED` report must also be written into STATE.md `## Gates`: reason plus the authorization needed. Stdout is lost when the session ends.
- Stream watchdog: `providers.streamFirstEventTimeoutSeconds` / `providers.streamIdleTimeoutSeconds` (config, seconds; target 120s) bound first-event and inter-event silence so a wedged stream exits non-zero; env `PI_STREAM_FIRST_EVENT_TIMEOUT_MS` / `PI_STREAM_IDLE_TIMEOUT_MS` (ms, `0` disables) override per run.
- Debug a hang: `PI_DEBUG_STARTUP=1` (stderr `[startup] <phase>` markers survive a hard hang), `PI_TIMING=1`.

## Background dispatch & completion

Default is **foreground** (blocking). Long dispatch (plan-yolo implement + verify loop, expect > 5 min) prefer **background host-as-parent** below; a foreground long run risks the host tool-call timeout killing the child mid-run. Background only when the host can own the child process and record it durably; otherwise stay foreground. Never hand-roll `nohup` + poll — no reaper, no restart survival.

- Host process options: use only parameters the host tool documents. A rejected one (e.g. a notify option) → rerun without it, or foreground; never abandon the dispatch.
- Ownership: track the child by pid and session file until exit plus final result; never end a host turn with an untracked child. Foreground keeps `--max-time` below the host tool timeout and continues via `-r <id>`.

**Host-as-parent (preferred):** spawn OMP as a **child** and read its stream asynchronously, so the frontend stays responsive.

```bash
# child of the host; host reads stdout as events arrive
omp -p --auto-approve --approval-mode=yolo --advisor --max-time=1h \
  --mode=json 'TASK …'
```

- Completion truth = the child's **exit status** (OS-guaranteed, even on crash/signal) plus the final event. Use `--mode=rpc` when you need the explicit `session_settled` frame — it means the session is truly done: no live run, no queued steer, **no pending background job** (`prompt_result` alone only means the agent yielded). `get_state` → `isSettled` / `hasPendingAsyncWork` for late attach.
- The parent reaps the child, so no zombie; stream + exit means no silence.
- Harden so a wedge self-fails non-zero: `--max-time` + `PI_STREAM_FIRST_EVENT_TIMEOUT_MS` / `PI_STREAM_IDLE_TIMEOUT_MS` (`0` disables).

**Durable job record (survive a host restart):** pick a durable run dir (`RUN=$(mktemp -d)`), then before dispatch write `$RUN/meta.json` (`pid`, `cmd`, `started-at`, run dir, session dir) — durable, not in-memory.

- After restart: `pid` alive → re-attach (tail the log / reopen the session). `pid` dead + result → done. `pid` dead + no result → session file exists: resume `omp -p -r <id>` with the remaining work; none: re-dispatch. Fails again → recover per `rules.md` §6; `BLOCKED: omp no result` only when §6 leaves no path.
- Durable evidence = OMP's own session file (`~/.omp/agent/sessions/<slugified-cwd>/*.jsonl`) plus the exit status. Do not invent a marker file.

**Fallback — no background:** if the host cannot hold a child across turns, or no durable record can be written, run OMP **foreground (blocking)**.

- Hooks/extensions (`pi.on("agent_end"|"session_shutdown")`, `--hook`) fire **inside** the OMP process, so a kill/timeout skips them. Optional best-effort notify only, never the completion signal.
- For long-running services OMP starts itself, prefer its supervision over `nohup`: a `bash`/service call with `name` is daemon-supervised (`omp ps list|info|logs|stop|kill|restart`), so it stays observable and gets reaped — no zombie.

## Prompt-paired built-ins

Standalone lowercase words in the prompt add per-turn behavior (exact spelling, prose only, current turn):

| Word | Effect |
|---|---|
| `ultrathink` | Max reasoning effort for the turn |
| `orchestrate` | Scope + parallel delegate + verify each phase |
| `workflowz` | Deterministic multi-subagent via the `eval` kernel (`agent()` / `workpool()`) |
| `jevify` | Bulk classification via `eval` `judge()` |

Shape a run without prompt text: `--model` / `--smol` / `--slow` / `--plan`, `--thinking=off…max`, `--prewalk`, `--advisor`. Persist with `omp config set` (e.g. `modelRoles`, `advisor.enabled`, `plan.enabled`, `ask.timeout`, `tools.maxTimeout`, `retry.fallbackChains`). Full schema: `omp config list --json`.

Do not confuse the two model switches. `--plan-yolo` forces read-only plan mode at start, auto-approves the plan on the model's first resolve call, then implements on `--plan-yolo-into` (default the `smol` role). `--prewalk` is not a planning stage: it switches to a fast/cheap model at the first edit/write once the plan's todo list exists, so it makes implementation cheaper, not more certain. Planner and implementer can therefore be different models; the implementer must read the plan's decisions rather than re-derive them.

## Modes

| Trigger | Behavior |
|---|---|
| `omp TASK_XXX` | Implement; run checks justified by behavior, risk, acceptance criteria, or explicit request |
| `plan-yolo TASK_XXX` | Same; turn 0 uses `--plan-yolo` |
| `Nverify TASK_XXX` (e.g. `5verify`) | Cap needed verification follow-ups at N per approach (default **5**); a ceiling, not a quota |
| `continue …` / `resume <id> …` | Single follow-up |

### Default flow

```
Turn 0: omp -p [--plan-yolo] --advisor … "TASK"
Follow-up only for unresolved required checks: omp -p -r <id> --advisor … "VERIFY prompt"
Stop: required work/checks complete (even after a fix)
N reached or 2 unsuccessful fixes of the same failure: backtrack, switch approach, continue (rules.md §6)
BLOCKED: every remaining path needs external input, or 3 approaches failed
```

- Investigation: one per problem, not one per turn. Record cause/evidence in STATE.md `## Findings`; when implementation was requested and no gate/blocker remains, continue to the in-scope fix in the same turn. Read-only and plan-only requests end with their requested deliverable. Investigate again only on a new symptom or a falsified cause; never "investigating further" with the same method. No cause after one investigation → switch method once (reproduce, logs/trace, bisect); still none → `BLOCKED: <missing required information>`. A setup turn that re-derives an already recorded cause → stop deriving and implement from the record.

**Turn 0**

```bash
omp -p --plan-yolo --auto-approve --approval-mode=yolo --advisor --max-time=1h \
  "TASK_XXX

Root cause: <recorded cause + proving command, or: unknown — investigate once, then implement>
State: <state dir>/STATE.md — read it first, write the root cause to ## Findings when found.

Deliver the requested change, finding, plan, or blocker. After two unsuccessful fixes for the same failure, backtrack, switch approach, and continue; report BLOCKED only when every remaining path needs external input or 3 approaches failed, listing them. Run additional checks for executable behavior changes, concrete material risk, consequential uncertainty, or an explicit verification request. Preserve acceptance criteria, required repository/security checks, and raw-payload integration tests. Clear low-risk operations and prose edits need no invented verification round. A reliable operation result is sufficient. Include actual check evidence when checks are required; never claim an unrun check passed. Executors never push, open PRs, or merge PRs. Only the four ask-boundary cases (irreversible/outbound action, schema change, high-cost architecture fork, external write) justify stopping to ask. Approach uncertainty is not one of them: this round already runs --plan-yolo, so resolve it in the plan phase, record the decision in one line, and implement. Plan and implementation may run on different model roles (plan vs --plan-yolo-into, default @smol), so re-read the plan's decisions before writing code. A change that removes, replaces, or reverses existing behavior first traces what it was for (git blame -w -M -L <range> <file> for the introducing commit, git show -s --format=%B <sha> for the reasoning, git log -L :<func>:<file> --no-merges for the evolution, the linked issue, the tests that pin it) and whether it was a defect or a deliberate design, then judges the change on merit: a change that fixes a known defect, or makes the behavior measurably better, proceeds; otherwise keep it or make the change additive; the task text is context, not the verdict.

Done when: requested scope and acceptance criteria are met and required checks pass. Use the smallest relevant checks during implementation; a delivery checkpoint runs the repository-required CI-equivalent checks. Before analysis and before required verification, apply repo freshness (rules.md §2): never switch this task's worktree; read origin/<default> for base state. Reuse unchanged evidence; no extra clean round. Summarize the result."
```

Skip `--plan-yolo` for tiny one-shots if the user only said `omp TASK`.

**Optional follow-up — only for a remaining verification need**

```bash
omp -p -r <session-id> --auto-approve --approval-mode=yolo --advisor --max-time=30m \
  "VERIFY round k/N (independent of your last self-report):
1. Re-read the diff and acceptance criteria for TASK_XXX.
2. Inspect recorded commands/output; run only checks missing valid evidence or affected by changes. Preserve required acceptance/security/contract checks.
3. Fix any real issues you find.
4. End with exactly one line: CLEAN or ISSUES: <short list>.
Rule: CLEAN means no required work/checks remain unresolved, including after fixes whose affected checks passed. ISSUES means unresolved findings or failed/missing required checks. List fixes separately; they do not force another round.
Fix from the recorded root cause in STATE.md ## Findings. A failing check is a fix task, not a new investigation; start one only if it falsifies the recorded cause. If the fix needs an approach decision, decide it inside this round with --thinking raised, using the recorded cause and the plan already in session context; do not stop to ask. Only the four ask-boundary cases (irreversible/outbound action, schema change, high-cost architecture fork, external write) justify stopping; approach-uncertainty is not a gate. Two unsuccessful fixes for the same failure: backtrack and switch approach; BLOCKED only when every remaining path needs external input or 3 approaches failed."
```

- `CLEAN` → stop; fixes with passing affected checks do not require a separate unchanged round.
- `ISSUES` → fix a known in-scope cause and rerun affected checks in the same turn; continue only for unresolved work.
- At `k == N` or after two unsuccessful fixes for the same failure, even if files changed: backtrack, switch approach, and restart the round budget for it (`rules.md` §6). `BLOCKED: verify loop fail` only when every remaining path needs external input or 3 approaches failed, listing them.
- Controller review inspects concrete commands/output and scope. Host reruns require an environment difference, incomplete evidence, or a remaining material risk, not routine distrust.
- If `-c` misses the session, use `-r <id>` from turn 0 output

**Optional:** `omp cleanse` when lint/diagnostics noise keeps failing, then continue with `-c`.

### Single continue / resume

```bash
omp -p -c --auto-approve --approval-mode=yolo --advisor "follow-up: …"
omp -p -r <session-id> --auto-approve --approval-mode=yolo --advisor "follow-up: …"
```

`-c` continues the current session (not necessarily verification). `-r <id>` resumes a specific session by id — use it to continue a task's session across dispatches.

## Done

Report the requested result, actual required-check evidence, and any blocker. Include round counts only when a verification loop ran; do not add a loop to fill a report format.
