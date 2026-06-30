# Sprint 2 Track 3 — Quick Capture Skill Plan

**Plan:** `docs/superpowers/plans/sprint-2-track-capture.md`  
**Source:** TASK.md (feat/capture)
**Depends on:** Sprint 1 (directory structure + `.commandcode/skills/` exists)

## Task 1: Create /akasha-capture skill file

- [ ] Create `.commandcode/skills/akasha-capture/SKILL.md`
- [ ] Format: standard cmdc skill with description and when-to-use
- [ ] Document input: text content from user
- [ ] Document behavior: creates timestamp-based file in `Inbox/`
- [ ] Document file format: minimal YAML frontmatter (date, status: seed) + body text
- [ ] Document edge cases: empty input, multi-line text, missing Inbox directory, filename collision

## Task 2: Implement capture logic

The skill body must instruct how to:
- [ ] Accept text input from the user
- [ ] Generate timestamp filename: `YYYY-MM-DDTHH-mm-ss.md` (append millisecond suffix if collision)
- [ ] Create file with frontmatter:
  ```markdown
  ---
  date: YYYY-MM-DDTHH:mm:ss
  status: seed
  ---
  <captured text>
  ```
- [ ] Write to `Inbox/<filename>.md`
- [ ] Confirm to user: "Captured to Inbox/<filename>.md"
- [ ] Handle multi-line text: preserve all line breaks, do not reformat
- [ ] Handle empty input: prompt user for content, do not create empty file

## Task 3: Defensive handling

- [ ] If `Inbox/` directory does not exist, create it first
- [ ] If timestamp collision (two captures in same second), append `-2`, `-3`, etc.

## Task 4: Integration note

- [ ] Document that captured files are processed by `akasha-ingest` during next `/akasha-nightly` — no special handling needed
- [ ] This is a standalone skill — it writes a file and exits, no agent delegation needed

## Task 5: Commit

- [ ] Commit to feat/capture with message: "akasha: Sprint 2 Track 3 — /akasha-capture quick capture skill"
