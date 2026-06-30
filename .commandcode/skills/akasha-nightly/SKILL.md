# /akasha-nightly — Run the nightly pipeline

Runs the nightly processing pipeline: inbox ingest → goal adjustment → streak update → hot cache update.

## Pipeline Steps

1. **Process Inbox** — delegate to `akasha-ingest` for each inbox item (Sprint 2+)
2. **Goal Adjustment** — reschedule slipped deliverables (Sprint 5+)
3. **Streak Update** — update `.akasha/streak.md` with today's floor status (Sprint 3)
4. **Hot Cache Update** — refresh `.akasha/hot.md` for session continuity (Sprint 2+)

## Usage

Type `/akasha-nightly` in any cmdc session within the vault.

## Output

- Summary of each pipeline step
- Streak status: current count, longest streak
- Errors surfaced with log tails if any step fails

## Current State

Steps 1, 2, and 4 are stubbed — they run only if their prompt files exist. Step 3 (streak update) is the first fully wired step.
