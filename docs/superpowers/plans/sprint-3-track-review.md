# Sprint 3 — Track 2: feat/review — Implementation Plan

**Track:** feat/review
**Sprint:** 3
**Owner:** accountability-engineer
**Branch:** feat/review (worktree: ../akasha-review)
**Depends on:** feat/streak (daily-note flow and streak tracking must exist)

## Plan Architecture

This track has 4 task groups. All are independent of each other but depend on feat/streak being merged to sprint-3 first.

1. [ ] Task 1: Create `akasha-weekly` agent
2. [ ] Task 2: Create `/akasha-review` skill
3. [ ] Task 3: Create `akasha-goal-align` agent
4. [ ] Task 4: Create `/akasha-goal-check` skill

---

## Task 1: Create `akasha-weekly` agent

**File:** `.commandcode/agents/akasha-weekly.md`

### What to implement

A Command Code subagent that runs the weekly review — reads the week's dailies, prompts five fixed questions, and produces `Reviews/YYYY-WXX.md`.

```markdown
---
name: akasha-weekly
description: Run the weekly review — read the week's dailies and streak, prompt five fixed questions, and produce Reviews/YYYY-WXX.md. Interactive 15-min format from the PKM accountability cascade.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
```

### Agent protocol (body)

1. **Determine current ISO week:**
   - Compute today's date
   - Determine ISO week number (W01-W53) and year
   - Compute Monday of this week as week-start

2. **Check for existing review:**
   - If `Reviews/<year>-W<week>.md` exists → append mode. Read the existing file, add a new section.
   - If not → create new review.

3. **Read input data:**
   - Read all `Daily/` files from Monday through today or yesterday (whichever is latest)
   - For each daily, extract: date, energy tag, top-3 items (with completion status)
   - Read `.akasha/streak.md` — extract streak status for each day of the week
   - Read `Templates/weekly.md` — the review structure template

4. **Detect gaps and breaks:**
   - Day gaps: any weekday (Mon-Sun) without a `Daily/<date>.md` file
   - Streak breaks: any day where streak shows "no" for any floor
   - Record both for flagging in the review

5. **Collect unfinished items:**
   - For each daily in the week, extract `- [ ]` items from Top-3 section
   - Compile into a single list for the Carried Over section

6. **Present the 5 questions (interactive):**

Ask the user one at a time and wait for their response:

```
# Weekly Review — W<week> (<date range>)

## Review Questions

1. What went well this week?
[Wait for user input]

2. What didn't go well?
[Wait for user input]

3. What did I learn?
[Wait for user input]

4. What am I avoiding?
[Wait for user input]

5. What's the ONE thing next week?
[Wait for user input]
```

Collect all 5 answers before writing the file.

7. **Assemble the review file:**

```markdown
---
week: <year>-W<week>
created: <today>
status: draft
---

## Review Questions

1. What went well this week?
<user answer>

2. What didn't go well?
<user answer>

3. What did I learn?
<user answer>

4. What am I avoiding?
<user answer>

5. What's the ONE thing next week?
<user answer>

## Goal Progress

No active goals (Sprint 5+)

## Start / Stop / Continue

### Start

### Stop

### Continue

## Week Summary

| Day | Energy | Top-3 Complete | Notes |
|-----|--------|---------------|-------|
| Mon | <energy> | 2/3 | — |
| Tue | <energy> | 3/3 | — |
| ... | ... | ... | ... |

## Carried Over

- [ ] <unfinished item 1>
- [ ] <unfinished item 2>

## Flags

<if gaps found>
- Missing dailies: Mon, Wed (2 days without notes)
</if>

<if streak breaks>
- Streak break: Thu (consume)
</if>

<if no issues>
All good — no missing dailies, no streak breaks this week.
</if>
```

8. **Write the file:** Create or append to `Reviews/<year>-W<week>.md`.

9. **Report:** week reviewed, file created/updated, gap count, break count.

### Edge cases to handle
- **No dailies this week at all:** Prompt user "No daily notes found for this week. Was this intentional?" — no judgment. Write minimal review with just the 5 questions answered.
- **Partial week (today is Wednesday):** Review only Mon-Wed. Note in file: "Mid-week review — partial data."
- **`.akasha/streak.md` has no entries:** Show "Not initialized" in streak section.
- **Review already exists:** Append a new section with today's date as a sub-heading. Let the user know it's an update, not a replacement.
- **ISO week numbering across year boundaries:** Handle W53 edge case (some years have 53 weeks).

---

## Task 2: Create `/akasha-review` skill

**File:** `.commandcode/skills/akasha-review/SKILL.md`

### What to implement

A skill wrapper for the weekly review flow. Invoked as `/akasha-review` in a cmdc session.

```markdown
# /akasha-review — Weekly review (15-min format)

Runs the weekly review by delegating to the `akasha-weekly` agent. The agent reads the week's dailies and streak data, prompts with 5 fixed questions, and produces `Reviews/YYYY-WXX.md`.

## Behavior

1. Delegates to the `akasha-weekly` agent
2. The agent reads `Daily/` for the current ISO week and `.akasha/streak.md`
3. Prompts you with 5 questions interactively (one at a time):
   - What went well this week?
   - What didn't go well?
   - What did I learn?
   - What am I avoiding?
   - What's the ONE thing next week?
4. Saves the review to `Reviews/YYYY-WXX.md`
5. Reports: week number, file path, any gaps or breaks detected

## Edge Cases

- **No dailies this week:** Agent prompts reflection (no judgment) — review still produced
- **Review already exists:** Appends to existing file rather than overwriting
- **Mid-week:** Shows partial data — review covers Mon through today
- **No streak data:** Streak section shows "not initialized" — no error

## Usage

Type `/akasha-review` in any cmdc session within the vault.

## Output

- Creates or updates `Reviews/YYYY-WXX.md`
- Reports: file created/updated, any flagged gaps or breaks
```

---

## Task 3: Create `akasha-goal-align` agent

**File:** `.commandcode/agents/akasha-goal-align.md`

### What to implement

A read-only audit agent. Checks recent dailies against goals, reports drift. Since goals don't exist yet (Sprint 5), this agent must handle missing goal files gracefully.

```markdown
---
name: akasha-goal-align
description: Audit recent dailies against stated goals. Read-only report — no file writes. Checks which goals are on track vs. drifting using specific daily entries as evidence. Handles missing goal files gracefully (Sprint 5+).
tools: read_file, glob, grep, shell_command, think
---
```

### Agent protocol (body)

**Important:** This agent is READ-ONLY. It has no `write_file` or `edit_file` tools. It reads and reports only.

1. **Read recent dailies:**
   - Read `Daily/` files from the last 7-14 days
   - Extract: dates, energy tags, top-3 items, any completed checkboxes
   - Build a summary: `{ date, energy, items_completed, items_total }`

2. **Read recent reviews:**
   - Check `Reviews/` for reviews in this period
   - Extract: any noted patterns, carried-over items, Start/Stop/Continue entries

3. **Read goal cascade (with graceful fallback):**
   - Check if `Goals/4year/vision.md` exists → read if present
   - Check if `Goals/semester/` has any `.md` files → read the most recent if present
   - Check if `Goals/monthly/` has any `.md` files → read the current month if present
   - Check if `Goals/_goal-domain-map.md` exists → read if present
   - If NONE of these exist: report "No goals configured" and stop gracefully

4. **Check goal-to-domain mapping:**
   - If `Goals/_goal-domain-map.md` exists, read the mapping table
   - For academic goals with domain links, count Knowledge notes in linked domains
   - Compare: "you said you'd study X, here's how many notes you have in that domain"

5. **Produce the report:**

```
# Goal Alignment Audit — <date>

## Dailies Summary
| Date | Energy | Completed |
|------|--------|-----------|
| <date> | high | 2/3 |
| ... | ... | ... |

## Goal Status

<if goals exist>

| Goal | Status | Evidence |
|------|--------|----------|
| <goal name> | on track | 4/5 dailies had related work |
| <goal name> | drifting | only 1 daily in 10 days touched this |

## Domain Progress

| Goal | Domain | Notes Count |
|------|--------|-------------|
| Linear Algebra | math | 12 |
| AWS AI | cs | 3 |

</if>

<if no goals exist>
No active goals found. Goals are configured in Sprint 5+. 
Set them up with /akasha-goal-set when available.
</if>

## Flags

- <if drifting goals>: "<goal> hasn't had activity in 10 days. Still relevant?"
- <if no recent dailies>: "Insufficient data — only 2 daily notes in the last week."
- <if all good>: "All goals receiving consistent attention."
```

6. **Display-only:** Output the report to the user. Never write to any file.

### Edge cases
- **No daily notes:** Report "Insufficient data to perform goal alignment audit."
- **Goal files are empty or malformed:** Report "Goal files found but empty or unparseable."
- **Goals/ directory doesn't exist:** Report "No goals configured. Goals are added in Sprint 5+."
- **Goal files mention deliverables/domains but no dailies reference them:** Flag as drifting.

---

## Task 4: Create `/akasha-goal-check` skill

**File:** `.commandcode/skills/akasha-goal-check/SKILL.md`

### What to implement

A skill wrapper for the goal alignment audit. Invoked as `/akasha-goal-check` in a cmdc session.

```markdown
# /akasha-goal-check — Goal alignment audit

Runs a read-only audit of recent dailies against active goals. Delegates to the `akasha-goal-align` agent. Reports which goals are on track vs. drifting with specific daily entries as evidence.

## Behavior

1. Delegates to the `akasha-goal-align` agent
2. Agent reads recent dailies (7-14 days), reviews, and goal cascade
3. Produces a read-only report:
   - Goal status table (on track / drifting) with evidence
   - Domain progress (Knowledge notes per linked domain)
   - Flags: stale goals, insufficient data
4. Report is displayed to you — nothing is written to disk

## Edge Cases

- **No dailies:** Report shows "insufficient data" — no error
- **No goals:** Report shows "No goals configured. Goals are added in Sprint 5+."
- **Missing goal files:** Handled gracefully by the agent

## Usage

Type `/akasha-goal-check` in any cmdc session within the vault.

## Output

- Read-only report displayed in terminal
- No files created or modified
```

---

## Verification Checklist

After implementation, verify:

- [ ] `akasha-weekly` agent exists at `.commandcode/agents/akasha-weekly.md` with valid YAML frontmatter and `tools` list
- [ ] `/akasha-review` skill exists at `.commandcode/skills/akasha-review/SKILL.md`
- [ ] `akasha-goal-align` agent exists at `.commandcode/agents/akasha-goal-align.md` with READ-ONLY tools (no write_file/edit_file)
- [ ] `/akasha-goal-check` skill exists at `.commandcode/skills/akasha-goal-check/SKILL.md`
- [ ] Weekly review agent reads ISO week correctly (Mon-Sun)
- [ ] Five questions prompt interactively in the agent protocol
- [ ] Review file saved as `Reviews/YYYY-WXX.md` with correct week number
- [ ] Missing daily notes are flagged
- [ ] Streak breaks are highlighted
- [ ] Goal progress table appears (with "No active goals" placeholder)
- [ ] Start/Stop/Continue section appears in review
- [ ] Goal-align agent handles missing `Goals/` directory gracefully
- [ ] Goal-align agent is truly read-only (no write_file/edit_file in tools)
- [ ] No accusing backlog language anywhere (I-2)
- [ ] Carried-over items appear in review from week's unfinished top-3 items
- [ ] Existing review append works (doesn't overwrite)

## Files Summary

| File | Action | Task |
|------|--------|------|
| `.commandcode/agents/akasha-weekly.md` | CREATE | 1 |
| `.commandcode/skills/akasha-review/SKILL.md` | CREATE | 2 |
| `.commandcode/agents/akasha-goal-align.md` | CREATE | 3 |
| `.commandcode/skills/akasha-goal-check/SKILL.md` | CREATE | 4 |
