# Sprint 3 — Track 1: feat/streak

**Owner:** accountability-engineer
**Branch:** feat/streak
**Depends on:** none (independent)

## Scope

Implement the daily-note flow and positive streak tracking system. This track delivers the core accountability layer — daily planning with carry-over, a streak log with three floors (study/move/consume), fried-day fallback, and the `/akasha-daily` skill. No goal cascade integration yet (that's Sprint 5) — cascade context shows "No active goals."

## Deliverables

### 1. `/akasha-daily` skill (`.commandcode/skills/akasha-daily/SKILL.md`)
- Reads `Daily/` for yesterday's daily (carry-over unfinished top-3 items)
- Reads `.akasha/hot.md` for recent session context
- Reads `.akasha/streak.md` for current streak state
- Scaffolds today's daily from `Templates/daily.md`
- Populates: Cascade Context (shows "No active goals"), Suggestions (derived from carry-over), Carry-over (unfinished items from yesterday)
- Leaves energy tag and top-3 blank for the user to fill
- Idempotent: if today's daily already exists, reports it rather than overwriting
- Edge cases: no yesterday daily → creates fresh; yesterday had no unfinished items → empty carry-over section

### 2. `akasha-daily` agent (`.commandcode/agents/akasha-daily.md`)
- Subagent definition for daily-note scaffolding
- Name: `akasha-daily`
- Description: prompt for when to delegate
- Tools: read_file, write_file, edit_file, glob, grep, shell_command, think

### 3. Streak logging — update `streak.md`
- `.akasha/streak.md` already exists as a stub with YAML frontmatter and empty table
- Implement streak update as part of `/akasha-nightly` or as separate prompt
- On daily completion: append a row to streak table
- Update frontmatter: `streak_count`, `longest_streak`, `last_entry`
- Three floors: study, move, consume
- Streak is positive-only — "no" entries reset count to 0 but logged without judgment
- No accusing backlog ever surfaced

### 4. Fried-day fallback
- Template already includes: "If fried-day: pick ONE surface-level task from Top-3 and rest."
- Ensure `/akasha-daily` doesn't override or remove this
- No additional implementation needed

### 5. `/akasha-nightly` integration
- Update `bin/akasha-nightly.sh` or skill to include streak-update step
- Or implement streak update as callable prompt in `bin/prompts/`

### 6. Acceptance verification
- `/akasha-daily` creates today's daily with carry-over from yesterday
- Streak table gets new rows when daily completed
- `streak_count` increments correctly and resets on missed day
- No accusing backlog anywhere (I-2)
- Fried-day fallback text preserved

## Files to create/modify

| File | Action |
|------|--------|
| `.commandcode/skills/akasha-daily/SKILL.md` | CREATE |
| `.commandcode/agents/akasha-daily.md` | CREATE |
| `.akasha/streak.md` | MODIFY (add update mechanism) |
| `bin/prompts/update-streak.md` | CREATE |
| `bin/akasha-nightly.sh` | MODIFY (add streak step) |

## Acceptance criteria

1. `/akasha-daily` scaffolds today's daily note with correct carry-over
2. Idempotent — running twice doesn't create duplicates
3. No accusing backlog in any output (I-2)
4. Streak table populated after daily completion
5. `streak_count` correct for consecutive all-floors days
6. Fried-day fallback text appears in generated dailies
