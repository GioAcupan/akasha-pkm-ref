# /akasha-daily — Create today's daily note

Scaffolds today's daily note (`Daily/YYYY-MM-DD.md`) from the template with carry-over from yesterday, cascade context, and streak status. Part of the daily planning ritual.

## Behavior

1. Delegates to the `akasha-daily` agent to scaffold the daily note
2. Agent reads `Daily/` for yesterday's note, `.akasha/streak.md` for streak state, `.akasha/hot.md` for recent context, and the goal cascade
3. Agent creates `Daily/<today>.md` with:
   - Empty Top-3 section (you fill in your priorities)
   - Cascade Context block — weekly ONE Thing, monthly Must/Should priorities, active study materials
   - Suggestions for today — 1-3 items derived from weekly deliverables (due this week, unfinished yesterday, untouched items). Suggestions are prompts, not assignments — you choose what to adopt.
   - Carry-over section with unfinished items
   - Fried-day fallback reminder
4. Reports: file created, carry-over count, streak status

### Cascade context (new in Sprint 5)

Before scaffolding, the agent reads the goal cascade and surfaces:
- **Cascade context block** — weekly ONE Thing, monthly Must/Should priorities, active study materials
- **Suggestions for today** — 1-3 items derived from weekly deliverables (due this week, unfinished yesterday, untouched items)
- Suggestions are prompts, not assignments — you choose what to adopt
- If no active goals: shows "No active goals — run /akasha-goal-set to create some"

## Edge Cases

- **Daily already exists:** Agent reports it exists — skill relays "Today's daily already exists at Daily/<date>.md"
- **No yesterday note:** Fresh daily with no carry-over
- **First ever daily:** No streak data, no hot cache — handled gracefully by the agent
- **No active goals:** Cascade context shows "No active goals" — daily scaffolds with empty suggestions

## Usage

Type `/akasha-daily` in any cmdc session within the vault.

## Output

- Creates `Daily/<today>.md` if it doesn't exist
- Reports: file path, carry-over count, streak status
