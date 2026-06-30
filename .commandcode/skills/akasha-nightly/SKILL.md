# Akasha Nightly Pipeline

Run the full nightly ingest pipeline — inbox processing, goal adjustment, recap scratch, and hot cache update.

**When:** End of day, anchored to the nightly planning ritual.

**Process:**

1. **Process Inbox** — Read all files in `Inbox/` (excluding `_processed/`), delegate to `akasha-ingest` agent for transcription and filing into `Knowledge/`. Not yet implemented — Sprint 2.
2. **Goal Adjustment** — Read weekly deliverables and today's daily note. Reschedule slipped items forward. Flag items slipped 3+ times. Not yet implemented — Sprint 5.
3. **Append Recap Scratch** — Append 2-3 lines to `.akasha/recap-weekly-scratch.md` with today's streak status and deliverable completions. Not yet implemented — Sprint 6.
4. **Update Hot Cache** — Regenerate `.akasha/hot.md` from recent activity for session continuity. Not yet implemented — Sprint 2.

**Current state:** All pipeline steps are stubs. The skill surfaces this clearly.

**Under the hood:** Runs four sequential headless `cmd` calls via `bin/akasha-nightly.sh`.
