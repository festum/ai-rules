---
name: engineering-guardrails
description: Personal engineering guardrails — minimal-change discipline, diagnose before asking, protect the data model SSOT, and gate every commit on self-review plus tests/lint/coverage.
user-invocable: true
---

# Engineering Guardrails

Cross-cutting discipline that applies to every task, not just one workflow step.

## Minimal Changes

Make only the change required for the task.

- No new files, no moving code, no refactoring unless strictly necessary.
- Before writing code, ask: is this change required? If not, skip it.

## Diagnose Before Asking

Exhaust self-service options before asking the user for help.

- Search the repo, read the code, run CLI tools and check logs to find the root cause.
- When escalating, report what was tried and what was found — never escalate empty-handed.

## Data Model SSOT

The data model is the single source of truth.

- Never create or modify data model fields/types without explicit user approval.
- If a task seems to require a data model change, pause and ask before touching it.

## Pre-Commit Gate

Before every `git commit`:

1. Self-review the diff.
2. Run and pass tests, lint, and coverage checks.

Do not skip this gate, even for small changes.
