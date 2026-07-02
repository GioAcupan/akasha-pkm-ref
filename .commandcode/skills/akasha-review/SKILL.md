# Akasha Review — Smart Router

Routes the user to the right review experience based on the current date and time. Single entry point — remembers no command names needed.

## When to use

User types `/akasha-review`. Determine current day, time, and vault state to dispatch.

## Routing logic

1. **Get current date and time** — Read `date` command output.
2. **Detect end of month** — If current date is within 3 days of month end, route to monthly recap.
3. **Detect weekend** — If Friday (after 18:00), Saturday, or Sunday, route to weekly review.
4. **Detect time of day** — Before 12:00 is morning scaffold, after 18:00 is evening reflection.
5. **Check existing state** — If dispatch target has already been run today/this week, ask before re-running.

| Condition | Route | Target |
|-----------|-------|--------|
| Last 3 days of month (any time) | Monthly recap | `akasha-recap monthly` |
| Fri 18:00+ / Sat / Sun | Weekly review | `akasha-weekly` |
| Before 12:00 (weekday) | Morning scaffold | `akasha-daily` |
| After 18:00 (weekday) | Evening reflection | `akasha-daily` (reflection pass) |
| 12:00–18:00 (weekday) | Suggest: "Midday check. Run `/akasha-daily` for updates or wait for evening reflection?" | Informational |

## Edge cases

- **Month-end + weekend overlap**: Monthly recap takes priority. Weekly can be postponed.
- **No daily note yet**: Morning route creates one. Evening route prompts: "No daily note for today. Run morning scaffold first?"
- **Already reviewed this week**: Check if `Reviews/YYYY-WXX.md` exists for current week. If yes, ask.
- **Already recapped this month**: Check if `Recaps/monthly/YYYY-MM.md` exists. If yes, ask.
- **First-time user**: If no daily/weekly/recap files exist, default to morning daily scaffold with setup guidance.

## Output

Brief confirmation of what was dispatched. Example:

```
→ Friday evening — routing to weekly review.
Running /akasha-weekly...
```
