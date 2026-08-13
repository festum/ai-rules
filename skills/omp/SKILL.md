---
name: omp
description: Delegate work to the Oh My Pi (`omp`) CLI with native multi-round verify via continue/resume + advisor. Hermes/OpenClaw only.
user-invocable: true
---

# omp — Delegating Work to Oh My Pi

Hand work to the local `omp` CLI ([can1357/oh-my-pi](https://github.com/can1357/oh-my-pi)). Linked for Hermes / OpenClaw only.

**With GSD:** for non-trivial coding work, prefer GSD (`gsd-*`) for plan/execute; use this skill's omp verify loop (`-c` / `Nverify`) after implementation. Tiny one-shots can stay omp-only. Do not edit the GSD pack from here.

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
Stop:     N reached, or 3 consecutive CLEAN verifies
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
- Stop when `consecutive_clean >= 3` or `k == N`
- If `-c` misses the session, use `-r <id>` from turn 0 output

**Optional:** `omp cleanse` when lint/diagnostics noise keeps failing, then continue with `-c`.

### Single continue / resume

```bash
omp -p -c --auto-approve --approval-mode=yolo --advisor "follow-up: …"
omp -p -r <session-id> --auto-approve --approval-mode=yolo --advisor "follow-up: …"
```

## Done

Report turn count, stop reason (`3× CLEAN` / `N reached` / error), last CLEAN/ISSUES line, and useful stdout.
