---
name: creating-pr
description: Create a clean, review-ready pull request with a good title, structured description, linked issues, and appropriate reviewers.
user-invocable: true
---

# Creating a PR

Package work into a pull request that's easy to review and merge.

## Workflow

### 1. Prepare the Branch

Before creating the PR:

```bash
git fetch origin
git rebase origin/main  # or merge, depending on project convention

# Check what will be in the PR
git log origin/main..HEAD --oneline
git diff origin/main --stat
```

Squash fixup commits if the project prefers clean history. Keep logical commits separate if the project prefers granular history.

Personal convention: if the branch is behind the base branch, auto pull/merge `main` and resolve conflicts without asking.

Commit message rules:
- Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/), ≤15 words, scope optional.
- Do not add `Co-Authored-By: XYZ` trailer.

### 2. Write the Title

Format: `<ticket_id_if_exists> <type>: <short description>`

| Type | When |
|------|------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `docs` | Documentation only |
| `test` | Adding or fixing tests |
| `chore` | Build, CI, deps, or tooling |
| `perf` | Performance improvement |

Examples:
- `feat: add dark mode toggle to settings page`
- `fix: prevent duplicate form submissions on checkout`
- `refactor: extract auth middleware into shared module`

### 3. Write the Description

If the repo has `.github/pull_request_template.md`, use only that template's content — no extra sections, no implementation notes. Keep the description very brief. Fill in feature owner (`@secilozdemir`) and the Jira ticket (`ON-XXXX`).

### 4. Self-Review

Before requesting review:
- Review every line of the diff
- Remove debug code (`console.log`, `TODO`, commented-out code, comments)
- Verify tests pass
- Verify types
- Verify lint
- Check for files that shouldn't be committed (`.env`, lockfile conflicts)

Personal convention: before committing, also run coverage checks and the `TF plan and apply DEV from branch (manual)` GitHub Action (if exists) to deploy and verify integration tests pass in DEV.

### 5. Create the PR

```bash
git push -u origin HEAD
gh pr create --title "<title>" --body "$(cat <<'EOF'
<.github/pull_request_template.md>

<very_brief_summary>

EOF
)"
```

Personal convention: use the `gh` CLI exclusively for all PR interactions (create, review, comment, merge).

### 6. Request Review

- Tag the appropriate reviewers (code owners, domain experts)
- If the PR is large (>400 lines), add a comment explaining the best order to review files
- If the PR depends on another PR, note it in the description
- Label the PR appropriately (feature, bug, breaking change, etc.)

## Tips

- Small PRs get reviewed faster — aim for <300 lines changed
- If a PR is too big, split it into stacked PRs
- Screenshots/recordings for UI changes make review much faster
- Draft PRs are useful for early feedback before the work is complete

## CI Notes (personal)

- A failing `validate-and-record-change` job means the PR isn't approved yet — do not treat it as a CI failure.
