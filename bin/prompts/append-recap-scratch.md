Append today's recap data to the weekly scratch file. Runs silently during the nightly pipeline.

## Process

1. **Read today's daily note** at `Daily/YYYY-MM-DD.md`.

2. **Read streak** from `.akasha/streak.md`. Extract today's entry: study, move, consume status.

3. **Count deliverables done today** from `Goals/weekly/` (current ISO week). Look for items marked `status: done` with today's date in the updated field.

4. **Count notes created today** by checking `Knowledge/_index.md` or scanning Knowledge files with today's `created:` date.

5. **Extract today's energy tag** from the daily note (high/medium/low tag).

6. **Append 2-3 lines to `.akasha/recap-weekly-scratch.md`:**

```
## YYYY-MM-DD
- streak: study=<yes/no>, move=<yes/no>, consume=<yes/no>
- deliverables done: N (list if ≤3, e.g. "Finish Chapter 3, Problem Set 4")
- notes created: N
- inbox processed: N
- energy: <high/medium/low>
```

7. **Period boundary checks:**
   - If today is the LAST DAY of the month: also append to `.akasha/recap-monthly-scratch.md` with a summary of the month's weekly scratch data.
   - If today is the last week of a semester (check `Goals/semester/` for term end dates): append to `.akasha/recap-semester-scratch.md`.

8. No user-facing output needed — this runs silently in the pipeline. Only produce output if there's an error.
