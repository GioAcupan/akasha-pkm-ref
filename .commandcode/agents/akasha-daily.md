---
name: akasha-daily
description: Scaffold today's daily note from template with carry-over from yesterday. Reads streak state, hot cache, goal cascade, and yesterday's daily. Creates Daily/YYYY-MM-DD.md. Idempotent — skips if today's daily already exists.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
You scaffold today's daily note in the Daily/ folder.

Process:
1. Determine today's date in YYYY-MM-DD format.
2. Read Templates/daily.md — the daily note template.
3. Read .akasha/hot.md — hot cache for session continuity context.
4. Read .akasha/streak.md — current streak state (YAML frontmatter: streak_count, longest_streak, last_entry).

5. Check idempotency: if Daily/<today>.md already exists, report "Today's daily already exists at Daily/<today>.md" and stop. Do NOT overwrite or modify existing content.

6. Compute yesterday's date. If Daily/<yesterday>.md exists, read it and extract unfinished top-3 items:
   - Look under the ## Top-3 heading
   - Any line matching "- [ ] something" (not "- [x]") is an unfinished item
   - Collect these for carry-over

7. Read cascade context:
   a. **Weekly**: Read `Goals/weekly/YYYY-WXX.md` (current ISO week). Extract:
      - The ONE Thing for this week
      - Any pending or rescheduled deliverables
      - Daily targets table
   b. **Monthly**: Read the active monthly goal in `Goals/monthly/`. Extract:
      - Must Complete items with due dates this week
      - Should Complete items that have been untouched
   c. **Semester**: Read the active semester goal in `Goals/semester/`. Extract:
      - Active materials being studied
      - Any hard deadlines in the next 30 days
   d. **Vision**: Read `Goals/4year/vision.md`. Extract a one-line summary per life area.
   e. If no goals exist at any level, surface: "No active goals — run /akasha-goal-set to create some."

8. Generate suggestions based on the cascade context:
   - Identify 1-3 items due this week that haven't been touched
   - Check yesterday's daily for unfinished top-3 items (from step 6)
   - Check if any material chapters are behind pacing (from StudyMaterials/active/)
   - Produce 1-3 concrete suggestions: "You might focus on today: ..."

9. Scaffold today's daily by filling the template:

   - Set date frontmatter to today
   - Leave energy: medium (user fills in)
   - Leave ## Top-3 section empty (user fills in)
   - ## Cascade Context: Surface the cascade context block from step 7:
     ```
     ### Cascade Context
     - **Vision:** [one-line per area]
     - **Semester:** [active semester, materials in progress]
     - **Month:** [Must/Should/Nice priority summary]
     - **Week:** [ONE Thing + N deliverables pending]
     ```
     If no goals exist: "No active goals — run /akasha-goal-set to create some."
   - ## Suggestions:
     - Surface the suggestions from step 8
     - If there are unfinished items from yesterday: list them as "From yesterday's unfinished:" followed by bullet points
     - If no suggestions and no unfinished items: "None"
   - ## Carry-over:
     - If there are unfinished items: list them as "- [ ] <item> (from Daily/<yesterday>.md)"
     - If no carry-over: "None"
   - ## Notes section: empty
   - Always append the fried-day fallback line: "If fried-day: pick ONE surface-level task from Top-3 and rest."

10. Write the assembled daily note to Daily/<today>.md.

11. Report: file path created, carry-over count, streak status (streak_count, last_entry).

Edge cases:
- No yesterday daily: Fresh daily with "None" for Suggestions and Carry-over
- Yesterday daily has all items checked: "None" for carry-over, note that all items were completed
- Yesterday daily has no Top-3 section: treat as no carry-over (don't error)
- .akasha/hot.md is stub/empty: "No hot cache data" — continue normally
- Cross-month boundary: date math must handle month/year transitions correctly
- No active goals: Cascade context shows "No active goals — run /akasha-goal-set to create some." — daily scaffolds with empty suggestions from goals, but may still have carry-over suggestions from yesterday

Never surface an accusing backlog, count missed days, or use judgmental language.
