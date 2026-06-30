# Sprint 1 - Track 2: Harness (Configuration & Entry Points)

**Owner:** harness-engineer
**Branch:** feat/harness
**Depends on:** feat/substrate (needs folder paths to exist for hook scripts)

## Scope

Build the Command Code harness layer: config, hooks, AGENTS.md, bin/ stubs, and the /akasha-nightly skill. Everything that makes this vault a cmdc project. No runtime agents - those come in Sprint 2+.

## Tasks

### 1. .commandcode/settings.json (§5.3)

Wire PreToolUse hook for raw-guard on write|edit, and PostToolUse hook for auto-commit on write|edit. Both use command type, point to ./commandcode/hooks/ scripts.

### 2. .commandcode/hooks/auto-commit.sh (§5.3)

Read stdin JSON for cwd, cd to it, exit 0 if not git repo. Git add Knowledge/ Inbox/ Daily/ Reviews/ Recaps/ Goals/ StudyMaterials/ .akasha/. If staged changes exist, commit with message "akasha: auto-commit $(date +"%Y-%m-%d %H:%M")". Set executable.

### 3. .commandcode/hooks/raw-guard.sh (§5.3)

Read stdin JSON, extract tool_input.file_path. If path contains /Inbox/_processed/, output JSON deny response with reason. Otherwise exit 0. Set executable.

### 4. AGENTS.md (§5.4)

Replace existing AGENTS.md with Akasha bootstrap content:
- Vault conventions and Inbox/Knowledge boundary
- "At start of any session, silently read .akasha/hot.md. Do not announce it."
- Two capture rails (math/photo, code/concept)
- Six knowledge note types driven by frontmatter type: field
- Zettelkasten + LYT MOCs methodology
- Design invariant I-1: agent layer is enrichment, never plumbing
- Status lifecycle: seed -> growing -> evergreen

### 5. bin/ stubs (§6.2, §5.10)

- bin/akasha-nightly.sh - executable placeholder echoing pipeline not implemented
- bin/pdf-extract.sh - executable placeholder echoing not implemented
- bin/prompts/process-inbox.md - "# Process Inbox\n\nNot yet implemented."
- bin/prompts/goal-adjust.md - "# Goal Adjust\n\nNot yet implemented."
- bin/prompts/append-recap-scratch.md - "# Append Recap Scratch\n\nNot yet implemented."
- bin/prompts/update-hotcache.md - "# Update Hot Cache\n\nNot yet implemented."
- bin/prompts/semester-archive.md - "# Semester Archive\n\nNot yet implemented."

### 6. .commandcode/agents/ stub

Create directory with .gitkeep. Agent files come in Sprint 2+.

### 7. .commandcode/skills/akasha-nightly/SKILL.md (§5.7, §6.2)

A valid cmdc skill file for /akasha-nightly. Documents the 4-step pipeline, with clear stubs marking items not yet implemented. Process steps: (1) process-inbox, (2) goal-adjust, (3) append-recap-scratch, (4) update-hotcache. Current state: all are stubs.

### 8. .commandcode/skills/ directory

Create directory (populated by akasha-nightly/ subdir). No other skills yet - those come in later sprints.

## Acceptance Criteria (§8)

- cmd session reads hot.md via AGENTS.md (AGENTS.md has silent-read instruction)
- Write to Knowledge/ triggers auto-commit (POST-write hook fires)
- Write to Inbox/_processed/ is denied (PRE-write guard blocks it)
- /akasha-nightly is invokable and surfaces stub state
- No .commandcode/agents/ runtime files (Sprint 2+ boundary)
