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

# Extract user message text using Node.js (portable JSON parsing)
user_msg=$(echo "$payload" | node -e "
  process.stdin.on('data', d => {
    try {
      const p = JSON.parse(d);
      const msgs = p.messages || [];
      const last = msgs.filter(m => m.role === 'user').pop();
      console.log(last?.content?.[0]?.text || last?.content || '');
    } catch(e) {
      console.log('');
    }
  });
")

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
node -e "
  console.log(JSON.stringify({
    systemMessage: 'Available Akasha commands:\n\n' +
      '  /akasha-review    — Smart router: daily/weekly/monthly review\n' +
      '  /akasha-ingest    — Process one inbox item\n' +
      '  /akasha-lint      — Vault hygiene report (read-only)\n' +
      '  /akasha-query     — Search or status dashboard\n' +
      '  /akasha-daily     — Scaffold today\\'s daily note\n' +
      '  /akasha-weekly    — Weekly review ritual\n' +
      '  /akasha-recap     — Period recap (weekly/monthly/semester)\n' +
      '  /akasha-capture   — Quick seed note creation\n' +
      '  /akasha-goal-set  — Create goals at any cascade level\n' +
      '  /akasha-goal-check— Audit goals vs recent activity\n' +
      '  /akasha-search    — Search knowledge base\n' +
      '  /akasha-adopt     — Migrate existing vault into Akasha\\n\\n' +
      'Tip: type /akasha-<command> to run one.'
  }));
"
