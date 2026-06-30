# /akasha-status — System dashboard

Shows the current state of the Akasha system at a glance. Read-only, instant, no side effects.

## Behavior

1. Delegates to the `akasha-query` agent in status mode
2. No input arguments
3. Pulls data from multiple sources: `Inbox/`, `.akasha/streak.md`, `Knowledge/_domains.md`, git log, `.akasha/hot.md`
4. Produces a compact dashboard

## Output

```markdown
# Akasha Status

## Inbox
3 pending: eigenvectors-problem.jpg, bayesian-update.md, ...
(Shows filenames if ≤5; otherwise "N pending")

## Streak
Current streak: 14 days (started 2026-09-14)
Last entry: 2026-09-28
Floors: study ✅ | move ✅ | consume ✅

## Domains
| Domain | Notes |
|--------|-------|
| math | 42 |
| cs | 28 |
| quant | 15 |

## Last Nightly
2026-09-28 23:15 — 3 items processed

## Health
Stale seeds (>30d): 5
Lint status: (not available — run /akasha-lint)
```

## Edge Cases

- **First run (no data):** Shows zeros and "not initialized"
- **No streak file:** Shows "not initialized" for streak section
- **No dailies:** Shows "no daily notes found"
- **Empty Inbox:** "0 pending — all clear"
- **No git history:** Uses `.akasha/hot.md` for last nightly; if missing too, shows "not run yet"

## Data sources

| Section | Source | Fallback |
|---------|--------|----------|
| Inbox | `Inbox/` (excl. `_processed/`) | — |
| Streak | `.akasha/streak.md` | "not initialized" |
| Domains | `Knowledge/_domains.md` | "no domains defined" |
| Last nightly | `git log --oneline --grep=auto-commit` | `.akasha/hot.md` |
| Health | `grep` for `status: seed` with old dates | — |

## Usage

Type `/akasha-status` in any cmdc session within the vault.

## Output

- Read-only — no files written
- Dashboard printed directly to the session
