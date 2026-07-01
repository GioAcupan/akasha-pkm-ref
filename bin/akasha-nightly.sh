#!/usr/bin/env bash
set -euo pipefail

# Akasha nightly pipeline
# Steps by sprint:
#   [1/5] Schema sync — Sprint 6 (akasha-sync-schema.sh)
#   [2/5] Process inbox — Sprint 2 (akasha-ingest agent)
#   [3/5] Goal adjustment — Sprint 5 (akasha-goal-tracker agent)
#   [4/5] Streak update — Sprint 3 (update-streak prompt)
#   [5/5] Hot cache update — Sprint 2+

VAULT_PATH="$(cd "$(dirname "$0")/.." && pwd)"

# Load credentials
if [ -f "$VAULT_PATH/.env" ]; then
  set -a; source "$VAULT_PATH/.env"; set +a
fi

echo "=== Akasha Nightly Pipeline ==="
echo ""

# Step 1: Schema sync
echo "[1/5] Syncing schema to R2..."
if [ -f "$VAULT_PATH/bin/akasha-sync-schema.sh" ]; then
  bash "$VAULT_PATH/bin/akasha-sync-schema.sh" 2>&1 | tail -1
else
  echo "  (not yet implemented — Sprint 6+)"
fi
echo ""

# Step 2: Process inbox
echo "[2/5] Processing inbox..."
if [ -f "$VAULT_PATH/bin/prompts/process-inbox.md" ]; then
  cmd -p "$(cat "$VAULT_PATH/bin/prompts/process-inbox.md")" \
    --yolo --skip-onboarding --max-turns 60 2>&1 | tail -1
else
  echo "  (not yet implemented — Sprint 2+)"
fi
echo ""

# Step 3: Goal adjustment
echo "[3/5] Adjusting goals..."
if [ -f "$VAULT_PATH/bin/prompts/goal-adjust.md" ]; then
  cmd -p "$(cat "$VAULT_PATH/bin/prompts/goal-adjust.md")" \
    --yolo --skip-onboarding --max-turns 15 2>&1 | tail -1
else
  echo "  (not yet implemented — Sprint 5+)"
fi
echo ""

# Step 4: Streak update
echo "[4/5] Updating streak..."
cmd -p "$(cat "$VAULT_PATH/bin/prompts/update-streak.md")" \
  --yolo --skip-onboarding --max-turns 8 2>&1 | tail -1
echo ""

# Step 5: Hot cache update
echo "[5/5] Updating hot cache..."
if [ -f "$VAULT_PATH/bin/prompts/update-hotcache.md" ]; then
  cmd -p "$(cat "$VAULT_PATH/bin/prompts/update-hotcache.md")" \
    --yolo --skip-onboarding --max-turns 8 2>&1 | tail -1
else
  echo "  (not yet implemented — Sprint 2+)"
fi
echo ""

echo "=== Nightly complete ==="
