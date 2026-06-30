Run goal adjustment for the nightly pipeline.

## Process

1. **Find the current week's goal.** Read the file in `Goals/weekly/` matching the current ISO week (YYYY-WXX format). If none found, skip — no goals to adjust.

2. **Read today's daily note.** Read `Daily/YYYY-MM-DD.md` (today's date).

3. **For each deliverable in the weekly goal:**
   - Check if the deliverable was completed today (look for checkboxes marked `[x]` matching the deliverable description, or explicit completion notes).
   - Done → mark `status: done`.
   - Missed (first or second time) → reschedule to tomorrow (today + 1), mark `status: rescheduled`, keep original due in HTML comment: `<!-- original due: YYYY-MM-DD -->`.
   - Missed 3+ times → do NOT reschedule. Mark `status: slipped`, add comment `⚠️⚠️⚠️ slipped 3+ times — needs rescheduling`.

4. **Update progress.** In the weekly goal frontmatter, set `progress:` to `done_count / total_count * 100`.

5. **Check staleness.** Read all goal files across all levels. Any goal with `status: active` and `updated` date 14+ days ago → flag it.

6. **Check Start/Stop/Continue threshold.** If >50% of this week's deliverables are `slipped` or `rescheduled`, surface start/stop/continue suggestions.

7. **Write to hot cache.** Append to `.akasha/hot.md`:
   ```
   ### Goal Adjustment — YYYY-MM-DD
   - Week: YYYY-WXX (progress: X%)
   - Done: N
   - Rescheduled: N
   - Flagged (3+ slips): N
   - Stale: N
   - Start/Stop/Continue: yes/no
   ```

8. **Report.** Brief summary of what was adjusted. No verbose output — this runs in the nightly pipeline.
