# /akasha-goal-check — Goal alignment audit

Runs a read-only audit of recent dailies against active goals. Delegates to the `akasha-goal-align` agent. Reports which goals are on track vs. drifting with specific daily entries as evidence.

## Behavior

1. Delegates to the `akasha-goal-align` agent
2. Agent reads recent dailies (last 7-14 days), reviews, and the goal cascade
3. Produces a read-only report:
   - Dailies summary table (date, energy, completion)
   - Goal status table (on track / drifting) with evidence
   - Domain progress (Knowledge notes per linked domain, if mapping exists)
   - Flags for stale goals or insufficient data
4. Report is displayed — nothing is written to disk

## Edge Cases

- **No dailies:** Report shows "insufficient data" — no error
- **No goals:** Report shows "No goals configured. Goals are added in Sprint 5+."
- **Missing goal files:** Handled gracefully by the agent — reports what's found
- **Empty goal files:** Reports "Goal files found but contain no deliverables to track."

## Usage

Type `/akasha-goal-check` in any cmdc session within the vault.

## Output

- Read-only report displayed in terminal
- No files created or modified
