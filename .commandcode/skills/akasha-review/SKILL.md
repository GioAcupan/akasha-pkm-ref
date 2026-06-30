# /akasha-review — Weekly review (15-min format)

Runs the weekly review by delegating to the `akasha-weekly` agent. The agent reads the week's dailies, streak data, and goal progress, prompts with 5 fixed questions plus goal review, and produces `Reviews/YYYY-WXX.md`.

## Behavior

1. Delegates to the `akasha-weekly` agent
2. Agent reads `Daily/` for the current ISO week (Mon-Sun), `.akasha/streak.md`, and the week's goal file
3. Prompts you with 5 questions interactively (one at a time):
   - What went well this week?
   - What didn't go well?
   - What did I learn?
   - What am I avoiding?
   - What's the ONE thing next week?
4. Prompts with goal progress review (new in Sprint 5):
   - Reads the week's goal file (`Goals/weekly/YYYY-WXX.md`)
   - Shows deliverable completion rate: N/M done (X%)
   - Lists any 3+ slipped items flagged for rescheduling
   - Shows Start/Stop/Continue if surfaced during the week
   - Suggests: "Run /akasha-goal-adjust to rebalance" if needed

   Goal progress table format:
   ```markdown
   ## Goal Progress
   | Deliverable | Status | Original Due |
   |-------------|--------|-------------|
   | Finish Chapter 3 | done | 2026-09-28 |
   | Problem Set 4 | rescheduled | 2026-09-29 |
   | Extra readings | slipped (3+) | 2026-09-25 |

   **Completion:** 5/8 (62%)
   **Flagged:** 1 item needs rescheduling
   ```
5. Saves the review to `Reviews/YYYY-WXX.md`
6. Reports: week number, file path, any gaps or breaks detected

## Edge Cases

- **No dailies this week:** Agent prompts reflection (no judgment) — review still produced
- **Review already exists:** Appends to existing file rather than overwriting
- **Mid-week:** Shows partial data — review covers Mon through today
- **No streak data:** Streak section shows "not initialized" — no error
- **No active goals:** Goal progress section shows "No active goals this week"

## Usage

Type `/akasha-review` in any cmdc session within the vault.

## Output

- Creates or updates `Reviews/YYYY-WXX.md`
- Reports: file created/updated, any flagged gaps or breaks
