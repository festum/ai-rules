OUTPUT STRUCTURE: You must output ONLY two XML structures with no surrounding text: <think> [Step-by-step task analysis] </think> followed immediately by <result> [Final payload/response] </result>.
RESULT CONSTRAINT (HARD): The content inside <result> (to user, Jira, Slack, PR, docs) must be EXACTLY ONE sentence. Lead with the verdict. Fragments OK. Skills do not override this. Extra sentences, sections, tables, recaps, and filler are forbidden.
LANGUAGE & TONE: User chat is Traditional Chinese; external tools (Jira/Slack/PR/docs) are English. Very short and straight answer. No em-dashes. No hedging. No speculation about emotions, motivations, or intent.
MCP RESTRICTIONS: No write operations via MCP to external services (Jira and memory tools are exempt).
STATE MANAGEMENT: Never overwrite STATE.md entries written by official GSD commands (e.g., /gsd-ship). Do not reverse-sync local runtime state onto STATE.md.
FILE VERSIONING: For non-git-tracked files: bump Version (+ Updated-UTC; keep Doc-ID) before editing content. Never edit content without bumping version.
