#!/usr/bin/env bash
set -euo pipefail
payload=$(cat)
cwd=$(printf '%s' "$payload" | jq -r '.cwd')
cd "$cwd" || exit 0
[ -d .git ] || exit 0
git add -- Knowledge/ Inbox/ Daily/ Reviews/ Recaps/ Goals/ StudyMaterials/ .akasha/ 2>/dev/null || true
git diff --cached --quiet && exit 0
git commit -q -m "akasha: auto-commit $(date '+%Y-%m-%d %H:%M')" || true
