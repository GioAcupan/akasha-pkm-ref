# /akasha-goal-set â€” Create or ingest a goal at any cascade level

Interactive goal creation at any cascade level (4year, semester, monthly, weekly) with two input modes: CLI brainstorming or file ingestion. Delegates to the `akasha-goal-setter` agent.

## Usage

```
/akasha-goal-set <level> [file]
```

### Arguments

| Argument | Required | Values | Description |
|----------|----------|--------|-------------|
| `<level>` | Yes | `4year`, `semester`, `monthly`, `weekly` | The cascade level for the goal |
| `[file]` | No | Path to `.md`, `.txt`, or `.pdf` file | Triggers file ingestion mode instead of CLI brainstorming |

### Level behavior summary

| Level | Creates file at | Confirmation gate | Key questions |
|-------|----------------|-------------------|---------------|
| `4year` | `Goals/4year/vision.md` | Vision summary shown for review before write | 6 life areas: Career, Health, Relationships, Financial, Academic, Soul |
| `semester` | `Goals/semester/<term>-<year>.md` | **Yes â€” must confirm before writing** | Courses, commitments, materials, Top 3 outcomes, deadlines, monthly breakdown |
| `monthly` | `Goals/monthly/<year>-<MM>.md` | Brief "Look good?" prompt | Deadlines, carry-over, Must/Should/Nice structure |
| `weekly` | `Goals/weekly/<year>-W<XX>.md` | Brief confirmation | ONE Thing, daily targets, carried over items, energy check |

## Behavior

### CLI Brainstorming Mode (no file argument)

1. Agent reads cascade context â€” all goals above the target level (e.g., for a monthly goal, it reads the 4-year vision, semester goal, and previous monthly).
2. Agent displays the cascade context so you see what this goal sits on top of.
3. Agent asks level-appropriate questions one at a time:
   - **4year**: Walks through 6 life areas, produces vision summary, derives year-by-year milestones.
   - **semester**: Asks about courses, commitments, materials, top 3 outcomes, deadlines. Produces monthly breakdown proposal. **Stops for confirmation before writing.**
   - **monthly**: Pulls focus from semester breakdown, asks about deadlines and carry-over. Produces Must/Should/Nice proposal.
   - **weekly**: Pulls from monthly Must/Should/Nice, asks about ONE Thing and daily targets. Checks energy level (fried-day handling).
4. After confirmation (where required), agent writes the goal file to the correct `Goals/` subdirectory.
5. Agent updates cascade linkages (e.g., semester goal referenced in 4-year vision milestones).
6. Agent reports: file created, cascade context used, key items, next steps.

### File Ingestion Mode (file argument provided)

1. Agent reads the file:
   - `.md` / `.txt` / `.markdown` â†’ read directly.
   - `.pdf` â†’ extracted via `bin/pdf-extract.sh text`. If the script is still a stub, agent reports "PDF extraction not yet available."
2. Agent parses the content to extract goal structure (level, outcomes, deliverables, deadlines, courses, etc.).
3. Agent displays parsed structure and asks: **"Adopt wholly or adjust?"**
   - **Adopt wholly**: Parsed structure mapped to goal template and written immediately.
   - **Adjust**: Guided conversation â€” for each section, agent asks keep/modify/drop. After all sections reviewed, final structure shown for confirmation before writing.

## Cascade Context

Before creating any goal, the agent reads and displays the cascade context:

```
### Cascade Context
- **4-year vision:** [area summary from vision.md, or "No 4-year vision yet"]
- **This semester:** [active semester goal title + key deliverables, or "No active semester goal"]
- **This month:** [Must/Should/Nice summary, or "No active monthly goal"]
- **This week:** [ONE Thing + deliverables, or "No active weekly goal"]
```

Only lines with data are shown. If nothing exists above the target level, the agent shows: "No cascade context found â€” this goal will be the anchor."

## Confirmation Gates

- **semester**: Agent MUST stop at the proposal and ask "Does this look right? Adjust anything before I write?" before writing. Never auto-creates a semester goal.
- **4year**: Vision summary shown for review before writing the file.
- **monthly**: Brief "Look good?" prompt. No formal gate but user can adjust.
- **weekly**: Brief confirmation. Includes energy check for fried-day handling.

## Edge Cases

### Missing parent goals
Agent warns if a parent goal is missing (e.g., monthly without semester) and suggests creating the parent first. Never blocks creation â€” user can proceed with a standalone goal.

### Existing goal at target path
- **4year/vision.md**: Agent asks "Replace or edit?" and shows existing vision.
- **semester**: Agent treats as unusual ("Are you revising?") and walks through modification.
- **monthly/weekly**: Agent asks "Replace or adjust?" and lets user choose.

### Empty or unparseable file
Agent reports "I couldn't extract a goal structure from this file" and offers to switch to CLI brainstorming mode using the file content as reference.

### Fried-day / low-energy weeks
Agent asks "How's your energy this week?" for weekly goals. If low or fried-day, reduces daily targets to 3-4 days max with a "Reduced-load week" note.

### Cross-semester months
If a month spans two semesters (e.g., August with Summer/Fall), agent asks which semester the monthly goal belongs to.

### ISO week 53
Agent handles years with 53 ISO weeks correctly â€” no hardcoded 52-week assumption.

### PDF extraction stub
If `bin/pdf-extract.sh` returns "PDF extraction not yet implemented â€” Sprint 5", agent reports: "PDF extraction is not yet available. The pdf-extract.sh helper is a stub (Sprint 5). Please convert the PDF to markdown manually and provide the .md file."

## Output

- Creates a goal file in the correct `Goals/<level>/` subdirectory.
- Updates cascade linkages in parent goal files (e.g., semester reference in 4-year milestones).
- Proposes (but does not auto-edit) `_goal-domain-map.md` entries if the goal mentions specific knowledge domains.
- Displays creation report: level, file path, cascade context used, key items count, next-step suggestion.

## Related

- `/akasha-goal-check` â€” Audit recent dailies against active goals (read-only).
- `/akasha-daily` â€” Create today's daily note (cascade context field links to goals in Sprint 5+).
- `/akasha-review` â€” Weekly review (goal progress section).