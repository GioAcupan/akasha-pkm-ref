# Sprint 3 — Track 2: feat/review

**Owner:** accountability-engineer
**Branch:** feat/review
**Depends on:** feat/streak (daily-note flow and streak tracking must exist)

## Scope

Implement the weekly review and goal alignment audit system. This track delivers `akasha-weekly` agent, `akasha-goal-align` agent, `/akasha-review` skill, and `/akasha-goal-check` skill. The five-question review format comes from the PKM accountability cascade. Goal data is placeholder until Sprint 5.

## Deliverables

### 1. `akasha-weekly` agent (`.commandcode/agents/akasha-weekly.md`)
- Reads all `Daily/` files for the current ISO week (Monday-Sunday)
- Reads `.akasha/streak.md` for streak state
- Reads `Templates/weekly.md` for review structure
- Prompts user with 5 fixed questions:
  1. What went well this week?
  2. What didn't go well?
  3. What did I learn?
  4. What am I avoiding?
  5. What's the ONE thing next week?
- Fills `Reviews/YYYY-WXX.md`
- Includes Goal Progress table (placeholder until Sprint 5)
- Includes Start/Stop/Continue section
- Carries over unfinished top-3 items from the week's dailies
- Detects missing daily notes (gaps) and flags them
- Highlights streak breaks
- If review exists for this week, appends rather than overwrites
- Edge cases: no dailies → prompts reflection (no judgment); no streak data → shows "not initialized"

### 2. `/akasha-review` skill (`.commandcode/skills/akasha-review/SKILL.md`)
- Invokes `akasha-weekly` agent
- Presents interactive 5-question flow
- Saves review file
- Reports: week reviewed, file created, any gaps or breaks

### 3. `akasha-goal-align` agent (`.commandcode/agents/akasha-goal-align.md`)
- Reads recent `Daily/*.md` files (last 7-14 days)
- Reads `Reviews/*.md`
- Reads goal cascade: `Goals/4year/vision.md`, `Goals/semester/*.md`, `Goals/monthly/*.md` (placeholders — gracefully handles missing files)
- Produces read-only report: which goals are on track, which are drifting, with specific daily entries as evidence
- Checks goal-to-domain mapping from `Goals/_goal-domain-map.md` if it exists
- No file writes, no side effects
- Edge cases: no recent dailies → insufficient data; no goals defined → "No goals to align against"

### 4. `/akasha-goal-check` skill (`.commandcode/skills/akasha-goal-check/SKILL.md`)
- Invokes `akasha-goal-align` agent
- Presents read-only report
- No writes, no side effects

### 5. Acceptance verification
- `/akasha-review` reads week's dailies + streak → produces five-question review
- Five fixed questions with interactive answers
- `/akasha-goal-check` audits dailies (handles missing goal files gracefully)
- No accusing backlog anywhere (I-2)
- Review file saved as `Reviews/YYYY-WXX.md`

## Files to create/modify

| File | Action |
|------|--------|
| `.commandcode/agents/akasha-weekly.md` | CREATE |
| `.commandcode/agents/akasha-goal-align.md` | CREATE |
| `.commandcode/skills/akasha-review/SKILL.md` | CREATE |
| `.commandcode/skills/akasha-goal-check/SKILL.md` | CREATE |

## Acceptance criteria

1. `/akasha-review` produces weekly review with all 5 questions
2. Review file saved to `Reviews/YYYY-WXX.md` with correct week number
3. Missing daily notes flagged in review output
4. Streak breaks highlighted
5. `/akasha-goal-check` runs read-only audit (handles missing goal files)
6. No accusing backlog in any output (I-2)
7. Goal progress table appears in review (empty placeholder)
