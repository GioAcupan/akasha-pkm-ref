# /akasha-goal-adjust — Deliverable rescheduling + pattern surfacing

Runs the `akasha-goal-tracker` agent to reschedule slipped deliverables, detect staleness, and surface patterns. Runs automatically after `/akasha-nightly` and on-demand when you want to rebalance.

## Behavior

1. Delegates to the `akasha-goal-tracker` agent
2. Agent reads weekly goals + today's daily note
3. For each deliverable: completes or reschedules
4. Flags items slipped 3+ times for manual review
5. Checks 14-day staleness across all active goals
6. Surfaces Start/Stop/Continue if >50% of weekly deliverables slipped
7. Reports Knowledge domain note counts for academic goals
8. Writes adjustment summary to `.akasha/hot.md`

## Usage

```
/akasha-goal-adjust
```

No arguments — uses today's date and current week.

## Output

```
## Goal Adjustment Summary

**Week:** 2026-W40 (progress: 60%)
**Rescheduled:** 2 deliverables pushed to tomorrow
**Done:** 3 completed today
**Flagged:** 1 item slipped 3+ times — needs manual review
**Stale:** 0 goals without updates in 14+ days
**Domain check:** math: 42 notes, cs: 28 notes, quant: 15 notes
**Start/Stop/Continue:** not triggered (40% slipped)
```

## Edge Cases

- **No weekly goal:** "No weekly goal found. Run /akasha-goal-set weekly first."
- **No daily note today:** "No daily note for today. Create one with /akasha-daily first."
- **All deliverables done:** "All clear — everything on track this week."
- **No active goals:** "No active goals defined. Run /akasha-goal-set to create some."
- **>50% slipped:** Start/Stop/Continue section appears with specific suggestions.

## When it runs

- **Automatically:** After ingest, during `/akasha-nightly` (step 2 of the pipeline)
- **On-demand:** Type `/akasha-goal-adjust` anytime you want to check progress or rebalance

## Output

- Updates `Goals/weekly/YYYY-WXX.md` deliverable statuses
- Writes adjustment summary to `.akasha/hot.md`
- Prints report to session
