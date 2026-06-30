# /akasha-daily — Create today's daily note

Scaffolds today's daily note (`Daily/YYYY-MM-DD.md`) from the template with carry-over from yesterday, cascade context, and streak status. Part of the daily planning ritual.

## Behavior

1. Delegates to the `akasha-daily` agent to scaffold the daily note
2. Agent reads `Daily/` for yesterday's note, `.akasha/streak.md` for streak state, and `.akasha/hot.md` for recent context
3. Agent creates `Daily/<today>.md` with:
   - Empty Top-3 section (you fill in your priorities)
   - Cascade Context (shows "No active goals" until Sprint 5)
   - Suggestions (unfinished items from yesterday, if any)
   - Carry-over section with unfinished items
   - Fried-day fallback reminder
4. Reports: file created, carry-over count, streak status

## Edge Cases

- **Daily already exists:** Agent reports it exists — skill relays "Today's daily already exists at Daily/<date>.md"
- **No yesterday note:** Fresh daily with no carry-over
- **First ever daily:** No streak data, no hot cache — handled gracefully by the agent

## Usage

Type `/akasha-daily` in any cmdc session within the vault.

## Output

- Creates `Daily/<today>.md` if it doesn't exist
- Reports: file path, carry-over count, streak status
