#!/usr/bin/env bash
# SessionStart hook — Akasha session context injection
# Injects: date, daily status, weekly freshness, streak, inbox, active materials
# Runs on session start (advisory, non-blocking)

set -euo pipefail

VAULT="$HOME/Documents/Gio Files/AKASHA/akasha-pkm-ref"

# Today's date
DATE=$(date '+%Y-%m-%d')
DAY=$(date '+%A')

# Check daily note
DAILY_FILE="$VAULT/Daily/$DATE.md"
if [ -f "$DAILY_FILE" ]; then
  DAILY_STATUS="✅ today's note exists"
else
  DAILY_STATUS="❌ no daily note yet"
fi

# Days since last weekly review — use file mtime for reliability
LAST_WEEKLY=$(ls -1t "$VAULT/Reviews/"*.md 2>/dev/null | head -1)
if [ -n "$LAST_WEEKLY" ]; then
  FILE_MTIME=$(stat -c %Y "$LAST_WEEKLY" 2>/dev/null || date -r "$LAST_WEEKLY" +%s 2>/dev/null || echo 0)
  NOW=$(date +%s)
  DIFF=$(( (NOW - FILE_MTIME) / 86400 ))
  [ "$DIFF" -lt 0 ] && DIFF=0
  WEEKLY_AGE="$DIFF days since last weekly"
else
  WEEKLY_AGE="no weekly review yet"
fi

# Streak
STREAK_FILE="$VAULT/.akasha/streak.md"
if [ -f "$STREAK_FILE" ]; then
  # Count date lines (YYYY-MM-DD) as streak entries
  STREAK_LEN=$(grep -cP '^\d{4}-\d{2}-\d{2}' "$STREAK_FILE" 2>/dev/null || echo "?")
  STUDY=$(grep -c "study: ✅" "$STREAK_FILE" 2>/dev/null && echo "✅" || echo "❌")
  MOVE=$(grep -c "move: ✅" "$STREAK_FILE" 2>/dev/null && echo "✅" || echo "❌")
  CONSUME=$(grep -c "consume: ✅" "$STREAK_FILE" 2>/dev/null && echo "✅" || echo "❌")
  STREAK="Streak: $STREAK_LEN days (study $STUDY move $MOVE consume $CONSUME)"
else
  STREAK="Streak: not initialized"
fi

# Inbox count
INBOX_COUNT=$(find "$VAULT/Inbox" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l)
INBOX="Inbox: $INBOX_COUNT pending"

# Active materials (max 3)
MATERIALS=$(ls -1 "$VAULT/StudyMaterials/active/"*.md 2>/dev/null | head -3 | while read f; do
  echo "  - $(basename "$f" .md)"
done)

# Output context block
echo "# Session Context — $DATE ($DAY)"
echo "$DAILY_STATUS"
echo "$WEEKLY_AGE"
echo "$STREAK"
echo "$INBOX"
if [ -n "$MATERIALS" ]; then
  echo "Active materials:"
  echo "$MATERIALS"
fi
echo ""
