# /akasha-nightly — Run the nightly pipeline

Runs the nightly processing pipeline: inbox ingest → goal adjustment → recap scratch append → streak update → hot cache update.

## Pipeline Steps

1. **Process Inbox** — delegate to `akasha-ingest` for each inbox item (Sprint 2+)
2. **Goal adjustment** — runs `cmd` with `bin/prompts/goal-adjust.md`:
   - Reads weekly deliverables and today's daily
   - Marks done, reschedules slipped, flags 3+ slips
   - Detects staleness, checks Start/Stop/Continue threshold
   - Writes adjustment summary to `.akasha/hot.md`
   - If no active goals: skips silently
3. **Recap scratch append** — runs `cmd` with `bin/prompts/append-recap-scratch.md`:
   - Reads today's daily + streak + weekly deliverables
   - Appends 2-3 lines to `.akasha/recap-weekly-scratch.md`
   - On month-end/semester-end boundaries: also updates monthly/semester scratch files
   - Silent — no user-facing output
4. **Streak Update** — update `.akasha/streak.md` with today's floor status (Sprint 3)
5. **Hot Cache Update** — refresh `.akasha/hot.md` for session continuity (Sprint 2+)

## Usage

Type `/akasha-nightly` in any cmdc session within the vault.

## Output

- Summary of each pipeline step
- Streak status: current count, longest streak
- Errors surfaced with log tails if any step fails

## Current State

Steps 1, 2, and 5 are stubbed — they run only if their prompt files exist. Step 3 (recap scratch append) is wired. Step 4 (streak update) is fully wired.
