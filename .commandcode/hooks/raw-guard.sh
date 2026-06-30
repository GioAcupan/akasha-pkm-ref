#!/usr/bin/env bash
set -euo pipefail
payload=$(cat)
fp=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')
if [[ "$fp" == *"/Inbox/_processed/"* ]]; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",
    permissionDecision:"deny",
    permissionDecisionReason:"Inbox/_processed holds immutable raw captures. Create or edit a note under Knowledge/ instead."}}'
fi
exit 0
