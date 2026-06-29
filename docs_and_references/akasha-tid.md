# Akasha — Technical Implementation Document (TID)

> **Akasha** — the note-taking system. A self-organizing Obsidian vault driven by Command Code (`cmdc`), built by porting two reference systems onto the commandcode harness rather than merging their code.
> 
> **Status:** Sprint 0 (design). This document is the deliverable of Sprint 0.
> **Phase:** This is the **Phase 1** automation layer from the Life OS roadmap. It sits *on top of* the Phase 0 manual capture rails and must never become plumbing the manual layer depends on (see §7, Invariant I-1).
> **Deviation:** Built ahead of the Life-OS Phase 1 gate (original trigger: floors held ~3–4 weeks; Phase 0 not yet running). Deliberate; Invariant I-1 (agent layer is enrichment, never plumbing) is the guardrail that keeps this safe.
> **Harness:** Command Code, `command-code` npm package, `cmdc` CLI, $1/mo plan.

---

## 1. Summary

Akasha turns a single Obsidian vault into a compounding knowledge base. You capture in two rails — handwritten math photographed into the vault, typed code/concept notes straight in — and a nightly `cmd` run reads the inbox, transcribes the math to LaTeX, files everything into atomic linked notes, updates an index + hot cache, and commits. A lightweight accountability layer (daily note, positive streak, weekly review) rides alongside.

It is built from two open-source systems, **ported** (not merged) onto commandcode:

| Source repo                    | What we take                                                            | What we drop                                                     |
| ------------------------------ | ----------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `ballred/obsidian-claude-pkm`  | accountability cascade (daily/weekly/goals), 4 agents, auto-commit hook | granular `.claude` permission lists, Claude-Code lifecycle hooks |
| `AgriciDaniel/claude-obsidian` | inbox→wiki ingest pattern, note-type templates, lint, hot cache, index  | ~2,700 LoC retrieval/DragonScale/locking/mode-router stack       |

**Why port, not merge:** the two repos target *different* harnesses (`.claude/`) and disagree on file layout. commandcode has a third config surface (`.commandcode/`) and a strictly smaller hook model. "Merging codebases" would mean reconciling three conventions and half the code wouldn't even fire. Re-implementing the *patterns* natively is less work and far more durable.

---

## 2. Goals / Non-goals

### Goals (v1)

- One vault, two capture rails, zero decisions at capture time.
- Nightly `cmd` run that files + links + transcribes inbox → Knowledge, idempotently.
- Photo-of-math → LaTeX transcription as a first-class path (the Phase 1 promise).
- Positive accountability: streak + floors + weekly review. **Never a visible accusing backlog.**
- Runs on the $1/mo plan with no VPS, no separate API bill, no always-on daemon required.
- Degrades gracefully: if `cmd` never runs, captures still land and stay readable.

### Non-goals (explicitly scoped OUT of v1, with rationale)

| Cut                                         | From                    | Why                                                                                                                                                 |
| ------------------------------------------- | ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| BM25 + rerank + contextual-prefix retrieval | autonote `scripts/*.py` | A single-user vault is searchable by commandcode `grep`/`glob` + Obsidian search. ~1,500 LoC + an embed cache for zero practical gain at this size. |
| DragonScale (addresses, tiling, log folds)  | autonote                | Solves problems of large multi-author wikis. Not yours. Pure maintenance surface.                                                                   |
| Per-file advisory locking (`wiki-lock.sh`)  | autonote                | Single user, single nightly writer. No concurrency to guard.                                                                                        |
| Methodology-mode router (LYT/PARA/Zettel)   | autonote `wiki-mode.py` | We hardcode **one** methodology — Zettelkasten + LYT (§5.0) — instead of a router you'd never reconfigure.                                          |
| `autoresearch`, `canvas` skills             | autonote                | Out of scope for note-taking; revisit only if a real need appears.                                                                                  |
| Fine-grained `permissions.allow/deny` lists | PKM `settings.json`     | commandcode uses permission *modes* + headless `--yolo`. Replaced by one `PreToolUse` guard hook (§5.3).                                            |

> Door left open: any cut item can be added later as an isolated module if a concrete need surfaces. None are load-bearing for v1.

---

## 3. Command Code harness — facts that constrain the design

Verified from the docs, not assumed:

- **Config lives in `.commandcode/`.** `settings.json` (user `~/.commandcode/`, project `.commandcode/`; project wins). Subagents in `.commandcode/agents/*.md`. Memory/bootstrap in `AGENTS.md` at project root.
- **Subagent file format:** YAML front matter `name`, `description` (when to delegate), `tools` (comma list or `"*"`); body = system prompt. **Reserved names (ignored if used):** `explore`, `plan`, `review`, `general`. → all runtime agents are prefixed `akasha-`.
- **Tool names differ from Claude Code.** Map on port: `Read→read_file`, `Write→write_file`, `Edit→edit_file`, `Bash→shell_command`, `Glob→glob`, `Grep→grep`, plus `think`. Drop `model:`, `memory:`, `maxTurns:` (not commandcode fields).
- **Hooks fire on only two events: `PreToolUse`, `PostToolUse`.** `type: "command"` only (no `type: "prompt"`). Matcher tests `tool_display_name` (`SHELL`/`READ`/`WRITE`/`EDIT`), e.g. `"write|edit"`. Hook reads a JSON payload on **stdin**; the edited path is `tool_input.file_path` (write/edit) — **not** an env var. Deny via `hookSpecificOutput.permissionDecision: "deny"` or exit `2`.
  - **Consequence:** the source repos' `SessionStart`, `UserPromptSubmit`, `Stop`, `PostCompact` hooks have **no commandcode equivalent**. Their jobs move to `AGENTS.md` (bootstrap/hot-cache load) and the nightly wrapper (hot-cache update). Only auto-commit survives as a real hook.
- **Headless mode is the automation entrypoint:** `cmd -p "<prompt>" --yolo --skip-onboarding --max-turns N`. Writes/shell are blocked unless `--yolo`. **Slash commands do not work headlessly** → the nightly run passes a prompt that *delegates to subagents*, it cannot call `/skills`. Each headless run is a standalone session (no history) — hence the hot cache.

---

## 4. Vault layout

The Obsidian vault root **is** the commandcode project root.

```
akasha/
├── .commandcode/
│   ├── settings.json            # hooks + env
│   ├── agents/                  # RUNTIME agents (the product)
│   │   ├── akasha-ingest.md
│   │   ├── akasha-lint.md
│   │   ├── akasha-weekly.md
│   │   ├── akasha-goal-align.md
│   │   └── akasha-adopt.md       # one-shot existing-vault migration
│   ├── hooks/
│   │   ├── auto-commit.sh        # ported from PKM
│   │   └── raw-guard.sh          # replaces permission lists
│   └── skills/
│       ├── akasha-nightly/
│       │   └── SKILL.md
│       ├── akasha-lint/
│       │   └── SKILL.md
│       ├── akasha-review/
│       │   └── SKILL.md
│       ├── akasha-goal-check/
│       │   └── SKILL.md
│       ├── akasha-adopt/
│       │   └── SKILL.md
│       ├── akasha-search/
│       │   └── SKILL.md
│       ├── akasha-status/
│       │   └── SKILL.md
│       ├── akasha-daily/
│       │   └── SKILL.md
│       └── akasha-capture/
│           └── SKILL.md
├── AGENTS.md                     # bootstrap + conventions (was SessionStart)
├── bin/
│   ├── akasha-nightly.sh         # headless entrypoint
│   └── prompts/
│       ├── process-inbox.md
│       └── update-hotcache.md
├── Inbox/                        # capture drop zone
│   └── _processed/               # raw sources after ingest (immutable archive)
├── Knowledge/                    # generated atomic notes (agent-owned)
│   ├── math/                     # domain folders only — see _domains.md
│   ├── cs/
│   ├── quant/                    # examples; driven by _domains.md approved list
│   ├── _domains.md               # domain registry (controlled vocabulary)
│   └── _index.md                 # master index (+ MOC list)
├── Daily/                        # tonight-only plan + streak line
├── Reviews/                      # weekly / Sunday reviews
├── Templates/                    # concept, math, source, entity, question, moc, daily, weekly
└── .akasha/
    ├── hot.md                    # hot cache (session continuity)
    └── streak.md                 # positive floors/streak log
```

**Inbox vs Knowledge boundary** (from autonote's `.raw/` → `wiki/` split): `Inbox/` is human-owned and the ingest agent never rewrites a raw capture — it reads, transcribes into a *new* Knowledge note, then moves the original into `Inbox/_processed/`. Math photos are kept (not deleted) so a LaTeX transcription can be re-checked against the source.

---

## 5. Runtime components

### 5.0 Methodology — Zettelkasten + LYT (hardcoded, no router)

Akasha's knowledge layer is **Zettelkasten substrate + LYT hubs**, chosen deliberately over PARA:

- **Zettel substrate.** Atomic notes, one idea each, connected by `[[wikilinks]]`. Structure emerges from links, not folders. This is what `akasha-ingest` produces by construction, and it matches the existing vault — so the old vault folds in with zero reformatting (§5.6).
- **LYT hubs (MOCs).** A **Map of Content** is a curated, ordered, annotated hub note (`type: moc`) — e.g. `Linear Algebra MOC`, `AWS AI Practitioner MOC` — that you *learn from*. MOCs carry the navigational structure, so domain folders can stay few. Made by hand (or proposed by `akasha-lint`) when a cluster grows large enough to deserve navigation; never auto-generated wholesale.
- **PARA is deliberately NOT used in the knowledge vault.** Project/action organization lives in the accountability layer (§5.5: Daily / Reviews / goal-align), not in Knowledge. Filing knowledge by *project* fragments a concept across every project that touches it — the exact failure mode this system exists to prevent. Knowledge is filed by *what an idea is*; action is tracked separately.

Domain folders (`math/`, `cs/`, …) are coarse buckets only; the real structure is wikilinks + MOCs.
A note's **physical location** is always its domain folder. Its **type** (`concept|math|source|entity|question|moc`) lives in the `type:` frontmatter field, never as a subdirectory — there are no `concepts/` or `entities/` folders under `Knowledge/`. This avoids dual-axis fragmentation (domain × type).

### 5.1 Note data model

Six note types, each a `Templates/` file with frontmatter (ported from autonote's templates, trimmed):

```yaml
---
type: concept | math | source | entity | question | moc
title: ""
status: seed            # seed → growing → evergreen
domain: ""              # math, cs, quant, ...
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []
related: []             # [[wikilinks]]
sources: []             # [[source notes]] / Inbox/_processed/<file>
---
```

A note's physical location is its **domain** folder under `Knowledge/`; its **type** lives in frontmatter — there are no `concepts/` or `entities/` subdirectories. `math` adds nothing structural — it just signals "body is LaTeX-heavy, transcribed from a photo source." Keep the body sections minimal (Definition / Why it matters / Connections) to avoid empty-section lint noise. `moc` notes live in their primary domain folder (or `Knowledge/` root if cross-domain); all MOCs are listed in `_index.md`. `moc` is a curated hub (§5.0): its body is a hand-ordered, annotated link list, exempt from empty-section lint.

The `daily` and `weekly` templates are **accountability** templates, separate from the six knowledge note types above — they live in `Templates/` alongside the knowledge set but apply only to `Daily/` and `Reviews/`.

### 5.2 `akasha-ingest` (the core agent)

Ported from autonote `wiki-ingest`, simplified (no locking, no address allocator, no mode router). One source in → atomic notes out.

```markdown
---
name: akasha-ingest
description: Process one Inbox item — text note or photo of math. Read it, (transcribe to LaTeX if an image), route into an existing domain from _domains.md (propose new ones, never auto-create), extract concepts/entities, create or update atomic notes under Knowledge/, cross-link, update _index.md, then move the raw source to Inbox/_processed/. Delegate one agent per Inbox item.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
You integrate ONE source into the Knowledge base.

Process:
1. Read the source fully. If it's an image, transcribe handwritten math to
   clean LaTeX/Markdown; preserve diagrams as described figures.
2. Read Knowledge/_index.md (avoid duplicates) and Knowledge/_domains.md
   (the allowed domain list).
3. Pick the closest EXISTING domain. If nothing fits, file under the nearest
   one anyway and append a one-line candidate under the "## Proposed" section
   of _domains.md — do NOT create a new domain folder yourself.
4. For each significant concept/entity: create OR update the atomic note under
   Knowledge/<domain>/ using the matching Template (never route by type-folder;
   type is frontmatter only). status: seed.
5. Cross-link with [[wikilinks]] to existing related notes. If a relevant MOC
   exists, add the new note under the right MOC heading.
6. Update Knowledge/_index.md.
7. If a claim contradicts an existing note, add a "> [!contradiction]" callout.
8. Move the raw source to Inbox/_processed/ (do NOT edit it in place).
9. Report: Created / Updated / Source-archived / Proposed-domain (if any) /
   one-line key insight.

Never: create a new domain folder unprompted, edit anything under
Inbox/_processed/, delete a raw capture, or duplicate a note already in _index.md.
```

### 5.3 Hooks (the only two that exist on commandcode)

**`auto-commit.sh`** — ported from PKM. Note the key change: path comes from stdin JSON, not `$TOOL_INPUT_FILE_PATH`.

```bash
#!/usr/bin/env bash
set -euo pipefail
payload=$(cat)
cwd=$(printf '%s' "$payload" | jq -r '.cwd')
cd "$cwd" || exit 0
[ -d .git ] || exit 0
git add -- Knowledge/ Inbox/ Daily/ Reviews/ .akasha/ 2>/dev/null || true
git diff --cached --quiet && exit 0
git commit -q -m "akasha: auto-commit $(date '+%Y-%m-%d %H:%M')" || true
```

**`raw-guard.sh`** — replaces PKM's permission lists with one guard: refuse any write/edit to immutable sources.

```bash
#!/usr/bin/env bash
set -euo pipefail
payload=$(cat)
fp=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')
if [[ "$fp" == *"/Inbox/_processed/"* ]]; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",
    permissionDecision:"deny",
    permissionDecisionReason:"Inbox/_processed holds immutable raw captures. Create or edit a note under Knowledge/ instead."}}'
fi
exit 0
```

**`settings.json`** wiring:

```json
{
  "hooks": {
    "PreToolUse":  [ { "matcher": "write|edit",
      "hooks": [ { "type": "command", "command": "./.commandcode/hooks/raw-guard.sh", "timeout": 5 } ] } ],
    "PostToolUse": [ { "matcher": "write|edit",
      "hooks": [ { "type": "command", "command": "./.commandcode/hooks/auto-commit.sh" } ] } ]
  }
}
```

### 5.4 `AGENTS.md` (does the SessionStart job)

Because there is no `SessionStart` hook, bootstrap lives here:

- Vault conventions + the Inbox/Knowledge boundary.
- "At the start of any session, silently read `.akasha/hot.md` to restore recent context. Do not announce it."
- Capture-rail rules and the note templates to use.
- **Invariant I-1 stated explicitly** so every session respects it.

### 5.5 Accountability layer (ported from PKM, renamed off reserved words)

- `Daily/<date>.md` — tonight-only plan: top-3, energy tag, fried-day fallback reminder. (Matches Phase 0 design exactly.)
- `.akasha/streak.md` — positive yes/no log for the three floors (study / move / consume). No backlog, no accusing pile.
- `akasha-weekly` agent — the 15-min Sunday review, five fixed questions.
- `akasha-goal-align` agent — audits recent dailies against the cert/math goal; flags drift. Read-only.

### 5.6 `akasha-adopt` (one-shot existing-vault migration)

Ported from PKM's `/adopt`. A **one-time, non-destructive** agent that folds an existing vault into Akasha so the old vault isn't left behind. Because the existing vault is already Zettel + folders (atomic notes, links, a Tags hub layer), it maps in cleanly with no reformatting.

```markdown
---
name: akasha-adopt
description: One-time migration of an existing Obsidian vault into Akasha structure. Scans folders, detects the org method, proposes a mapping, and on confirmation moves/registers content non-destructively. Run once, manually.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
You migrate an existing vault into Akasha. NON-DESTRUCTIVE and INCREMENTAL.

Process:
1. Scan the source vault: folders, note count, frontmatter presence, link
   density. Detect the org method (expect Zettel + folders).
2. Produce a MAPPING REPORT (folder -> Akasha target) and STOP for
   confirmation. Change nothing yet.
3. On approval, execute in small git-committed steps, one folder at a time:
   - Rough/fleeting folders -> Inbox/ (re-ingested via akasha-ingest)
   - Source-material folders -> Knowledge/ (type: source), backfill frontmatter
   - Tag/index/hub notes      -> MOCs (type: moc)
   - Template folders         -> merged into Templates/ (never overwrite)
   - Seed Knowledge/_domains.md from the folders actually found
4. Leave already-atomic notes in place; backfill MISSING frontmatter only.
5. Report what moved, what was registered, and any notes needing manual review.

Never: rewrite the body of an existing atomic note, overwrite a template, or
proceed past step 2 without explicit confirmation.
```

Default mapping for the current vault (folder `4` was collapsed in the screenshot; it's resolved at scan time):

| Existing folder      | → Akasha target                                           |
| -------------------- | --------------------------------------------------------- |
| `1- Rough Notes`     | `Inbox/` (re-ingest)                                      |
| `2- Source Material` | `Knowledge/` (`type: source`)                             |
| `3 - Tags`           | MOCs (`type: moc`)                                        |
| `5 - Templates`      | `Templates/` (merge; keep `Metalearning`, `People`, etc.) |

### 5.7 Skill catalog

All user-facing operations are invoked as slash commands. Skills either wrap an existing agent or compose multiple agents/scripts into a single workflow. No shell commands required.

#### `/akasha-nightly` — run the ingest pipeline

Wraps the headless `cmd` calls from §6.2. Delegates to `akasha-ingest` for each Inbox item, then updates the hot cache.

- **When:** End of day, anchored to the nightly planning ritual.
- **Input:** None — reads everything in `Inbox/` (excluding `_processed/`).
- **Output:** Summary — items processed, notes created/updated, domains touched, any proposed domains. Errors surfaced immediately with log tails.
- **Edge cases:** Empty Inbox → "Nothing to process." Already-processed items → skipped (idempotent). Agent error → surfaces which item failed and why, continues with remaining items.

#### `/akasha-lint` — vault hygiene check

Runs the `akasha-lint` agent for read-only health checks.

- **When:** Sunday review, or anytime you want a health check.
- **Input:** None — scans entire `Knowledge/` and `Daily/`.
- **Output:** Report grouped by issue type: orphaned notes (no incoming links), broken `[[wikilinks]]`, missing frontmatter fields, empty body sections, `seed` notes older than 30 days. Each issue includes file path and line number.
- **Behavior:** Report-only, never auto-fixes. After reading the report, you can ask the agent to fix specific issues in a follow-up message.
- **Edge cases:** Clean vault → "No issues found." Many issues → capped at 50 per type, with a count of remaining.

#### `/akasha-review` — weekly Sunday review

Runs the `akasha-weekly` agent to produce a structured weekly review.

- **When:** Sunday (or whenever you want to do a weekly review). Part of the weekly planning ritual.
- **Input:** Reads the week's `Daily/*.md` files and `.akasha/streak.md`.
- **Output:** Creates `Reviews/YYYY-WXX.md` from the weekly template. The agent reads your week and prompts you with five fixed questions (from the PKM accountability cascade). You answer interactively; the agent fills in the review note.
- **Behavior:** Carries over any unfinished top-3 items from the week's dailies. Highlights streak breaks. Flags if any daily notes are missing (gaps in the week).
- **Edge cases:** No dailies this week → prompts you to reflect on why, no judgment. Review already exists → appends to it rather than overwriting.

#### `/akasha-goal-check` — goal alignment audit

Runs the `akasha-goal-align` agent to check progress against stated goals.

- **When:** Weekly or biweekly, during review or standalone.
- **Input:** Reads recent `Daily/*.md` (last 7–14 days), `Reviews/*.md`, and the goal definitions (from `AGENTS.md` or a goals file).
- **Output:** Read-only report — which goals are on track, which are drifting, with specific daily entries as evidence. Suggests adjustments but takes no action.
- **Behavior:** Informational only. No side effects, no file writes. Designed to be fast and non-intrusive.
- **Edge cases:** No recent dailies → reports insufficient data. No goals defined → prompts you to set some.

#### `/akasha-adopt` — migrate existing vault

Runs the `akasha-adopt` agent for one-time migration of an existing Obsidian vault.

- **When:** Once, when setting up Akasha with an existing vault.
- **Input:** Scans the current vault structure — folders, note count, frontmatter presence, link density.
- **Output:** Multi-step interactive process. First produces a mapping report (folder → Akasha target) and stops for explicit confirmation. On approval, executes migration in small git-committed steps.
- **Behavior:** Non-destructive. Leaves atomic note bodies untouched, only backfills missing frontmatter. Never overwrites templates. Each step is a separate git commit for reversibility.
- **Edge cases:** Already adopted → detects existing Akasha structure and warns. Partial migration → can resume from where it left off (checks what's already been moved).

#### `/akasha-search <topic>` — query the knowledge base

Searches Knowledge for notes matching a topic.

- **When:** Anytime you want to find what you know about something.
- **Input:** A topic string (e.g., `/akasha-search linear algebra`).
- **Output:** Ranked list of matching notes — title, domain, status, and a brief snippet showing the match context. Organized with exact title matches first, then wikilink matches, then body content matches.
- **Behavior:** Read-only, no side effects. Searches `Knowledge/` by default. If no results, offers to search `Inbox/` (unprocessed captures) and `Inbox/_processed/` (archived sources) as well.
- **Edge cases:** No results anywhere → suggests the topic might not exist yet, offers to create a seed note. Very broad query (e.g., "math") → caps at 20 results, suggests narrowing.

#### `/akasha-status` — system dashboard

Shows the current state of the Akasha system at a glance.

- **When:** Anytime — quick sanity check before nightly, during reviews, or just to see how things are going.
- **Input:** None.
- **Output:** A compact dashboard showing:
  - **Inbox:** N items pending (list filenames if ≤5)
  - **Streak:** current streak length, last entry date, floors status (study/move/consume)
  - **Domains:** note count per domain from `_domains.md`
  - **Last nightly:** timestamp from git log or hot.md
  - **Health:** count of `seed` notes >30d (stale), any lint warnings
- **Behavior:** Read-only, instant, no side effects. Pulls from multiple files but writes nothing.
- **Edge cases:** First run (no data yet) → shows zeros and onboarding hints. Missing files (no streak.md yet) → shows "not initialized" for that section.

#### `/akasha-daily` — create today's daily note

Scaffolds today's daily note from the template.

- **When:** Start of day, or when you want to plan. Part of the daily planning ritual.
- **Input:** None — uses today's date.
- **Output:** Creates `Daily/YYYY-MM-DD.md` from the daily template. Pre-populates:
  - Carries over unfinished top-3 items from yesterday's daily (items without checkmarks)
  - Reads `.akasha/hot.md` for recent context
  - Leaves energy tag and new top-3 for you to fill in
- **Behavior:** Idempotent — if today's daily already exists, opens it instead of creating a duplicate. Never overwrites existing content.
- **Edge cases:** No yesterday daily → creates fresh with empty top-3. Yesterday had no unfinished items → empty carry-over section.

#### `/akasha-capture "text"` — quick capture to inbox

Appends a quick typed note to the Inbox without opening Obsidian.

- **When:** Anytime you have a fleeting thought, code snippet, or concept you want to capture from the terminal.
- **Input:** Text content (e.g., `/akasha-capture "Zettelkasten: atomic notes, one idea each, linked by wikilinks"`).
- **Output:** Creates a new file in `Inbox/` with a timestamp-based filename (e.g., `2025-01-15T14-30-00.md`) containing the text. Minimal frontmatter (date, status: seed).
- **Behavior:** Quick, one-shot, no interaction needed. This is the cmdc-native capture rail — complements the photo sync rail (math/photos) and direct Obsidian typing (code/concepts).
- **Edge cases:** Multi-line text → handled gracefully, preserves formatting. Empty input → prompts for content. This rail is text-only; images still go through the photo sync path.

---

## 6. Key flows

### 6.1 Capture (manual, always-on, no agent)

- **Math/graphs:** paper → phone photo → synced into `Inbox/` (Obsidian mobile or a synced folder).
- **Code/concepts:** typed in Obsidian, either authored directly in `Knowledge/` or dropped as a fleeting `.md` in `Inbox/`.

### 6.2 Nightly run — `/akasha-nightly` skill

The nightly pipeline is wrapped in a skill so it's invokable as a slash command — no manual shell commands needed.

**Invocation:** `/akasha-nightly` (or `/akasha-nightly` typed in any cmdc session in the vault).

**Under the hood**, the skill runs two headless `cmd` calls sequentially:

```bash
cd "$HOME/akasha"
cmd -p "$(cat bin/prompts/process-inbox.md)"   --yolo --skip-onboarding --max-turns 60
cmd -p "$(cat bin/prompts/update-hotcache.md)" --yolo --skip-onboarding --max-turns 8
```

`process-inbox.md` instructs the main session: *"List every file in `Inbox/` (excluding `_processed/`). For each, delegate to the `akasha-ingest` agent. After all are filed, update `Knowledge/_index.md`."* (Delegation works headlessly; slash commands don't — hence prompt-driven, not `/skill`-driven.)

**Error surfacing:** The skill captures exit codes and stderr from both `cmd` runs. If either fails, it surfaces the error summary to the user — e.g. which agent errored, how many items processed before failure, and the relevant log tail. No silent failures.

**Trigger: manual, anchored to the 10:00 planning ritual — not cron.** A commuter laptop isn't reliably on at 11pm, and an invisible daemon is exactly the kind of ignorable plumbing that died before. Running `/akasha-nightly` as the last step of the existing nightly planning peg keeps it rhythm-based and keeps you in the loop. Cron/launchd is an optional later add, not a dependency.

**`bin/akasha-nightly.sh`** still exists as the script the skill delegates to — it can also be run directly if needed, but the skill is the primary interface.

### 6.3 Hygiene (weekly, opt-in)

`akasha-lint` (ported autonote `wiki-lint`, stripped of DragonScale checks): orphans, dead `[[links]]`, missing frontmatter, empty sections, stale `seed` notes >30d. **Reports only, never auto-fixes.** Run it as part of the Sunday review.

---

## 7. Design invariants

- **I-1 — Agent layer is enrichment, never plumbing.** Capture and reading work with zero `cmd` runs. The agent only files/links/transcribes. If Akasha is down for a week, the Inbox is still a readable pile of notes. *This is the hard line between the Phase 0 life layer and the Phase 1 build layer.*
- **I-2 — No accusing backlog.** No surfaced "N unprocessed" counter, ever. The Inbox empties nightly; the streak is positive-only. (Notion died of this.)
- **I-3 — One home.** No split-by-mood. Rails split by *content type* only (photo-math vs typed-code), both landing in one vault.
- **I-4 — Idempotent ingest.** Re-running on an already-filed source updates, never duplicates (index check in `akasha-ingest` step 2).
- **I-5 — Raw sources immutable.** Enforced by `raw-guard.sh`, not by trust.

---

## 8. Build plan — sprints, worktrees, subagent ownership, merge order

**Dev subagents** (live in the *build repo's* `.commandcode/agents/`, distinct from the runtime `akasha-*` agents which are the product):

| Dev subagent              | Owns                                                                    |
| ------------------------- | ----------------------------------------------------------------------- |
| `substrate-engineer`      | vault folders, templates, index/hot-cache/streak stubs                  |
| `harness-engineer`        | `.commandcode/` config, hooks, `AGENTS.md`, `bin/` wrappers             |
| `pipeline-engineer`       | `akasha-ingest`, process-inbox prompt, image→LaTeX path, `akasha-adopt` |
| `accountability-engineer` | daily/streak/floors, `akasha-weekly`, `akasha-goal-align`               |
| `hygiene-engineer`        | `akasha-lint`, lightweight query prompt                                 |
| `verifier`                | read-only pre-merge audit (ported from autonote `verifier.md`)          |

**Worktree mechanics.** One repo, one worktree per parallel stream off a per-sprint integration branch:

```bash
git worktree add ../akasha-substrate feat/substrate
git worktree add ../akasha-harness   feat/harness
# each owned by one dev subagent, run in its own `cmd` session
```

**Merge gate.** Before any feature branch merges into its sprint branch, dispatch `verifier` against the staged diff (read-only). Merge only on a clean verdict. Sprint branches merge to `main` in sprint order.

---

### Sprint 1 — Substrate & Harness (foundation)

| #   | Worktree / branch | Owner              | Scope                                                                                              | Depends on      |
| --- | ----------------- | ------------------ | -------------------------------------------------------------------------------------------------- | --------------- |
| 1   | `feat/substrate`  | substrate-engineer | folder tree, 8 templates (6 knowledge + 2 accountability), `_index.md`, `hot.md`/`streak.md` stubs | —               |
| 2   | `feat/harness`    | harness-engineer   | `settings.json`, `auto-commit.sh`, `raw-guard.sh`, `AGENTS.md`, `bin/` stubs, `/akasha-nightly` skill | substrate paths |

**Merge order:** `substrate` → `harness` → `sprint-1` → `main`.
**Acceptance:** a `cmd` session in the vault loads `hot.md` via `AGENTS.md`; a write to `Knowledge/` triggers an auto-commit; a write to `Inbox/_processed/` is denied by the guard; `/akasha-nightly` runs the pipeline and surfaces any errors.

### Sprint 2 — Capture & Ingest (the engine)

| #   | Worktree / branch | Owner             | Scope                                                                           | Depends on             |
| --- | ----------------- | ----------------- | ------------------------------------------------------------------------------- | ---------------------- |
| 1   | `feat/ingest`     | pipeline-engineer | `akasha-ingest` agent, `process-inbox.md`, index update, idempotency (I-4)      | Sprint 1               |
| 2   | `feat/vision`     | pipeline-engineer | photo→LaTeX transcription rules, `math` template wiring, `_processed/` archival | `feat/ingest` contract |
| 3   | `feat/capture`    | pipeline-engineer | `/akasha-capture` skill for cmdc-native quick capture to Inbox                  | Sprint 1               |

**Merge order:** `ingest` → `vision` → `capture` → `sprint-2` → `main`.
**Acceptance:** dropping one typed note + one math photo in `Inbox/`, then running `/akasha-nightly`, yields two linked Knowledge notes (math one in LaTeX), an updated `_index.md`, both sources in `_processed/`, and a re-run creates no duplicates. `/akasha-capture "test note"` creates a file in `Inbox/` that gets processed on the next nightly run.

### Sprint 2.5 — Adopt existing vault (one-shot)

| #   | Worktree / branch | Owner             | Scope                                                                                 | Depends on              |
| --- | ----------------- | ----------------- | ------------------------------------------------------------------------------------- | ----------------------- |
| 1   | `feat/adopt`      | pipeline-engineer | `akasha-adopt` agent, `/akasha-adopt` skill, mapping report, non-destructive migration | Sprint 2 (needs ingest) |

**Merge order:** `adopt` → `sprint-2.5` → `main`.
**Acceptance:** a dry run produces a folder→target mapping report and changes nothing; on approval the existing vault's notes land in Akasha with frontmatter backfilled, `3 - Tags` hub notes become MOCs, templates merged (none overwritten), `_domains.md` seeded from real folders — all reversible via git, no atomic-note bodies rewritten. `/akasha-adopt` is invokable as a slash command and handles the interactive confirmation flow.

### Sprint 3 — Accountability & Review

| #   | Worktree / branch | Owner                   | Scope                                                                     | Depends on    |
| --- | ----------------- | ----------------------- | ------------------------------------------------------------------------- | ------------- |
| 1   | `feat/streak`     | accountability-engineer | daily-note flow, `streak.md` positive tracker, floors, fried-day fallback | Sprint 1      |
| 2   | `feat/review`     | accountability-engineer | `akasha-weekly` + `akasha-goal-align` agents, `/akasha-review` + `/akasha-goal-check` + `/akasha-daily` skills | `feat/streak` |

**Merge order:** `streak` → `review` → `sprint-3` → `main`.
**Acceptance:** `/akasha-daily` creates today's daily from template with carry-over from yesterday; `/akasha-review` reads the week's dailies + streak and produces the five-question review under the 15-min format; `/akasha-goal-check` audits recent dailies against goals and reports drift; no accusing backlog is surfaced anywhere (I-2 check).

### Sprint 4 — Hygiene & Query (polish)

| #   | Worktree / branch | Owner            | Scope                                                             | Depends on |
| --- | ----------------- | ---------------- | ----------------------------------------------------------------- | ---------- |
| 1   | `feat/lint`       | hygiene-engineer | `akasha-lint` agent, `/akasha-lint` skill (orphans/dead-links/frontmatter), report-only | Sprint 2   |
| 2   | `feat/query`      | hygiene-engineer | `akasha-query` agent, `/akasha-search` + `/akasha-status` skills  | Sprint 2   |

**Merge order:** `lint` → `query` → `sprint-4` → `main`. Final `verifier` pass → tag `v0.1`.
**Acceptance:** `/akasha-lint` flags a deliberately-orphaned note; `/akasha-search linear algebra` returns matching Knowledge notes with snippets; `/akasha-status` shows inbox count, streak, domain breakdown, and last nightly timestamp; all three are read-only and invokable as slash commands.

**Overall merge order:** `sprint-1 → sprint-2 → sprint-2.5 → sprint-3 → sprint-4 → main`.

> Solo-dev note: the two worktrees per sprint are *optional* parallelism. If juggling two `cmd` sessions adds friction, run them sequentially on one branch — the dependency arrows already give a safe linear order. Don't let the build orchestration become its own maintenance project.

---

## 9. Risks & open questions

- **Vision/LaTeX accuracy** on messy handwriting is the biggest unknown. Mitigation: keep raw photos in `_processed/`; treat transcriptions as `status: seed` for review, not ground truth.
- **`--max-turns 60`** may be tight for a large Inbox; raise per run or chunk the Inbox.
- **commandcode model choice** for vision: confirm which available model handles image input on the $1 plan before Sprint 2 (the docs list Claude Opus/Sonnet/Haiku among providers).
- **Sync reliability** of phone→`Inbox/` is outside the harness; pick the sync mechanism (Obsidian mobile vs synced folder) before Sprint 2.

## 10. Decisions — resolved

1. **Vault path** — `~/akasha`. ✅
2. **Domains** — flexible via `Knowledge/_domains.md`: `akasha-ingest` files into existing domains only and *proposes* new ones under a `## Proposed` heading; you promote them by hand. Auto-suggest, manual-confirm — no silent sprawl. ✅
3. **Trigger** — manual, anchored to the nightly planning ritual. ✅
4. **Build style** — linear single-branch (two-worktree parallelism stays optional, per §8). ✅

**Methodology (new):** Zettelkasten + LYT MOCs, hardcoded; PARA explicitly not used in the knowledge vault (§5.0).
**Existing vault (new):** folded in via the one-shot `akasha-adopt` agent (§5.6 / Sprint 2.5), non-destructive and reversible.
