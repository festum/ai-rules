---
name: open-pr
description: Create a clean, review-ready pull request with a good title, structured description, linked issues, and appropriate reviewers.
user-invocable: true
---

# Creating a PR

Package work into a pull request that's easy to review and merge.

## Workflow

### 1. Prepare the Branch

Sync the base branch, commit, and squash per `git-commit` (merge, not rebase; push only after the human says "push").

```bash
# Check what will be in the PR
git log origin/main..HEAD --oneline
git diff origin/main --stat
```

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

If the repo has `.github/pull_request_template.md`, use only that template's content — no extra sections, no implementation notes. Keep the description very brief. Fill in the template's required fields (e.g. feature owner, ticket ID) from the repo's `AGENTS.md`/`CLAUDE.md` or the branch name; ask if still unknown.

### 4. Self-Review

Before requesting review:
- Review every line of the diff
- Remove debug code (`console.log`, `TODO`, commented-out code, comments)
- Verify tests pass
- Verify types
- Verify lint
- Check for files that shouldn't be committed (`.env`, lockfile conflicts)

Personal convention: before committing, also run coverage checks.

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

- A failing approval-gate job (change-record or sign-off check) means the PR isn't approved yet — do not treat it as a CI failure.
