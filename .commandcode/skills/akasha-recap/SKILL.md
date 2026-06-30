# /akasha-recap — Period snapshots

Produces factual, backward-looking recaps at three cadences. Hybrid trigger: nightly silently appends raw data to scratch files; user invokes this skill to produce a formatted recap with interactive biggest-win selection.

## Behavior

1. Delegates to the `akasha-recap` agent
2. Takes `level` parameter: `weekly`, `monthly`, or `semester`
3. Agent reads the corresponding scratch file from `.akasha/`
4. Cross-references with `Daily/`, `Goals/`, `Knowledge/_index.md`, `StudyMaterials/active/`, `.akasha/streak.md`, domain `_moc-registry.md` files
5. Proposes 3 biggest-win candidates auto-generated from the period's data
6. User picks one (or writes their own) — agent writes the final recap
7. Saves to `Recaps/<level>/<period>.md`
8. Resets the scratch file to empty for the new period

## Usage

```
/akasha-recap <level>
```

Level: `weekly` | `monthly` | `semester`

## Output

### Weekly recap
```
Recaps/weekly/2026-W40.md
```
Contains: deliverable stats, streak, knowledge growth, inbox processed, material progress, study load (energy distribution), biggest win, upcoming deliverables.

### Monthly recap
```
Recaps/monthly/2026-09.md
```
Contains: weekly aggregates + Must/Should/Nice completion rates, staleness warnings, domain growth trend, semester-progress gauge.

### Semester recap
```
Recaps/semester/2026-fall.md
```
Contains: monthly aggregates + full material coverage, total notes, evergreen count, domain growth summary, goal cascade retrospect, carried-forward items.

## Biggest win flow

1. Agent scans the period's data
2. Proposes 3 candidates derived from: streak milestones, deliverable completions, chapter progress, note creation spikes, floor consistency
3. You pick one or write your own
4. Agent writes the choice into the recap and saves

## Edge Cases

- **No scratch data:** Produces minimal recap from cross-referenced source data alone.
- **Recap already exists:** Warns and offers overwrite/append/skip.
- **No active goals:** Skips goal sections — knowledge-only recap.
- **No materials active:** Skips materials section.
- **No streak data:** Shows "Not initialized" for streak.
- **No dailies:** Shows "No daily data for this period."
- **Mid-week invocation (weekly):** Produces recap for most recently completed week.

## When it runs

- **Manual:** `/akasha-recap weekly|monthly|semester` anytime
- **Weekly hint:** Agent surfaces "Weekly recap ready" on Sunday if no recap exists yet
- **Monthly hint:** Last day of month
- **Semester:** Tied to `/akasha-semester-setup` flow

## Output

- Creates `Recaps/<level>/<period>.md`
- Resets corresponding `.akasha/recap-*-scratch.md`
- Read-only otherwise — no changes to Knowledge/, Goals/, or other vault areas
