# Sprint 2 Track 3 — Quick Capture Skill

**Owner:** pipeline-engineer
**Branch:** feat/capture
**Depends on:** Sprint 1 (directory structure + skills directory exist)

## Scope

Create the `/akasha-capture` skill — a cmdc-native quick capture rail. Lets you type fleeting thoughts directly from the terminal into the Inbox without opening Obsidian. Complements the photo sync rail (math/photos) and direct Obsidian typing (code/concepts).

## Tasks

### 1. Create `/akasha-capture` skill (§5.7)

Create `.commandcode/skills/akasha-capture/SKILL.md` with:

- Standard cmdc skill format (name, description, when to use)
- **Input:** Text content provided by the user
- **Behavior:** Creates a new file in `Inbox/` with timestamp-based filename: `YYYY-MM-DDTHH-mm-ss.md`
- **File format:** Minimal YAML frontmatter (date, status: seed) + the captured text as body
- **Output:** Confirms the file was created, shows the filename
- **Edge cases:**
  - Empty input → prompts for content
  - Multi-line text → handled gracefully, preserves formatting
  - Inbox doesn't exist → creates it first (defensive)
  - File collision (same timestamp) → append millisecond suffix

### 2. File format

Each captured file should look like:

```markdown
---
date: YYYY-MM-DDTHH:mm:ss
status: seed
---

<captured text content>
```

Minimal frontmatter — just enough for the ingest agent to process it. No title, domain, or tags needed (the ingest agent adds those during processing).

### 3. Multi-line support

Handle multi-line capture gracefully:

- User provides text with line breaks (e.g. pasted code snippet, multi-paragraph thought)
- Preserve the line breaks in the output file
- Do NOT wrap or reformat

### 4. Integration with nightly pipeline

The captured file goes straight to `Inbox/` — no special handling needed. It gets processed by the `akasha-ingest` agent during the next `/akasha-nightly` run, same as any other Inbox item.

## Acceptance Criteria (§8)

- `/akasha-capture "test note"` creates a file in `Inbox/`
- File has timestamp-based filename: `YYYY-MM-DDTHH-mm-ss.md`
- File has valid YAML frontmatter (date, status: seed)
- File body contains the captured text unmodified
- Multi-line text preserved with original formatting and line breaks
- Empty input handled gracefully (prompts for content, doesn't create empty file)
- Captured file is processed on next `/akasha-nightly` run (integration test)
- Skill file is valid cmdc slash command format
