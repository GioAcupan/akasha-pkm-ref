#!/usr/bin/env bash
set -euo pipefail

# Akasha nightly pipeline
# Steps by sprint:
#   [1/4] Process inbox — Sprint 2 (akasha-ingest agent)
#   [2/4] Goal adjustment — Sprint 5 (akasha-goal-tracker agent)
#   [3/4] Streak update — Sprint 3 (update-streak prompt)
#   [4/4] Hot cache update — Sprint 2+

VAULT_PATH="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Akasha Nightly Pipeline ==="
echo ""

# Step 1: Process inbox
echo "[1/4] Processing inbox..."
if [ -f "$VAULT_PATH/bin/prompts/process-inbox.md" ]; then
  cmd -p "$(cat "$VAULT_PATH/bin/prompts/process-inbox.md")" \
    --yolo --skip-onboarding --max-turns 60 2>&1 | tail -1
else
  echo "  (not yet implemented — Sprint 2+)"
fi
echo ""

# Step 2: Goal adjustment
echo "[2/4] Adjusting goals..."
if [ -f "$VAULT_PATH/bin/prompts/goal-adjust.md" ]; then
  cmd -p "$(cat "$VAULT_PATH/bin/prompts/goal-adjust.md")" \
    --yolo --skip-onboarding --max-turns 15 2>&1 | tail -1
else
  echo "  (not yet implemented — Sprint 5+)"
fi
echo ""

# Step 3: Streak update
echo "[3/4] Updating streak..."
cmd -p "$(cat "$VAULT_PATH/bin/prompts/update-streak.md")" \
  --yolo --skip-onboarding --max-turns 8 2>&1 | tail -1
echo ""

# Step 4: Hot cache update
echo "[4/4] Updating hot cache..."
if [ -f "$VAULT_PATH/bin/prompts/update-hotcache.md" ]; then
  cmd -p "$(cat "$VAULT_PATH/bin/prompts/update-hotcache.md")" \
    --yolo --skip-onboarding --max-turns 8 2>&1 | tail -1
else
  echo "  (not yet implemented — Sprint 2+)"
fi
echo ""

echo "=== Nightly complete ==="
