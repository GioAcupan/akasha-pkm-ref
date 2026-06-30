# Akasha — User Guide

> A personal knowledge management system that builds a compounding knowledge base from your notes, study materials, and daily work — driven by a simple morning/evening rhythm. Powered by Command Code (`cmdc`) and Obsidian.

---

## 1. Getting Started

### Prerequisites

- An Obsidian vault (this folder is your vault root).
- Command Code installed (`cmdc` CLI, $1/mo plan).

### What You See on First Run

Akasha starts with three empty knowledge domains — `math`, `cs`, and `quant` — waiting for your first capture. The vault is scaffolded but empty: no notes, no MOCs, no streak yet. This is intentional. The system fills in as you use it.

### If You Already Have an Obsidian Vault

Run `/akasha-adopt` to migrate your existing notes, tags, and index files into the Akasha structure. This is a one-time, non-destructive migration — your original notes are preserved as-is, and every step is a separate git commit so you can roll back anything.

### Vault Layout at a Glance

| Directory | What Lives Here |
|-----------|----------------|
| `Inbox/` | Your capture drop zone — fleeting thoughts, math photos, rough drafts. Processed nightly. |
| `Knowledge/` | Processed, atomic, linked notes organized by domain (`math/`, `cs/`, `quant/`). Agent-owned. |
| `Daily/` | Daily planning notes — top-3, energy tag, cascade context. |
| `Goals/` | Goal cascade: 4-year vision → semester → monthly → weekly. |
| `Reviews/` | Weekly review notes (Sunday ritual). |
| `Recaps/` | Period snapshots: weekly, monthly, semester. |
| `StudyMaterials/` | Course PDFs, extracted TOCs, chapter pacing. |
| `.akasha/` | System state — streak, hot cache, recap scratch files. You rarely touch these. |

---

## 2. Core Concepts

### Inbox vs. Knowledge

**Inbox** is human-owned — you capture here with zero friction. The nightly agent reads your captures, creates atomic Knowledge notes from them, and moves the originals to `Inbox/_processed/` (immutable archive). You never need to manually file anything.

**Knowledge** is agent-owned — linked, atomic notes organized by domain. This is your compounding knowledge base. The more you capture, the richer it gets.

### Note Types

Every note has a `type` in its frontmatter. Pick the right one when creating a note manually:

| Type | Purpose |
|------|---------|
| `concept` | An atomic idea or principle (e.g., "Backpropagation", "Eigenvalues") |
| `math` | LaTeX-heavy, transcribed from a photo of handwritten math |
| `source` | Summary of a reference — book, paper, article |
| `entity` | A person, tool, or named thing (e.g., "Strang", "PyTorch") |
| `question` | An open question or inquiry you want to answer later |
| `moc` | Map of Content — a curated hub note linking to related atomic notes |

### Note Lifecycle

```
seed → growing → evergreen
```

All new notes start as `seed`. As you refine them — add connections, flesh out sections, verify claims — promote them to `growing` and eventually `evergreen`. The lint agent flags `seed` notes older than 30 days as a gentle reminder.

### Maps of Content (MOCs)

A MOC is a hand-curated hub note that organizes atomic notes by topic. Think of it as a custom table of contents you build as a cluster of related notes grows.

MOCs form a hierarchy within each domain:

| Level | Role |
|-------|------|
| `domain` | Root MOC for the domain (e.g., "Linear Algebra MOC") |
| `topic` | Major topic (e.g., "Vector Spaces MOC") |
| `subtopic` | Any depth below topic (e.g., "Eigenvalues MOC") — recursive |

**Important:** The MOC tree is a navigational overlay, not a cage. Notes can freely `[[wikilink]]` across MOCs and across domains. The system is a **wiki**, not a file tree.

### Methodology in One Sentence

**Zettelkasten** (one idea per note, connected by `[[wikilinks]]`) + **LYT MOCs** (curated navigation hubs). Structure emerges from links, not folders.

---

## 3. The Daily Rhythm

Akasha works on a morning/evening cadence. Two commands anchor the day.

### Morning: `/akasha-daily`

Scaffolds today's planning note. It reads yesterday's daily, your weekly goals, the current month's priorities, and your streak — then produces `Daily/YYYY-MM-DD.md` with:

- **Cascade context** — this week's ONE Thing, monthly Must/Should priorities, material chapters in progress.
- **Suggestions** — 1–3 items derived from your weekly deliverables (what's due, what was unfinished, what needs attention). These are *prompts*, not assignments.
- **Carry-over** — unfinished items from yesterday's top-3.
- **Streak status** — current streak length, which floors you're holding.

You fill in your top-3 and energy tag. The rest is pre-populated.

If today's daily already exists, it opens it without duplicating.

### During the Day

Capture freely — no agent required:

- **Quick text from terminal:** `/akasha-capture "Bayes theorem: P(H|E) = P(E|H)P(H) / P(E)"`
- **Math on paper:** Photograph with your phone, sync into `Inbox/`.
- **Direct in Obsidian:** Type a note in `Knowledge/` or drop a fleeting `.md` in `Inbox/`.

You can also search anytime: `/akasha-search linear algebra` or check status: `/akasha-status`.

### Evening: `/akasha-nightly`

The pipeline runs in four steps:

1. **Process Inbox** — reads every new capture in `Inbox/`, transcribes math photos to LaTeX, creates atomic notes in the right domain, places them in the deepest matching MOC, cross-links, and moves originals to `_processed/`.
2. **Adjust Goals** — checks today's daily for completed deliverables, reschedules slipped items forward, flags anything that's slipped 3+ times.
3. **Append Recap Scratch** — adds today's data (streak, deliverables, notes created) to the running scratch file for later recap generation.
4. **Update Hot Cache** — refreshes session continuity data so next session picks up where this one left off.

Output is a summary: notes created, updated, domains touched, MOC placements, proposed domains or MOC splits, and any alerts.

**Empty Inbox?** The pipeline reports "Nothing to process" and skips straight to goal adjustment. **Already processed?** Idempotent — re-running never creates duplicates.

---

## 4. Common Workflows

### 4.1 Capturing a Fleeting Thought

```
/akasha-capture "Zettelkasten: atomic notes, one idea each, connected by wikilinks"
```

Creates a timestamped file in `Inbox/` (e.g., `2026-06-30T09-15-00.md`). Processed on the next nightly run. No interaction needed — fire and forget.

### 4.2 Capturing Math / Diagrams (Photo Rail)

1. Write math on paper.
2. Photograph with your phone.
3. Sync the photo into `Inbox/` (Obsidian mobile or a synced folder).
4. On the next `/akasha-nightly`, the ingest agent transcribes the handwriting to LaTeX, creates a `type: math` note in `Knowledge/`, and preserves the original photo in `Inbox/_processed/` for reference.

The transcription starts as `status: seed` — review and refine it later. The original photo is never deleted, so you can always check the transcription against the source.

### 4.3 Running the Nightly Pipeline

```
/akasha-nightly
```

The pipeline processes everything in the Inbox. Watch the summary output:

- **Created:** Which new atomic notes were made, in which domains.
- **Updated:** Which existing notes were enriched or cross-linked.
- **MOC placements:** Where each note landed in the MOC hierarchy.
- **Proposals:** If a MOC hit 15+ notes (split candidate) or a new domain was suggested.
- **Goal adjustments:** Deliverables rescheduled, patterns flagged, staleness warnings.

If a step errors, the skill surfaces which step failed and why — it continues with remaining items rather than stopping completely.

### 4.4 Searching Your Knowledge

```
/akasha-search linear algebra
/akasha-search eigenvalue
```

Returns a ranked list of matching notes — title, domain, status, and a snippet showing the match context. Exact title matches come first, then wikilink matches, then body content matches. Read-only, no side effects.

If nothing matches, it offers to search `Inbox/` (unprocessed captures) and `Inbox/_processed/` (archived sources) as well.

### 4.5 Checking System Status

```
/akasha-status
```

A compact dashboard:

- **Inbox:** N items pending (lists filenames if ≤5)
- **Streak:** current length, last entry date, floor status (study/move/consume)
- **Domains:** note count per domain
- **Last nightly:** when the pipeline last ran
- **Health:** stale seed notes (>30d), any lint warnings

Instant, read-only. Useful as a quick check before starting your morning routine.

### 4.6 Running Vault Hygiene

```
/akasha-lint
```

Checks the entire `Knowledge/` and `Daily/` directories for:

- Orphaned notes (no incoming links)
- Broken `[[wikilinks]]`
- Missing frontmatter fields
- Empty body sections
- Stale `seed` notes older than 30 days
- Orphaned MOCs (not in any parent MOC or registry)
- Registry drift (MOCs in frontmatter but not in registry, or vice versa)
- Overfull MOCs (15+ direct notes — split candidate)
- Underfull MOCs (fewer than 3 notes — merge candidate)
- MOC chains deeper than 4 levels

**Report-only** — it never auto-fixes. Run it as part of your Sunday review. After reading the report, you decide what to address.

### 4.7 Setting Goals

Goal-setting at any level, two input modes:

**CLI brainstorming** (interactive, comprehensive):
```
/akasha-goal-set 4year
/akasha-goal-set semester
/akasha-goal-set monthly
/akasha-goal-set weekly
```

The agent reads your cascade context (what already exists above the target level), then walks you through a guided conversation covering all 6 life areas: academic, career, health, relationships, soul, financial. For semester and above, it produces a proposal and stops for confirmation before writing.

**File ingestion** (parse an existing document):
```
/akasha-goal-set monthly path/to/my-plan.md
```

The agent parses your file into the universal goal structure and asks "Adopt wholly or adjust?" If you want to tweak things, it runs a guided conversation to modify the content before writing.

### 4.8 Checking Goal Alignment

```
/akasha-goal-check
```

Read-only audit. Compares your recent dailies (last 7–14 days) against your active goals at all levels. Reports which goals are on track vs. drifting, with specific daily entries as evidence. Also checks goal ↔ domain mapping: for academic goals, it counts how many Knowledge notes exist in the linked domain as a gauge of learning progress.

Informational only. No side effects. Run it weekly or whenever you feel off-track.

### 4.9 Adjusting Goals

```
/akasha-goal-adjust
```

Runs the goal tracker: checks today's daily against this week's deliverables, reschedules slipped items forward, flags anything that's slipped 3+ times, surfaces Start/Stop/Continue if more than half the week's deliverables have slipped. Updates the weekly goal file with new due dates.

Also runs automatically as part of `/akasha-nightly`. You can run it on-demand whenever you want to rebalance.

Never marks anything as "failed" — only `pending`, `done`, `slipped`, `rescheduled`. If you want to drop a goal entirely, the agent moves it to `_not-doing.md` with an explicit note.

### 4.10 Managing Study Materials

1. Drop a course PDF in `StudyMaterials/inbox/`.
2. Run:
   ```
   /akasha-material-ingest
   ```
3. The agent extracts the table of contents, estimates per-chapter difficulty (page count + content complexity), and presents the structured TOC for your review. You can adjust chapter difficulties or reorder things.
4. On approval, it creates `StudyMaterials/active/<material-name>.md` with the full TOC, chapter page counts, difficulty ratings, and pacing notes. The PDF moves to `StudyMaterials/pdfs/`.

Materials link to semester goals through the `material:` frontmatter field — so your semester goal can reference "Strang — Linear Algebra" and the system knows which chapters are in play.

### 4.11 Weekly Review

```
/akasha-review
```

The 15-minute Sunday review. The agent reads your week's dailies and streak, then prompts you with five fixed questions (from the PKM accountability cascade). You answer interactively; the agent fills in `Reviews/YYYY-WXX.md`.

The review note includes:
- Your answers to the five questions
- A goal progress table (deliverable completion rates)
- A Start/Stop/Continue section for rebalancing
- Unfinished top-3 items carried over from the week

If you missed any daily notes, it flags the gaps without judgment.

### 4.12 Period Recaps

```
/akasha-recap weekly
/akasha-recap monthly
/akasha-recap semester
```

Factual, backward-looking snapshots — distinct from the weekly review (which is reflective). The recap answers "what actually happened" before the review asks "how did it feel."

**Weekly recap** includes: deliverable stats, streak, notes created, domains touched, MOC growth, Inbox processed, material chapters completed, study load (energy tag distribution), and upcoming deliverables.

**Monthly recap** aggregates 4–5 weeklies plus: Must/Should/Nice completion rates from the monthly goal, staleness warnings surfaced during the month, domain growth trends.

**Semester recap** aggregates monthlies plus: full material coverage (chapters done / total), total Knowledge notes created, evergreen count, domain growth summary, and a goal cascade retrospect.

**Biggest win:** The agent proposes 3 candidates from the period's data — e.g., "5-day study streak," "Finished 3 Strang chapters," "10 new notes across 3 domains." You pick one or write your own. The recap isn't saved until you confirm the biggest win.

Nightly runs silently accumulate raw data into scratch files (`.akasha/recap-*-scratch.md`) so the recap agent has a full picture when you invoke it.

### 4.13 Semester Transition

```
/akasha-semester-setup 2027-spring
```

Multi-step interactive process:
1. Archives current `StudyMaterials/active/` and `pdfs/` to `archive/<previous-term>/`.
2. Reads your 4-year vision and last semester's goal.
3. Asks about your focus, course load, and materials for the new term.
4. If PDFs are waiting in `StudyMaterials/inbox/`, offers to ingest each one.
5. Creates the new semester goal file with monthly breakdown and material references.

Summer terms follow the same flow — lighter expected load, same structure.

### 4.14 Adopting an Existing Vault

```
/akasha-adopt
```

One-time migration. Scans your existing vault (folders, tags, rough notes, source material), infers a MOC hierarchy from `[[wikilink]]` patterns, and produces a proposal table:

| Tag | → MOC Name | Level | Parent | Domain | Notes |
|-----|-----------|-------|--------|--------|-------|
| Machine Learning | Machine Learning MOC | topic | (domain root) | cs | KNN Basics, Deep Learning… |

Nothing moves until you confirm the proposal. On approval, it converts tags to MOCs, seeds `_moc-registry.md` per domain, migrates notes into domain folders with frontmatter backfill (never rewrites note bodies), and merges templates. Every step is a separate git commit — you can roll back anything.

---

## 5. Complete Command Reference

| Command | Arguments | What It Does |
|---------|-----------|-------------|
| `/akasha-daily` | *(none)* | Scaffold today's daily note with cascade context, suggestions, and carry-over |
| `/akasha-capture` | `"<text>"` | Quick-capture text to `Inbox/` with timestamp filename |
| `/akasha-nightly` | *(none)* | Run full nightly pipeline: ingest → goals → streak → recap scratch → hot cache |
| `/akasha-status` | *(none)* | System dashboard: Inbox count, streak, domains, last nightly, health |
| `/akasha-search` | `<topic>` | Ranked search across Knowledge base with snippets |
| `/akasha-lint` | *(none)* | Read-only vault hygiene report (orphans, broken links, frontmatter, MOC issues) |
| `/akasha-review` | *(none)* | Interactive 5-question weekly review → `Reviews/YYYY-WXX.md` |
| `/akasha-recap` | `weekly` / `monthly` / `semester` | Formatted period snapshot with biggest-win selection |
| `/akasha-goal-set` | `<level> [file]` | Create goal at any cascade level (CLI brainstorming or file ingestion) |
| `/akasha-goal-adjust` | *(none)* | Reschedule slipped deliverables, detect staleness, surface patterns |
| `/akasha-goal-check` | *(none)* | Read-only audit: dailies vs. active goals, with drift evidence |
| `/akasha-material-ingest` | `[filename]` | Extract TOC from PDF, create structured material note in `StudyMaterials/active/` |
| `/akasha-semester-setup` | `<term>` | Archive previous semester, create new semester + monthly goals |
| `/akasha-adopt` | *(none)* | One-time migration of existing Obsidian vault into Akasha structure |

---

## 6. Checkpoints — When to Do What

| When | Command(s) |
|------|-----------|
| **Every morning** | `/akasha-daily` |
| **Every evening** | `/akasha-nightly` |
| **Anytime** | `/akasha-capture`, `/akasha-search`, `/akasha-status` |
| **Sunday** | `/akasha-recap weekly`, `/akasha-review`, `/akasha-lint` |
| **Month end** | `/akasha-recap monthly`, `/akasha-goal-set monthly` |
| **Start of semester** | `/akasha-semester-setup`, `/akasha-goal-set semester` |
| **When slipping** | `/akasha-goal-adjust` |
| **New course PDF** | `/akasha-material-ingest` |
| **Weekly or biweekly** | `/akasha-goal-check` |
| **First time (existing vault)** | `/akasha-adopt` |

---

## 7. Design Philosophy

### The Agent Helps, It Never Blocks You

You can read, write, and capture notes with zero `cmdc` runs. The agent enriches — it files, links, transcribes. If Akasha is down for a week, your Inbox is still a readable pile of notes and your Knowledge base still works in Obsidian. This is the hard line between the system and the tool.

### No Guilt

There is no "N unprocessed" counter. The Inbox empties when you run nightly, and the streak is positive-only — it tracks what you *did*, not what you didn't. Skipped a day? The streak doesn't shame you. Just run `/akasha-nightly` when you're back.

### One Vault

Math photos and typed notes go to the same place. Two capture rails — photograph handwritten math, type code/concepts — one knowledge base. No split-by-mood, no multiple apps.

### Nothing Gets Duplicated

Re-running nightly on already-processed captures is safe. The ingest agent checks the index first and updates rather than duplicates. If you accidentally drop the same note twice, only one atomic note results.

### Raw Sources Are Preserved

Original math photos, capture files — everything stays in `Inbox/_processed/` forever. The `raw-guard.sh` hook enforces this: no write or edit to that directory is permitted. You can always check a LaTeX transcription against the original photo.

### Goals Suggest, Never Dictate

Daily suggestions from your goal cascade are prompts, not assignments. The system never blocks or warns if you ignore a suggestion. You choose what to adopt.

### Things Slip, Nothing Fails

Deliverables are `pending`, `done`, `slipped`, or `rescheduled` — never "failed" or "missed." If a deliverable slips, it moves forward to tomorrow or next week. If it slips 3+ times, the system flags it for a conversation about whether it belongs at a different priority level. If you decide to drop it entirely, it goes to `_not-doing.md` with an explicit note — not a silent deletion.

---

## 8. Troubleshooting & FAQ

### "My math photo didn't transcribe well"

Check the original in `Inbox/_processed/`. Transcriptions start as `status: seed` for a reason — they're a first pass, not ground truth. Open the generated `type: math` note, compare against the photo, and refine the LaTeX.

### "The nightly pipeline errored"

The skill surfaces which step failed and why in the summary output. Common causes: an image file format the model can't read (try converting to PNG/JPG), or a single Inbox item that causes the ingest agent to exceed its turn limit. If one item fails, the pipeline continues with the rest — only that item is affected.

### "I want a new Knowledge domain"

You don't create domain folders yourself. When the ingest agent encounters a note that doesn't fit any existing domain, it files it under the closest match and appends a one-line candidate under `## Proposed` in `Knowledge/_domains.md`. You promote it by hand — edit `_domains.md` to move it from Proposed to the approved list. This prevents domain sprawl while keeping the door open.

### "I want to split or reorganize a MOC"

Run `/akasha-lint`. It flags overfull MOCs (15+ direct notes) as split candidates. It proposes the split — e.g., "Eigenvalues and Diagonalization MOC" and "Norms and Inner Products MOC" could branch off "Vector Spaces MOC" — and suggests which notes would move. You decide. Nothing splits automatically.

### "Can I run nightly on a schedule? Like cron?"

It's manual by design, anchored to your evening planning ritual. A commuter laptop isn't reliably on at 11pm, and an invisible daemon is the kind of ignorable plumbing that tends to die quietly. Running `/akasha-nightly` as the last step of your evening planning peg keeps it rhythm-based and keeps you in the loop. That said, if you have a server or always-on machine, `bin/akasha-nightly.sh` is the underlying script — you can wire it to cron/launchd if you want to.

### "I missed a day (or a week)"

Just run `/akasha-nightly` whenever you're back. The streak log records what happened on each day you ran it — missed days are simply absent from the log, not marked as failures. `/akasha-daily` will scaffold today's note with whatever context is available. No catching up required.

### "How do I handle contradictions in my notes?"

If the ingest agent creates a note that contradicts an existing one, it adds a `> [!contradiction]` callout in the new note. You resolve the contradiction manually — the agent surfaces it, you decide which claim stands.

### "What happens if I edit an atomic note directly in Obsidian?"

That's expected. The agent creates and updates notes, but you're free to refine them — add connections, flesh out sections, promote from `seed` to `growing` to `evergreen`. The agent won't overwrite your manual edits unless you re-ingest the same source material, and even then it updates non-destructively (adds links, doesn't replace body text).

### "Where do I put my own notes vs. letting the agent handle it?"

- **Fleeting thoughts, rough drafts, math photos** → `Inbox/`. Let the nightly run process them.
- **Notes you want to write carefully now** → Create directly in `Knowledge/<domain>/` with the right template and frontmatter. The agent respects what's already there.
- **Daily planning, reviews** → Use `/akasha-daily` and `/akasha-review` — they scaffold from templates so formatting is consistent.

---

## 9. Quick Start Summary

If you read nothing else, read this:

1. **Morning:** `/akasha-daily` — see what's on your plate, set today's top-3.
2. **Capture freely:** `/akasha-capture "thought"` from terminal, or type/photograph into `Inbox/`.
3. **Evening:** `/akasha-nightly` — the agent files everything, adjusts goals, updates your streak.
4. **Sunday:** `/akasha-recap weekly` + `/akasha-review` + `/akasha-lint` — snapshot, reflect, clean up.
5. **When things slip:** `/akasha-goal-adjust` — reschedule, don't stress.

That's the system. Start capturing, and let the agent build your knowledge base.
