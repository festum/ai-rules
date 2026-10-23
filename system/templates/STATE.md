# <key> - <title>
key: <key> | aliases: <old IDs or none> | ticket: <URL or none>
repos: <repo>, <repo>
status: <prepared|planned|reviewed|handed-off|in-progress|verified|delivered|pr-loop|blocked|done>
control: <unattended-auto|interactive|human>
updated: <UTC> | by: <hermes|omp|claude|cursor|opencode|human>

## Scope & constraints
## Decisions locked
- <decision> | why: <reason> | do not reopen
## Repos & worktrees
- <repo> | branch <branch> | worktree <path> | base <branch>
## Status
Done: …
Not done: …
Next: …
## Gotchas
- <trap> | symptom: <what breaks if ignored> | guard: <what to do>
## Findings
- cause: <root cause> | evidence: <command that proves it> | at: <UTC>
## Open questions
- <question> | known: <current assumption> | resolve-by: <when the answer is needed>
## Verification
- <UTC> <command or check> → CLEAN|ISSUES: …
## Gates
## Sessions
- omp: <name> (<session id>) (<cwd>) | claude: <session id> | pr: <URL>
## Plan
current: plan-v<N>.md (delegate only)
