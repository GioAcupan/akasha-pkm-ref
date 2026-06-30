# Sprint 3 — Track 1: feat/streak — Implementation Plan

**Track:** feat/streak
**Sprint:** 3
**Owner:** accountability-engineer
**Branch:** feat/streak (worktree: ../akasha-streak)
**Depends on:** none (independent)

## Plan Architecture

This track has 5 task groups, ordered by dependency:

1. [ ] Task 1: Create `akasha-daily` agent definition
2. [ ] Task 2: Create `/akasha-daily` skill
3. [ ] Task 3: Create streak update prompt (`bin/prompts/update-streak.md`)
4. [ ] Task 4: Implement streak logging logic (update `.akasha/streak.md`)
5. [ ] Task 5: Wire streak into `/akasha-nightly`

---

## Task 1: Create `akasha-daily` agent

**File:** `.commandcode/agents/akasha-daily.md`

### What to implement

Create a Command Code subagent definition using the same YAML frontmatter + body format as the existing `akasha-ingest.md` agent.

```markdown
---
name: akasha-daily
description: Scaffold today's daily note from template with carry-over from yesterday. Reads streak state, hot cache, and yesterday's daily. Creates Daily/YYYY-MM-DD.md. Idempotent — skips if today's daily already exists.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
```

### Agent protocol (body)

1. **Read context files:**
   - Read `Templates/daily.md` — the scaffolding template
   - Read `.akasha/hot.md` — hot cache for session continuity
   - Read `.akasha/streak.md` — current streak state (frontmatter: `streak_count`, `longest_streak`, `last_entry`)

2. **Determine today's date:** Use `date` command or shell to get `YYYY-MM-DD`.

3. **Check idempotency:** If `Daily/<today>.md` already exists, report "Today's daily already exists at Daily/<today>.md" and stop. Do NOT overwrite.

4. **Find yesterday's daily:**
   - Compute yesterday's date (cross-month safe — use shell `date` math)
   - If `Daily/<yesterday>.md` exists, read it
   - Extract unfinished top-3 items: look under `## Top-3` heading — any line that is `- [ ] something` (not `- [x]`)

5. **Parse streak state:**
   - Extract `streak_count` and `last_entry` from `streak.md` YAML frontmatter
   - If `last_entry` is today → streak already logged
   - If `last_entry` is yesterday → streak active
   - If no entries yet → "No streak data yet"

6. **Scaffold the daily note:**

Read the template from `Templates/daily.md` and produce today's daily with these sections filled:

```markdown
---
date: <today>
energy: medium
---

## Top-3



## Cascade Context

No active goals

## Suggestions

None
```

If there were unfinished items from yesterday, append them under Suggestions:
```markdown
## Suggestions

From yesterday's unfinished:
- [ ] <carried-over item 1>
- [ ] <carried-over item 2>
```

If there were unfinished items, also add:
```markdown
## Carry-over

- [ ] <item 1> (from Daily/<yesterday>.md)
- [ ] <item 2> (from Daily/<yesterday>.md)
```

If no carry-over items:
```markdown
## Carry-over

None
```

Always append:
```markdown
## Notes



If fried-day: pick ONE surface-level task from Top-3 and rest.
```

7. **Write the file:** Create `Daily/<today>.md` with the assembled content.

8. **Report:** "Daily/<today>.md created" with carry-over count, streak status, and any notes.

### Edge cases to handle
- **No yesterday daily:** Suggestions and Carry-over show "None" — create fresh daily
- **Yesterday daily has all items checked:** "All top-3 items from yesterday were completed" — empty carry-over
- **Yesterday daily has no Top-3 section:** treat as no carry-over, don't error
- **`.akasha/hot.md` is empty/just a stub line:** handle gracefully, report "No hot cache data"
- **Cross-month boundary:** shell date math handles this (`date -d "yesterday"` or equivalent)

---

## Task 2: Create `/akasha-daily` skill

**File:** `.commandcode/skills/akasha-daily/SKILL.md`

### What to implement

A skill wrapper that delegates to the `akasha-daily` agent. Skills are invoked as slash commands in cmdc sessions.

```markdown
# /akasha-daily — Create today's daily note

Scaffolds today's daily note (`Daily/YYYY-MM-DD.md`) from the template with carry-over from yesterday, cascade context, and streak status.

## Behavior

1. Delegate to the `akasha-daily` agent to scaffold the daily note
2. Report the result: file created, carry-over items, streak status
3. Display the daily note's key sections (date, top-3 area, cascade context)

## Edge Cases

- **Daily already exists:** Agent reports it exists — skill relays the message
- **No yesterday note:** Fresh daily with no carry-over
- **First ever daily:** No streak data, no hot cache — handled gracefully by the agent

## Usage

Type `/akasha-daily` in any cmdc session within the vault.

## Output

- Creates `Daily/<today>.md` if it doesn't exist
- Reports: file path, carry-over count, streak status
```

---

## Task 3: Create streak update prompt

**File:** `bin/prompts/update-streak.md`

### What to implement

A headless prompt that reads today's daily and streak file, then updates the streak log. This is called by the nightly pipeline.

```markdown
# Streak Update

You update the streak log in `.akasha/streak.md` based on today's daily note.

Process:
1. Determine today's date (YYYY-MM-DD).
2. Read `.akasha/streak.md` — note the current `streak_count`, `longest_streak`, and `last_entry` from YAML frontmatter.
3. Read today's `Daily/YYYY-MM-DD.md` if it exists.

4. If today's daily does NOT exist:
   - Do nothing. Do not modify streak.md. "No daily found for today."

5. If today's daily exists:
   - Check the `## Top-3` section for completion indicators.
   - For the three floors (study, move, consume), check if the daily note mentions them.
   - Default: if the daily was created today, assume all three floors = yes (the user filled it in).
   - If the daily has explicit floor markers, use those.

6. Append a row to the streak table:
   ```
   | <today> | yes | yes | yes | Daily completed |
   ```
   If any floor is "no", use "no" for that column.

7. Update YAML frontmatter:
   - `last_entry`: set to today
   - If today is consecutive (yesterday's daily also exists): increment `streak_count`
   - If today breaks the streak (yesterday's daily missing): set `streak_count` to 1
   - If `streak_count > longest_streak`: update `longest_streak` to match

8. Write the updated `.akasha/streak.md`.

Never: surface an accusing backlog, count missed days, or use language like "you broke your streak."
```

---

## Task 4: Implement streak logging logic

**File to modify:** `.akasha/streak.md`

### Current state

```markdown
---
streak_count: 0
longest_streak: 0
last_entry: ""
---

# Streak Log

| Date | Study | Move | Consume | Notes |
|------|-------|------|---------|-------|
```

### Changes needed

The streak file format is correct. No structural changes to the file itself — the update mechanism lives in the prompt (`bin/prompts/update-streak.md` from Task 3) and the nightly pipeline (Task 5). 

**What this task actually does:**

1. Verify the current `streak.md` format matches the expected schema:
   - YAML frontmatter has `streak_count`, `longest_streak`, `last_entry`
   - Table has columns: `Date`, `Study`, `Move`, `Consume`, `Notes`

2. Add a brief header comment explaining the streak format for human readers:
   ```markdown
   <!--
     Positive-only streak tracker. Three floors: Study, Move, Consume.
     "yes" = done, "no" = missed (no judgment).
     streak_count = consecutive days with all three floors = yes.
     longest_streak = all-time best consecutive run.
     NEVER surface an accusing backlog.
   -->
   ```

3. Ensure the file is valid YAML (no issues with the existing format).

---

## Task 5: Wire streak into `/akasha-nightly`

**File to modify:** `bin/akasha-nightly.sh`
**File to modify:** `.commandcode/skills/akasha-nightly/SKILL.md`

### Current state of nightly script

```bash
#!/usr/bin/env bash
echo "Nightly pipeline not yet implemented — Sprint 2+"
```

### What to implement

Update the script to run the streak update as a step. The full nightly pipeline from the TID is:

1. Process inbox (`bin/prompts/process-inbox.md`)
2. Goal adjust (`bin/prompts/goal-adjust.md`)
3. Streak update (`bin/prompts/update-streak.md`) — NEW
4. Update hot cache (`bin/prompts/update-hotcache.md`)

**For Sprint 3, only step 3 (streak) is being implemented.** Steps 1, 2, and 4 are from other sprints:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Akasha nightly pipeline
# Steps 1-2: Sprint 2 (inbox) and Sprint 5 (goals) — not yet implemented
# Step 3: Sprint 3 — streak update

VAULT_PATH="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Akasha Nightly Pipeline ==="
echo ""

# Step 3: Streak update
echo "[3/4] Updating streak..."
cmd -p "$(cat "$VAULT_PATH/bin/prompts/update-streak.md")" \
    --yolo --skip-onboarding --max-turns 8 2>&1 | tail -1
echo ""

# Step 4: Hot cache update (Sprint 2+)
echo "[4/4] Updating hot cache..."
# cmd -p "$(cat "$VAULT_PATH/bin/prompts/update-hotcache.md")" \
#     --yolo --skip-onboarding --max-turns 8 2>&1 | tail -1
# echo ""

echo "=== Nightly complete ==="
```

Also update the skill file at `.commandcode/skills/akasha-nightly/SKILL.md` to reflect the new streak step in its documentation:

```markdown
# /akasha-nightly — Run the nightly pipeline

Runs the nightly processing pipeline: inbox ingest → goal adjustment → streak update → hot cache update.

## Pipeline Steps

1. **Process Inbox** — delegate to `akasha-ingest` for each inbox item (Sprint 2+)
2. **Goal Adjustment** — reschedule slipped deliverables (Sprint 5+)
3. **Streak Update** — update `.akasha/streak.md` with today's floor status (Sprint 3)
4. **Hot Cache Update** — refresh `.akasha/hot.md` for session continuity (Sprint 2+)

## Usage

Type `/akasha-nightly` in any cmdc session within the vault.

## Output

- Summary of each pipeline step
- Streak status: current count, longest streak
- Errors surfaced with log tails if any step fails
```

**Important:** Step 3 (streak) is the only step actually wired in this sprint. Steps 1-2 and 4 remain commented out or stubbed — they'll be wired in their respective sprints.

---

## Verification Checklist

After implementation, verify:

- [ ] `/akasha-daily` creates `Daily/<today>.md` with correct template structure
- [ ] `/akasha-daily` carries over unfinished top-3 items from yesterday
- [ ] `/akasha-daily` shows "No active goals" under Cascade Context
- [ ] `/akasha-daily` is idempotent — running twice doesn't create duplicates
- [ ] `akasha-daily` agent file exists at `.commandcode/agents/akasha-daily.md` with valid YAML frontmatter
- [ ] `/akasha-daily` skill file exists at `.commandcode/skills/akasha-daily/SKILL.md`
- [ ] `bin/prompts/update-streak.md` exists with streak update protocol
- [ ] Streak table accepts new rows with correct columns
- [ ] `streak_count` increments correctly for consecutive days
- [ ] `streak_count` resets to 1 when a day is missed
- [ ] `longest_streak` tracks all-time best
- [ ] No accusing backlog language anywhere in agent output or skill docs
- [ ] Fried-day fallback text appears in every generated daily
- [ ] `bin/akasha-nightly.sh` runs streak update step
- [ ] Nightly skill doc references streak step

## Files Summary

| File | Action | Task |
|------|--------|------|
| `.commandcode/agents/akasha-daily.md` | CREATE | 1 |
| `.commandcode/skills/akasha-daily/SKILL.md` | CREATE | 2 |
| `bin/prompts/update-streak.md` | CREATE | 3 |
| `.akasha/streak.md` | MODIFY (add header comment) | 4 |
| `bin/akasha-nightly.sh` | MODIFY | 5 |
| `.commandcode/skills/akasha-nightly/SKILL.md` | MODIFY | 5 |
