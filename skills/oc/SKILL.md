---
name: oc
description: Delegate work to the opencode CLI (Docker-first) — one-off runs, full-autonomy `/ulw` and `/ulw-loop` runs, and multi-round Plan/Dev cycles with independent PM-style verification.
user-invocable: true
---

# oc — Delegating Work to opencode

Trigger when the user's message starts with one of the mode keywords below, followed by a task description (`TASK_XXX`).

## Modes

| Trigger | Behavior |
|---|---|
| `oc TASK_XXX` | One-off task, run directly via `opencode`. |
| `ulw TASK_XXX` | Full-agent, fully autonomous run via `opencode /ulw` — runs to completion. |
| `ulw-loop TASK_XXX` | Same as `ulw`, but opencode runs its own built-in self-review loop before returning. |
| `Nplan TASK_XXX` (e.g. `20plan TASK_XXX`) | Design-only, N-round reviewed plan — no code written. |
| `Ndev TASK_XXX` (e.g. `20dev TASK_XXX`) | Implements the plan from `Nplan`, N-round reviewed, test-first. |
| `NPlan+MDev TASK_XXX` (e.g. `10plan+20dev TASK_XXX`) | Chain: run `Nplan`, then feed its plan into `Mdev`. |

## Runtime Default

Prefer the `opencode` instance running in Docker. Fall back to the local `opencode` binary only if Docker is unavailable, and tell the user why.

## `oc` — Single Task

Simple, one-shot task with no multi-agent review needed.

```bash
opencode run "TASK_XXX"
```

## `ulw` — Full Autonomy

All agents engage; opencode runs autonomously to completion. Don't interrupt with intermediate approvals.

```bash
opencode /ulw "TASK_XXX"
```

## `ulw-loop` — Self-Reviewing Autonomy

Same as `ulw`, but invoke `/ulw-loop` so opencode self-reviews internally before handing control back.

```bash
opencode /ulw-loop "TASK_XXX"
```

## `Nplan` — Multi-Round Design Review

`N` is the max round count (`20plan TASK_XXX` → N=20). Never write code in this mode — output is a plan document only.

1. Run `opencode /ulw` on `TASK_XXX` for deep code analysis and design; output a plan, no implementation.
2. Save/update the plan at `{REPO}/docs/plans/YYYY-MM-DD_{FEATURE}.md`.
3. Dispatch an independent external reviewer agent to deep-analyze the plan against the codebase — never trust the plan author's self-report.
4. If the reviewer raises issues, feed them back into step 1 for a revised plan.
5. Repeat until either:
   - `N` rounds are reached, or
   - 3 consecutive rounds are clean from both sides.
6. Report the final round count and exit reason.

## `Ndev` — Multi-Round Implementation

`N` is the max round count (`20dev TASK_XXX` → N=20). Requires the plan document produced by `Nplan` at `{REPO}/docs/plans/YYYY-MM-DD_{FEATURE}.md`.

Per round:

```
ulw-loop (opencode self-reviews until it thinks it's done)
    ↓
PM independent verification (external perspective, never trust self-report)
    ↓
issues found → ulw-loop runs again
3 clean rounds in a row → terminate
```

1. **`ulw-loop`**: run `opencode /ulw-loop`. Write the minimal necessary test cases from the plan's requirements and edge cases first, then implement, self-reviewing until opencode itself considers the round done.
2. **Independent verification**: dispatch an external reviewer agent (PM perspective) that re-runs tests and re-reads the diff itself — never trust opencode's self-report.
3. If the reviewer finds issues, go back to step 1 for another `ulw-loop` round.
4. Exit when either:
   - `N` rounds are reached, or
   - 3 consecutive rounds are clean from both sides.

**Done criteria, every round, either side:** lint passes, unit tests pass, regression tests pass, integration tests pass, and the plan document is updated to reflect what changed.

## Combined Mode

`NPlan+MDev TASK_XXX` chains the two: run `Nplan` first to produce and lock the plan document, then run `Mdev` against that plan. Example: `10plan+20dev TASK_XXX` = plan with up to 10 rounds, then implement with up to 20 rounds.
