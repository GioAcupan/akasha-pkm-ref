#!/usr/bin/env bash
set -euo pipefail

# WSL compat: use jq.exe when native jq isn't available
command -v jq.exe >/dev/null 2>&1 && jq() { jq.exe "$@"; }
payload=$(cat | tr -d '\r')
fp=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""' | tr -d '\r')
if [[ "$fp" == *"/Inbox/_processed/"* ]]; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",
    permissionDecision:"deny",
    permissionDecisionReason:"Inbox/_processed holds immutable raw captures. Create or edit a note under Knowledge/ instead."}}'
fi
exit 0
