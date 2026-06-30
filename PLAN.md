# Sprint 1 - Track 2: Harness Implementation Plan

**Plan:** `docs/superpowers/plans/sprint-1-track-harness.md`
**Source:** TASK.md (feat/harness)
**Depends on:** feat/substrate (paths must exist)

## Task 1: Create .commandcode/ configuration

- [ ] Create `.commandcode/` directory
- [ ] Create `.commandcode/settings.json` with PreToolUse hook (raw-guard) and PostToolUse hook (auto-commit)

## Task 2: Create hook scripts

- [ ] Create `.commandcode/hooks/` directory
- [ ] Create `.commandcode/hooks/auto-commit.sh` — reads stdin JSON for cwd, git add targeted dirs, commit if changes
- [ ] Create `.commandcode/hooks/raw-guard.sh` — reads stdin JSON, blocks writes to Inbox/_processed/ with deny response
- [ ] Make both scripts executable (`chmod +x`)

## Task 3: Replace AGENTS.md

- [ ] Read existing `AGENTS.md`
- [ ] Write new AGENTS.md with Akasha bootstrap content:
  - Vault conventions + Inbox/Knowledge boundary
  - Silent hot.md read instruction
  - Two capture rails
  - Six note types driven by frontmatter
  - Zettelkasten + LYT MOCs methodology
  - Design invariant I-1
  - Status lifecycle (seed → growing → evergreen)
  - Template references

## Task 4: Create bin/ stubs

- [ ] Create `bin/` directory
- [ ] Create `bin/akasha-nightly.sh` — executable, echo stub message
- [ ] Create `bin/pdf-extract.sh` — executable, echo stub message
- [ ] Create `bin/prompts/` directory
- [ ] Create `bin/prompts/process-inbox.md` — "# Process Inbox\n\nNot yet implemented."
- [ ] Create `bin/prompts/goal-adjust.md` — "# Goal Adjust\n\nNot yet implemented."
- [ ] Create `bin/prompts/append-recap-scratch.md` — "# Append Recap Scratch\n\nNot yet implemented."
- [ ] Create `bin/prompts/update-hotcache.md` — "# Update Hot Cache\n\nNot yet implemented."
- [ ] Create `bin/prompts/semester-archive.md` — "# Semester Archive\n\nNot yet implemented."

## Task 5: Create skills directory and akasha-nightly skill

- [ ] Create `.commandcode/skills/` directory
- [ ] Create `.commandcode/skills/akasha-nightly/` directory
- [ ] Create `.commandcode/skills/akasha-nightly/SKILL.md` — valid cmdc skill file documenting the 4-step pipeline with all steps marked as stubs

## Task 6: Create agents stub

- [ ] Create `.commandcode/agents/` directory with `.gitkeep`

## Task 7: Verification

- [ ] Verify settings.json is valid JSON
- [ ] Verify auto-commit.sh and raw-guard.sh are executable
- [ ] Verify AGENTS.md contains hot.md silent-read instruction
- [ ] Verify bin/ scripts are executable and return 0
- [ ] Verify /akasha-nightly skill file is valid markdown with correct skill metadata
- [ ] Verify no .commandcode/agents/ runtime agents exist (only .gitkeep)
