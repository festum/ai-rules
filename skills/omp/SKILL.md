---
name: omp
description: Delegate work to the Oh My Pi (`omp`) CLI with native multi-round verify via continue/resume + advisor. Hermes/OpenClaw only.
user-invocable: true
---

# omp — Delegating Work to Oh My Pi

Hand work to the local `omp` CLI ([can1357/oh-my-pi](https://github.com/can1357/oh-my-pi)). Linked for Hermes / OpenClaw only.

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

Default unattended base:

```bash
omp -p --auto-approve --approval-mode=yolo --advisor --max-time=1h
```

Override `--max-time` / models when specified. Use `--cwd` when needed. If `omp` is missing from `PATH`, stop.

## Shared task state (rules.md §8)

- Before dispatch: resolve the key (ticket ID → current branch → aliases → STATE.md worktree match), read or create `${AGENT_STATE_DIR:-$HOME/.local/state/agents}/<key>/STATE.md` (fill `repos:`; task without a ticket: create the branch named after the key), and put the state folder path into the prompt.
- After every round: write the omp session id to `## Sessions`, the round verdict to `## Verification` (`<UTC> <command or check> → CLEAN|ISSUES: …`), and append one line to `log.md`.

## Liveness & failure detection

`omp -p` fails loudly: non-zero exit, message on **stderr**, stdout can stay empty. A caller that reads only stdout sees nothing — treat that as failure, not success.

- Preflight before dispatch: `command -v omp`, then `omp --version`. Missing or non-zero → stop, report `BLOCKED`. Never assume OMP ran.
- Capture **exit code and stderr**, not just stdout. Exit ≠ 0, empty stdout, or no result → failure.
- Proof it started: a new `~/.omp/agent/sessions/<slugified-cwd>/*.jsonl` after dispatch (no file → OMP never ran). `omp ps --json` adds daemon-supervised state.
- Silence rule: no first output within N seconds and no session file → kill and report `BLOCKED: omp not started`; do not wait for `--max-time`.
- A `BLOCKED` report must also be written into STATE.md `## Gates` (rules.md §8): reason plus the authorization needed. Stdout is lost when the session ends.
- Debug a hang: `PI_DEBUG_STARTUP=1` (stderr `[startup] <phase>` markers survive a hard hang), `PI_TIMING=1`. Built-in stream deadlines `PI_STREAM_FIRST_EVENT_TIMEOUT_MS` / `PI_STREAM_IDLE_TIMEOUT_MS` (`0` disables).

## Background dispatch & completion

Default is **foreground** (blocking). Go background only when the host can own the child process and record it durably; otherwise stay foreground. Never hand-roll `nohup` + poll — no reaper, no restart survival.

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

- After restart: `pid` alive → re-attach (tail the log / reopen the session). `pid` dead + result → done. `pid` dead + no result → `BLOCKED: omp no result`, kill, escalate.
- Durable evidence = OMP's own session file (`~/.omp/agent/sessions/<slugified-cwd>/*.jsonl`) plus the exit status. Do not invent a marker file.

**Fallback — no background:** if the host cannot hold a child across turns, or no durable record can be written, run OMP **foreground (blocking)**. `nohup` + poll has no reaper and no restart survival — last resort only, with a bounded deadline.

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

## Modes

| Trigger | Behavior |
|---|---|
| `omp TASK_XXX` | Implement + multi-round verify (default) |
| `plan-yolo TASK_XXX` | Same; turn 0 uses `--plan-yolo` |
| `Nverify TASK_XXX` (e.g. `5verify`) | Cap verify continues at N (default **5**) |
| `continue …` / `resume <id> …` | Single follow-up |

### Default flow

```
Turn 0:   omp -p [--plan-yolo] --advisor … "TASK"
Turn 1…N: omp -p -c --advisor … "VERIFY prompt"
Stop:     N reached, 3 consecutive CLEAN verifies, or 2 consecutive rounds still ISSUES (BLOCKED)
```

**Turn 0**

```bash
omp -p --plan-yolo --auto-approve --approval-mode=yolo --advisor --max-time=1h \
  "TASK_XXX

Done when: lint + unit + relevant regression/integration pass; summarize what changed."
```

Skip `--plan-yolo` for tiny one-shots if the user only said `omp TASK`.

**Turns 1…N — verify via continue**

```bash
omp -p -c --auto-approve --approval-mode=yolo --advisor --max-time=30m \
  "VERIFY round k/N (independent of your last self-report):
1. Re-read the diff and acceptance criteria for TASK_XXX.
2. Re-run lint and the relevant tests yourself.
3. Fix any real issues you find.
4. End with exactly one line: CLEAN or ISSUES: <short list>."
```

- `CLEAN` → consecutive_clean++
- `ISSUES` → fix in that continue turn; consecutive_clean = 0
- Stop when `consecutive_clean >= 3`, or `k == N`, or two consecutive rounds still end `ISSUES` → stop and report `BLOCKED: verify loop fail` (governance: hermes.md §5.1)
- If `-c` misses the session, use `-r <id>` from turn 0 output

**Optional:** `omp cleanse` when lint/diagnostics noise keeps failing, then continue with `-c`.

### Single continue / resume

```bash
omp -p -c --auto-approve --approval-mode=yolo --advisor "follow-up: …"
omp -p -r <session-id> --auto-approve --approval-mode=yolo --advisor "follow-up: …"
```

## Done

Report turn count, stop reason (`3× CLEAN` / `N reached` / error), last CLEAN/ISSUES line, and useful stdout.
