#!/usr/bin/env bash
# Print a Claude Code session transcript as plain USER/ASSISTANT/AGENT text,
# without tool calls, tool output, thinking, API errors, compaction summaries,
# local command echoes, skill bodies, task notifications, or system reminders.
set -euo pipefail

arg=${1:?usage: transcript.sh <session.jsonl | session-id> [project-dir]}
f=$arg
if [ ! -f "$f" ]; then
  id=$(basename "${arg%.jsonl}")
  proj=${2:-"$HOME/.claude/projects/$(pwd -P | sed 's#[^A-Za-z0-9]#-#g')"}
  f="$proj/$id.jsonl"
  if [ ! -f "$f" ]; then
    f=$(find "$HOME/.claude/projects" -maxdepth 2 -name "$id.jsonl" -print -quit 2>/dev/null || true)
  fi
fi
[ -n "$f" ] && [ -f "$f" ] || { echo "ERROR: transcript not found: $arg" >&2; exit 1; }

jq -r '
  select((.isSidechain // false) == false)
  | select((.isApiErrorMessage // false) | not)
  | select((.isCompactSummary // false) | not)
  | if .type == "user" then
      (if (.message.content | type) == "string" then .message.content
       else [.message.content[]? | select(.type == "text") | .text] | join("\n") end) as $t
      | select($t != "")
      | select(($t | test("^\\s*<(local-command|command-name|command-message|command-args)")) | not)
      | select(($t | startswith("Base directory for this skill:")) | not)
      | select(($t | test("<task-notification>")) | not)
      | if ($t | test("^\\s*Another Claude session sent a message")) then "AGENT: " + $t else "USER: " + $t end
    elif .type == "assistant" then
      ([.message.content[]? | select(.type == "text") | .text] | join("\n")) as $t
      | select($t != "")
      | "ASSISTANT: " + $t
    else empty end
' "$f" | perl -0pe 's#<system-reminder>.*?</system-reminder>##gs; s/\n{3,}/\n\n/g'
