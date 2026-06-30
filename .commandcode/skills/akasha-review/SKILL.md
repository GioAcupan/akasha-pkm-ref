# /akasha-review — Weekly review (15-min format)

Runs the weekly review by delegating to the `akasha-weekly` agent. The agent reads the week's dailies and streak data, prompts with 5 fixed questions, and produces `Reviews/YYYY-WXX.md`.

## Behavior

1. Delegates to the `akasha-weekly` agent
2. Agent reads `Daily/` for the current ISO week (Mon-Sun) and `.akasha/streak.md`
3. Prompts you with 5 questions interactively (one at a time):
   - What went well this week?
   - What didn't go well?
   - What did I learn?
   - What am I avoiding?
   - What's the ONE thing next week?
4. Saves the review to `Reviews/YYYY-WXX.md`
5. Reports: week number, file path, any gaps or breaks detected

## Edge Cases

- **No dailies this week:** Agent prompts reflection (no judgment) — review still produced
- **Review already exists:** Appends to existing file rather than overwriting
- **Mid-week:** Shows partial data — review covers Mon through today
- **No streak data:** Streak section shows "not initialized" — no error

## Usage

Type `/akasha-review` in any cmdc session within the vault.

## Output

- Creates or updates `Reviews/YYYY-WXX.md`
- Reports: file created/updated, any flagged gaps or breaks
