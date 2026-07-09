---
name: open-pr
description: 開PR
---

## Commits

- Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/), ≤15 words, scope optional.
- Do **not** add `Co-Authored-By: Claude` trailer.
- Before committing: 
  - self code review, pass tests, lint, and coverage. 
  - Run "TF plan and apply DEV from branch (manual)" to deploy and verify int test is pass in dev.

## Creating a PR

- Use `.github/pull_request_template.md`. Keep the summary **very brief**.
- Fill in: `Feature owner: @MohitChandna` and `Jira: ON-XXXX`.
- If the branch is out-of-date with base, auto pull/merge `main` and resolve conflicts.
- Use `gh` CLI exclusively for all PR interactions.

## CI

- A failing `validate-and-record-change` job means the PR isn't approved yet — do **not** treat it as a CI failure.
