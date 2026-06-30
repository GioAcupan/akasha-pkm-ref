#!/usr/bin/env bash
set -euo pipefail

# akasha-notify.sh — send Expo push notification when a capture session fails parsing.
# Usage: akasha-notify.sh <session_id>

SESSION_ID="${1:-}"
if [ -z "$SESSION_ID" ]; then
  echo "Usage: akasha-notify.sh <session_id>" >&2
  exit 1
fi

: "${EXPO_PUSH_TOKEN:?EXPO_PUSH_TOKEN not set}"

curl -s -H "Content-Type: application/json" \
  -X POST "https://exp.host/--/api/v2/push/send" \
  -d "$(cat <<EOF
{
  "to": "$EXPO_PUSH_TOKEN",
  "title": "Akasha Alert: Parse Failed",
  "body": "Session '$SESSION_ID' could not be read. Please rescan.",
  "data": {
    "session_id": "$SESSION_ID",
    "type": "parse_failure"
  }
}
EOF
)"
