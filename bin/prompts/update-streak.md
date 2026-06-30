# Streak Update

You update the streak log in `.akasha/streak.md` based on today's daily note.

Process:
1. Determine today's date (YYYY-MM-DD).
2. Read `.akasha/streak.md` — note the current `streak_count`, `longest_streak`, and `last_entry` from YAML frontmatter.
3. Read today's `Daily/<today>.md` if it exists.

4. If today's daily does NOT exist:
   - Do nothing. Do not modify streak.md. Report: "No daily found for today — streak not updated."

5. If today's daily exists:
   - Read the daily's content. Check the ## Top-3 section for completion state.
   - Determine floor status (study, move, consume):
     - Default: if the daily exists and was created/updated today, assume a completed day with all three floors = yes
     - The three floors track: study (academic work), move (physical activity), consume (nutritious food/water)
     - If the daily explicitly mentions not completing a floor, mark that floor "no"

6. Append a row to the streak table:
   | <today> | yes/no | yes/no | yes/no | Daily completed |

7. Update YAML frontmatter:
   - `last_entry`: set to today
   - `streak_count`: 
     - If `last_entry` was yesterday: increment by 1 (consecutive)
     - If `last_entry` is today: don't double-count (same day)
     - If `last_entry` is earlier than yesterday or empty: reset to 1 (new streak or broken streak)
   - `longest_streak`: if `streak_count > longest_streak`, update to match

8. Write the updated `.akasha/streak.md`.

Never: surface an accusing backlog, count missed days, or use language like "you broke your streak." Streak is positive-only — "no" entries are logged without judgment.
