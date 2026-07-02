#!/usr/bin/env bash
# Stop event hook — skill discovery
# When user asks "help", "skills", "what can you do", "commands", or "available",
# inject a listing of all /akasha-* commands.
# Anti-spam: only triggers once per 3 turns (tracked via cache file).
set -euo pipefail

CACHE="$HOME/.commandcode/.skill-discovery-cache"
TURN_FILE="$HOME/.commandcode/.turn-counter"

# Read stdin payload
payload=$(cat)

# Auto-increment turn counter (Stop hook fires every turn)
TURN=0
[ -f "$TURN_FILE" ] && TURN=$(cat "$TURN_FILE" 2>/dev/null || echo 0)
TURN=$((TURN + 1))
echo "$TURN" > "$TURN_FILE"

# Extract user message text using jq (consistent with other hooks)
user_msg=$(printf '%s' "$payload" | jq -r '.messages // [] | map(select(.role == "user")) | last | .content[0].text // .content // ""' 2>/dev/null || echo "")

# Normalize to lowercase for matching
lower_msg=$(echo "$user_msg" | tr '[:upper:]' '[:lower:]')

# Check for trigger keywords — strict list only
triggered=0
for kw in "help" "skills" "what can you do" "commands" "available"; do
  case "$lower_msg" in
    *"$kw"*) triggered=1; break ;;
  esac
done

# No trigger — output empty JSON (no action)
[ "$triggered" -eq 0 ] && echo '{}' && exit 0

# Anti-spam: read last trigger turn
LAST_TRIGGER=0
[ -f "$CACHE" ] && LAST_TRIGGER=$(cat "$CACHE" 2>/dev/null || echo 0)

# Only trigger if 3+ turns have passed since last trigger
GAP=$((TURN - LAST_TRIGGER))
if [ "$GAP" -lt 3 ]; then
  echo '{}'
  exit 0
fi

# Update cache
echo "$TURN" > "$CACHE"

# Inject system message with skill listing
SKILL_LIST='Available Akasha commands:

  /akasha-review    — Smart router: daily/weekly/monthly review
  /akasha-ingest    — Process one inbox item
  /akasha-lint      — Vault hygiene report (read-only)
  /akasha-query     — Search or status dashboard
  /akasha-daily     — Scaffold today'\''s daily note
  /akasha-weekly    — Weekly review ritual
  /akasha-recap     — Period recap (weekly/monthly/semester)
  /akasha-capture   — Quick seed note creation
  /akasha-goal-set  — Create goals at any cascade level
  /akasha-goal-check— Audit goals vs recent activity
  /akasha-search    — Search knowledge base
  /akasha-adopt     — Migrate existing vault into Akasha

Tip: type /akasha-<command> to run one.'

jq -n --arg msg "$SKILL_LIST" '{systemMessage: $msg}'
