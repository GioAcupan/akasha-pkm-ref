#!/usr/bin/env bash
set -euo pipefail

# WSL compat: use jq.exe when native jq isn't available
command -v jq.exe >/dev/null 2>&1 && jq() { jq.exe "$@"; }
payload=$(cat | tr -d '\r')
cwd=$(printf '%s' "$payload" | jq -r '.cwd' | tr -d '\r')
cd "$cwd" || exit 0
[ -d .git ] || exit 0
git add -- Knowledge/ Inbox/ Daily/ Reviews/ Recaps/ Goals/ StudyMaterials/ .akasha/ 2>/dev/null || true
git diff --cached --quiet && exit 0
git commit -q -m "akasha: auto-commit $(date '+%Y-%m-%d %H:%M')" || true
