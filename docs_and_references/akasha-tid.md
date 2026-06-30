# Akasha — Technical Implementation Document (TID)

> **Akasha** — the note-taking system. A self-organizing Obsidian vault driven by Command Code (`cmdc`), built by porting two reference systems onto the commandcode harness rather than merging their code.
> 
> **Status:** Sprint 0 (design). This document is the deliverable of Sprint 0.
> **Phase:** This is the **Phase 1** automation layer from the Life OS roadmap. It sits *on top of* the Phase 0 manual capture rails and must never become plumbing the manual layer depends on (see §7, Invariant I-1).
> **Deviation:** Built ahead of the Life-OS Phase 1 gate (original trigger: floors held ~3–4 weeks; Phase 0 not yet running). Deliberate; Invariant I-1 (agent layer is enrichment, never plumbing) is the guardrail that keeps this safe.
> **Harness:** Command Code, `command-code` npm package, `cmdc` CLI, $1/mo plan.

## 1. Summary

Akasha turns a single Obsidian vault into a compounding knowledge base. You capture in two rails — handwritten math photographed into the vault, typed code/concept notes straight in — and a nightly `cmd` run reads the inbox, transcribes the math to LaTeX, files everything into atomic linked notes, updates an index + hot cache, and commits. A lightweight accountability layer (daily note, positive streak, weekly review) rides alongside. An automated recap system silently accumulates raw data nightly; when invoked, it produces formatted period snapshots (weekly / monthly / semester) with deliverable stats, streak data, knowledge growth, and a user-chosen "biggest win" — factual backward-looking mirrors to the review's forward-looking reflection.

A **goal cascade** (4-year vision → semester → monthly → weekly) feeds directly into the daily and nightly flows, grounding every day's plan in long-term intent. Study materials (ebook PDFs) are ingested, TOC-extracted, and used to derive semester goals with per-chapter pacing. Goals auto-adjust when deliverables slip — rescheduling forward rather than marking failure — and surface gentle nudges after repeated slips. The goal system connects to the Knowledge domain structure, so academic goals map to `math/`, `cs/`, `quant/` domains.

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
- Goal cascade (4-year → semester → monthly → weekly) that grounds daily planning in long-term intent, with auto-adjustment when deliverables slip.
- Study material management: PDF ingestion, TOC extraction, chapter pacing derived from materials, active/archive lifecycle per semester.
- Goal ↔ domain mapping: academic goals linked to Knowledge domains (`math/`, `cs/`, `quant/`), creating a bridge between *what you're studying* and *what you've learned*.
- Runs on the $1/mo plan with no VPS, no separate API bill, no always-on daemon required.
- Automated period recaps (weekly / monthly / semester) — factual snapshots of what happened: deliverable completion, streak data, knowledge growth, material progress, biggest win, upcoming deliverables. Hybrid trigger: nightly silently appends scratch data; user invokes manually to produce the formatted recap.
- All the above degrades gracefully: if `cmd` never runs, captures still land and stay readable.

### Non-goals (explicitly scoped OUT of v1, with rationale)

| Cut                                         | From                    | Why                                                                                                                                                 |
| ------------------------------------------- | ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| BM25 + rerank + contextual-prefix retrieval | autonote `scripts/*.py` | A single-user vault is searchable by commandcode `grep`/`glob` + Obsidian search. ~1,500 LoC + an embed cache for zero practical gain at this size. |
| DragonScale (addresses, tiling, log folds)  | autonote                | Solves problems of large multi-author wikis. Not yours. Pure maintenance surface.                                                                   |
| Per-file advisory locking (`wiki-lock.sh`)  | autonote                | Single user, single nightly writer. No concurrency to guard.                                                                                        |
| Methodology-mode router (LYT/PARA/Zettel)   | autonote `wiki-mode.py` | We hardcode **one** methodology — Zettelkasten + LYT (§5.0) — instead of a router you'd never reconfigure.                                          |
| `autoresearch`, `canvas` skills             | autonote                | Out of scope for note-taking; revisit only if a real need appears.                                                                                  |
| Fine-grained `permissions.allow/deny` lists | PKM `settings.json`     | commandcode uses permission *modes* + headless `--yolo`. Replaced by one `PreToolUse` guard hook (§5.3).                                            |
| Effort allocation percentages | PKM `Goals/1. Yearly Goals.md` | Area weighting (e.g., 40% career, 20% health) is overengineered for a student's goal system. Priority is expressed through 3-tier Must/Should/Nice, not percentage splits. |
| Separate "Projects" bridge layer | PKM `Projects/*/CLAUDE.md` | Akasha already has Knowledge domains as the bridge between goals and learning. A separate project layer would duplicate this. |
| Coach-style emotional probing | PKM daily skill | "How do you want to feel at end of day?" doesn't fit Akasha's directness. Goal-setting is comprehensive but focused on deliverables, not feelings. |
| Automatic goal rebalancing without confirmation | PKM goal-aligner | Auto-adjustment only reschedules slipped deliverables forward. Structural changes (dropping goals, changing semester scope) always require explicit confirmation. |

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
│   │   ├── akasha-goal-setter.md    # interactive goal creation at any level
│   │   ├── akasha-goal-tracker.md   # progress calc, staleness, adjustment
│   │   ├── akasha-material-parser.md # PDF → structured TOC
│   │   ├── akasha-adopt.md          # one-shot existing-vault migration
│   │   └── akasha-recap.md          # period recap + biggest-win flow
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
│       ├── akasha-goal-set/
│       │   └── SKILL.md           # comprehensive goal-setting (any level)
│       ├── akasha-goal-adjust/
│       │   └── SKILL.md           # deliverable rescheduling + pattern surfacing
│       ├── akasha-material-ingest/
│       │   └── SKILL.md           # PDF → TOC extraction
│       ├── akasha-semester-setup/
│       │   └── SKILL.md           # new semester init + archive previous
│       ├── akasha-adopt/
│       │   └── SKILL.md
│       ├── akasha-search/
│       │   └── SKILL.md
│       ├── akasha-status/
│       │   └── SKILL.md
│       ├── akasha-daily/
│       │   └── SKILL.md
│       ├── akasha-capture/
│       │   └── SKILL.md
│       └── akasha-recap/
│           └── SKILL.md
├── AGENTS.md                     # bootstrap + conventions (was SessionStart)
├── bin/
│   ├── akasha-nightly.sh         # headless entrypoint
│   ├── pdf-extract.sh            # PDF TOC/text extraction helper (pdftotext + pymupdf)
│   └── prompts/
│       ├── process-inbox.md
│       ├── update-hotcache.md
│       ├── goal-adjust.md        # nightly goal adjustment prompt
│       ├── append-recap-scratch.md  # nightly recap scratch accumulation
│       └── semester-archive.md   # archive previous semester materials
├── Inbox/                        # capture drop zone
│   └── _processed/               # raw sources after ingest (immutable archive)
├── Knowledge/                    # generated atomic notes (agent-owned)
│   ├── math/                     # domain folders only — see _domains.md
│   │   ├── _moc-registry.md      # domain MOC registry (agent-maintained)
│   │   └── <MOCs + atomic notes> # flat within domain; hierarchy via MOC links
│   ├── cs/
│   │   ├── _moc-registry.md
│   │   └── ...
│   ├── quant/                    # examples; driven by _domains.md approved list
│   │   ├── _moc-registry.md
│   │   └── ...
│   ├── _domains.md               # domain registry (controlled vocabulary)
│   └── _index.md                 # master index (+ MOC list)
├── Goals/                        # goal cascade (§5.8)
│   ├── 4year/
│   │   └── vision.md             # 4-year college vision, 6 life areas
│   ├── semester/
│   │   ├── 2026-fall.md          # semester goals, material references
│   │   └── 2026-summer.md        # summer study (if applicable)
│   ├── monthly/
│   │   ├── 2026-09.md            # 3-tier: Must/Should/Nice
│   │   └── 2026-10.md
│   ├── weekly/
│   │   ├── 2026-W40.md           # ONE Thing + daily targets
│   │   └── 2026-W41.md
│   ├── _not-doing.md             # explicit drops (protects focus)
│   └── _goal-domain-map.md       # goal ↔ Knowledge domain mapping
├── StudyMaterials/               # ebook/resource management (§5.9)
│   ├── inbox/                    # drop PDFs here
│   ├── active/                   # current semester's extracted TOCs
│   ├── pdfs/                     # full PDFs for active semester (agent reference)
│   └── archive/                  # past semesters
│       └── 2025-fall/
├── Daily/                        # tonight-only plan + streak line
├── Reviews/                      # weekly / Sunday reviews
├── Recaps/                       # period recaps (weekly/monthly/semester)
│   ├── weekly/
│   │   └── 2026-W40.md
│   ├── monthly/
│   │   └── 2026-09.md
│   └── semester/
│       └── 2026-fall.md
├── Templates/                    # concept, math, source, entity, question, moc, daily, weekly
└── .akasha/
    ├── hot.md                    # hot cache (session continuity)
    ├── streak.md                 # positive floors/streak log
    ├── recap-weekly-scratch.md   # nightly raw data accumulation
    ├── recap-monthly-scratch.md  # nightly raw data (month rollups)
    └── recap-semester-scratch.md # nightly raw data (term rollups)
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

#### MOC hierarchy protocol

MOCs form a **recursive tree within each domain**, navigated via a domain-level registry file. Three levels via `moc_level` frontmatter:

- **`domain`** — the top-level domain hub (e.g. `Linear Algebra MOC` under `math/`). One per domain, root of the MOC tree.
- **`topic`** — major topic within a domain (e.g. `Vector Spaces MOC`).
- **`subtopic`** — any depth below topic (e.g. `Eigenvalues MOC`, `Norms and Inner Products MOC`). Recursive — a subtopic can nest another subtopic indefinitely.

Each MOC has one structural parent (enforced by frontmatter + registry), except domain-level MOCs which have none. **Notes are not constrained by the MOC tree** — a note can be listed in any number of MOCs, cross-domain, with free `[[wikilinks]]` between all notes. The MOC tree is a navigation overlay on a wiki graph, not a replacement for it.

**Registry file** (`Knowledge/<domain>/_moc-registry.md`): a derived index maintained by `akasha-ingest` and `akasha-lint`. The MOC frontmatter is the source of truth; the registry is a fast-lookup cache.

```markdown
# math — MOC Registry

| MOC | Level | Parent | Notes |
|-----|-------|--------|-------|
| [[Linear Algebra MOC]] | domain | — | 15 |
| [[Calculus MOC]] | domain | — | 8 |
| [[Vector Spaces MOC]] | topic | [[Linear Algebra MOC]] | 7 |
| [[Eigenvalues MOC]] | subtopic | [[Vector Spaces MOC]] | 4 |
```

**Split/merge heuristics** (enforced by `akasha-lint`):
- **Split signal**: a MOC with 15+ direct notes → agent proposes splitting into subtopic MOCs during ingest or lint. Never auto-splits; always proposes to the user.
- **Merge signal**: a MOC with fewer than 3 notes → flagged as a merge candidate in lint reports.
- **Depth warning**: MOC chains deeper than 4 levels → gentle nudge in lint (not an error).

**Note placement protocol** (in `akasha-ingest`):
1. Read the domain's `_moc-registry.md`.
2. Walk the tree from domain-level MOC → deepest matching MOC for the note's content.
3. List the note under the best MOC heading. If no MOC fits, list under the domain-level MOC directly.
4. **Cross-list** if the note is relevant to MOCs in other domains — add it there too. The note's file stays in its primary domain; only the MOC link is cross-domain.
5. Update the registry's `Notes` count for MOC(s) touched.
6. Check threshold — if a MOC hits 15 notes, propose splitting.

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

MOC notes add two additional frontmatter fields (§5.0):

```yaml
moc_level: domain | topic | subtopic   # position in the MOC hierarchy
parent: "[[Parent MOC]]"               # empty for domain-level MOCs
```

A note's physical location is its **domain** folder under `Knowledge/`; its **type** lives in frontmatter — there are no `concepts/` or `entities/` subdirectories. `math` adds nothing structural — it just signals "body is LaTeX-heavy, transcribed from a photo source." Keep the body sections minimal (Definition / Why it matters / Connections) to avoid empty-section lint noise. `moc` notes live in their primary domain folder; all MOCs are listed in `_index.md` and tracked in their domain's `_moc-registry.md`. `moc` is a curated hub (§5.0): its body is a hand-ordered, annotated link list, exempt from empty-section lint.

The `daily` and `weekly` templates are **accountability** templates, separate from the six knowledge note types above — they live in `Templates/` alongside the knowledge set but apply only to `Daily/` and `Reviews/`.

### 5.2 `akasha-ingest` (the core agent)

Ported from autonote `wiki-ingest`, simplified (no locking, no address allocator, no mode router). One source in → atomic notes out.

```markdown
---
name: akasha-ingest
description: Process one Inbox item — text note or photo of math. Read it, (transcribe to LaTeX if an image), route into an existing domain from _domains.md (propose new ones, never auto-create), navigate the MOC registry to place the note in the deepest matching MOC, cross-list across domains if relevant, extract concepts/entities, create or update atomic notes under Knowledge/, cross-link, update _index.md, then move the raw source to Inbox/_processed/. Delegate one agent per Inbox item.
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
5. Navigate the MOC hierarchy for the note's domain:
   a. Read Knowledge/<domain>/_moc-registry.md.
   b. Walk the tree from the domain-level MOC to find the deepest matching
      MOC for the note's content.
   c. List the note under the best MOC heading in that MOC's body. If no
      MOC fits, list under the domain-level MOC directly.
   d. If the note is also relevant to MOCs in OTHER domains, cross-list it
      there (add under the MOC heading). The note file stays in its primary
      domain; only the MOC link crosses domains.
   e. Update the Notes count in _moc-registry.md for each MOC touched.
   f. If any MOC's count reaches 15, include a split proposal in the report
      (suggest 2–3 subtopic MOC names + which notes would move). Do NOT
      auto-create the new MOCs.
6. Cross-link with [[wikilinks]] to existing related notes.
7. Update Knowledge/_index.md.
8. If a claim contradicts an existing note, add a "> [!contradiction]" callout.
9. Move the raw source to Inbox/_processed/ (do NOT edit it in place).
10. Report: Created / Updated / Source-archived / Proposed-domain (if any) /
    MOC-placements / Cross-listings / Split-proposals (if any) /
    one-line key insight.

Never: create a new domain folder unprompted, edit anything under
Inbox/_processed/, delete a raw capture, duplicate a note already in
_index.md, or create a new MOC without proposing it first.
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
git add -- Knowledge/ Inbox/ Daily/ Reviews/ Recaps/ Goals/ StudyMaterials/ .akasha/ 2>/dev/null || true
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
- `akasha-weekly` agent — the 15-min Sunday review, five fixed questions. Now includes goal progress table and Start/Stop/Continue from the cascade.
- `akasha-goal-align` agent — audits recent dailies against active goals across all levels. Checks goal ↔ domain mapping for academic goals. Reports drift with specific daily entries as evidence. Read-only.
- `akasha-goal-tracker` agent — progress calculation, staleness detection, deliverable auto-adjustment. Runs during `/akasha-nightly` and on-demand via `/akasha-goal-adjust`.

### 5.6 `akasha-adopt` (one-shot existing-vault migration)

Ported from PKM's `/adopt`. A **one-time, non-destructive** agent that folds an existing vault into Akasha so the old vault isn't left behind. The existing vault already uses a proto-hierarchy: `4 - Indexes/` (7 empty domain files) and `3 - Tags/` (32 hub notes, mostly stubs) form a two-layer structure that maps to Akasha's MOC hierarchy.

#### Existing vault structure → Akasha mapping

The existing vault has three layers that map to Akasha:

| Existing layer | Example | → Akasha |
|---|---|---|
| `4 - Indexes/` (7 empty files) | `Computer Science.md`, `Math.md` | Domain-level MOCs (`moc_level: domain`) |
| `3 - Tags/` (32 files, mostly stubs) | `Machine Learning.md`, `Statistics.md` | Topic or subtopic MOCs (`moc_level: topic | subtopic`) |
| `1- Rough Notes/` (76 files) | `K Nearest Neighbors Basics.md` | Atomic notes (processed through ingest) |
| `2- Source Material/` (9 files) | `Mastery by Robert Greene.md` | Source notes (`type: source`) |

The tags are flat (no hierarchy), but many are clearly nested — e.g. `Natural Language Processing` is a subtopic of `Machine Learning`; `pandas`, `numpy`, `matplotlib` are subtopics of `Python` or `Data Science`. The agent infers this hierarchy from link patterns: which tags are referenced together, which notes reference multiple tags, and which tags have child-like relationships.

#### Migration protocol — 5 steps

```markdown
---
name: akasha-adopt
description: One-time migration of an existing Obsidian vault into Akasha structure. Scans folders, infers MOC hierarchy from tag/note link patterns, proposes a domain→topic→subtopic mapping, and on confirmation moves/registers content non-destructively. Seeds _moc-registry.md for each domain. Run once, manually.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
You migrate an existing vault into Akasha. NON-DESTRUCTIVE and INCREMENTAL.

Process:
1. SCAN the source vault: folders, note count, frontmatter presence, link
   density. Map 4 - Indexes/ files to domain folders:
   - Computer Science.md → cs/
   - Math.md → math/
   - Programming.md → cs/ (merged — programming is a domain of CS)
   - Finance.md → quant/ (or finance/)
   - Humanities.md → humanities/
   - People.md → entities/ (or people/)
   - Organization.md → skip (PARA-like; action tracking lives in Daily/Reviews)
   Seed Knowledge/_domains.md from this mapping.

2. INFER TAG HIERARCHY. For each of the 32 tags in 3 - Tags/:
   a. Read which rough notes reference it (from [[tag]] links).
   b. Check if the tag is referenced by other tags (child-like relationship).
   c. Check which domain it maps to (from step 1).
   d. Propose moc_level: domain | topic | subtopic and parent MOC.
   Example inference:
   - Machine Learning → topic (referenced by many notes, children: NLP, scikitlearn)
   - Natural Language Processing → subtopic (parent: Machine Learning)
   - pandas → subtopic (parent: Python or Data Science)
   - Algorithms and Complexity → topic (cross-references Data Structures and Algorithms)
   PRODUCE A HIERARCHY PROPOSAL TABLE and STOP for confirmation. Change nothing yet.

   Proposal table format:
   | Tag | → MOC Name | moc_level | Parent | Domain | Notes that reference it |
   |-----|-----------|-----------|--------|--------|------------------------|
   | Machine Learning | Machine Learning MOC | topic | (domain root) | cs | KNN Basics, Deep Learning notes, ... |
   | NLP | Natural Language Processing MOC | subtopic | Machine Learning MOC | cs | ... |

3. On approval, create MOCs in small git-committed steps:
   a. Convert each tag to a MOC note with moc_level, parent, domain frontmatter.
   b. Place in the correct Knowledge/<domain>/ folder.
   c. Populate the MOC body with links to notes that reference it.
   d. Create _moc-registry.md for each domain with the full hierarchy.
   e. For tags that cross-reference each other (e.g. Algorithms ↔ Data Structures),
      link them in the MOC body as related MOCs.

4. MIGRATE NOTES. For each rough note:
   a. Determine primary domain from the MOCs it links to.
   b. Backfill frontmatter (type, status: seed, domain, created, tags).
   c. Place in primary domain folder.
   d. List under the deepest matching MOC (cross-list if relevant to other domains).
   e. Preserve all [[wikilinks]] as-is.
   f. Leave already-atomic notes in place; backfill MISSING frontmatter only.

5. MIGRATE SOURCE MATERIAL. 2- Source Material/ files → type: source notes in
   their domain, backfilled with frontmatter.

6. MERGE TEMPLATES. 5 - Templates/ → Templates/ (merge; keep Metalearning,
   People, etc. — never overwrite existing Akasha templates).

7. Report: domains created, MOCs created (per level), notes migrated per domain,
   cross-listings, any notes needing manual review, any tags with ambiguous
   hierarchy placement.

Never: rewrite the body of an existing atomic note, overwrite a template,
proceed past step 2 without explicit confirmation, or create MOCs without
showing the hierarchy proposal first.
```

Default mapping for the current vault:

| Existing folder      | → Akasha target                                           |
| -------------------- | --------------------------------------------------------- |
| `1- Rough Notes`     | `Inbox/` (re-ingest) → atomic notes in domain folders     |
| `2- Source Material` | `Knowledge/` (`type: source`)                             |
| `3 - Tags`           | MOCs with `moc_level: topic | subtopic` (hierarchy inferred) |
| `3 - Tags/4 - Indexes` | MOCs with `moc_level: domain` (one per domain)          |
| `5 - Templates`      | `Templates/` (merge; keep `Metalearning`, `People`, etc.) |

### 5.7 Skill catalog

All user-facing operations are invoked as slash commands. Skills either wrap an existing agent or compose multiple agents/scripts into a single workflow. No shell commands required.

#### `/akasha-nightly` — run the ingest pipeline + goal adjustment

Wraps the headless `cmd` calls from §6.2. Delegates to `akasha-ingest` for each Inbox item, then runs goal adjustment, then updates the hot cache.

- **When:** End of day, anchored to the nightly planning ritual.
- **Input:** None — reads everything in `Inbox/` (excluding `_processed/`), plus current week's deliverables.
- **Output:** Summary — items processed, notes created/updated, domains touched, any proposed domains. MOC placements, cross-domain listings, and split proposals for any MOCs hitting 15+ notes. Plus goal adjustment summary: deliverables rescheduled, patterns flagged, staleness warnings. Errors surfaced immediately with log tails.
- **Edge cases:** Empty Inbox → "Nothing to process." Already-processed items → skipped (idempotent). Agent error → surfaces which item failed and why, continues with remaining items. No active goals → skips goal adjustment silently.

#### `/akasha-lint` — vault hygiene check

Runs the `akasha-lint` agent for read-only health checks.

- **When:** Sunday review, or anytime you want a health check.
- **Input:** None — scans entire `Knowledge/` and `Daily/`.
- **Output:** Report grouped by issue type: orphaned notes (no incoming links), broken `[[wikilinks]]`, missing frontmatter fields, empty body sections, `seed` notes older than 30 days. Each issue includes file path and line number. **MOC hierarchy checks** (reads each domain's `_moc-registry.md`): orphaned MOCs (not listed in any parent MOC or registry), registry drift (MOCs in frontmatter but not in registry, or vice versa), overfull MOCs (15+ direct notes — split candidate), underfull MOCs (fewer than 3 notes — merge candidate), depth warnings (MOC chains deeper than 4 levels).
- **Behavior:** Report-only, never auto-fixes. After reading the report, you can ask the agent to fix specific issues in a follow-up message.
- **Edge cases:** Clean vault → "No issues found." Many issues → capped at 50 per type, with a count of remaining.

#### `/akasha-review` — weekly Sunday review

Runs the `akasha-weekly` agent to produce a structured weekly review with goal cascade integration.

- **When:** Sunday (or whenever you want to do a weekly review). Part of the weekly planning ritual.
- **Input:** Reads the week's `Daily/*.md` files, `.akasha/streak.md`, current weekly deliverables, and monthly goals.
- **Output:** Creates `Reviews/YYYY-WXX.md` from the weekly template. The agent reads your week and prompts you with five fixed questions (from the PKM accountability cascade). You answer interactively; the agent fills in the review note. Includes a **goal progress table** showing deliverable completion rates and a **Start/Stop/Continue** section for rebalancing.
- **Behavior:** Carries over any unfinished top-3 items from the week's dailies. Highlights streak breaks. Flags if any daily notes are missing (gaps in the week). Rolls up goal deliverable status. Detects patterns across weeks (consistently avoided work, energy trends).
- **Edge cases:** No dailies this week → prompts you to reflect on why, no judgment. Review already exists → appends to it rather than overwriting. No active goals → skips goal progress table.

#### `/akasha-goal-check` — goal alignment audit

Runs the `akasha-goal-align` agent to check progress against stated goals.

- **When:** Weekly or biweekly, during review or standalone.
- **Input:** Reads recent `Daily/*.md` (last 7–14 days), `Reviews/*.md`, and the goal cascade (`Goals/4year/`, `Goals/semester/`, `Goals/monthly/`).
- **Output:** Read-only report — which goals are on track, which are drifting, with specific daily entries as evidence. Suggests adjustments but takes no action.
- **Behavior:** Informational only. No side effects, no file writes. Designed to be fast and non-intrusive.
- **Edge cases:** No recent dailies → reports insufficient data. No goals defined → prompts you to set some.

#### `/akasha-adopt` — migrate existing vault

Runs the `akasha-adopt` agent for one-time migration of an existing Obsidian vault.

- **When:** Once, when setting up Akasha with an existing vault.
- **Input:** Scans the current vault structure — folders, note count, frontmatter presence, link density. Reads `3 - Tags/` and `4 - Indexes/` to infer the existing hierarchy.
- **Output:** Multi-step interactive process. First produces a folder→target mapping report. Then infers a tag hierarchy from link patterns and produces a proposal table (tag → MOC name, `moc_level`, `parent`, `domain`, referencing notes) and stops for explicit confirmation. On approval, executes migration in small git-committed steps: creates MOCs with hierarchy, seeds `_moc-registry.md` per domain, migrates notes into domain folders with frontmatter backfill.
- **Behavior:** Non-destructive. Leaves atomic note bodies untouched, only backfills missing frontmatter. Never overwrites templates. Each step is a separate git commit for reversibility. The hierarchy proposal is the critical gate — nothing moves until the user confirms the MOC structure.
- **Edge cases:** Already adopted → detects existing Akasha structure and warns. Partial migration → can resume from where it left off (checks what's already been moved). Tags with ambiguous hierarchy → agent flags them in the proposal with a "needs review" marker.

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

#### `/akasha-daily` — create today's daily note (goal-grounded)

Scaffolds today's daily note from the template, grounded in the goal cascade.

- **When:** Start of day, or when you want to plan. Part of the daily planning ritual.
- **Input:** None — uses today's date. Reads goal cascade (weekly deliverables → monthly goals → semester goal) and `.akasha/hot.md`.
- **Output:** Creates `Daily/YYYY-MM-DD.md` from the daily template. Pre-populates:
  - **Cascade context block** — surfaces the week's ONE Thing, monthly Must/Should priorities, and any material chapters in progress
  - **Suggestions for today** — 1–3 items derived from weekly deliverables (what's due, what was unfinished yesterday, what hasn't been touched in a while). These are prompts, not assignments.
  - Carries over unfinished top-3 items from yesterday's daily (items without checkmarks)
  - Reads `.akasha/hot.md` for recent context
  - Leaves energy tag and new top-3 for you to fill in
- **Behavior:** Idempotent — if today's daily already exists, opens it instead of creating a duplicate. Never overwrites existing content. Suggestions are informational — you choose what to adopt.
- **Edge cases:** No yesterday daily → creates fresh with empty top-3. Yesterday had no unfinished items → empty carry-over section. No active goals → shows cascade context as "No active goals" and skips suggestions.

#### `/akasha-capture "text"` — quick capture to inbox

Appends a quick typed note to the Inbox without opening Obsidian.

- **When:** Anytime you have a fleeting thought, code snippet, or concept you want to capture from the terminal.
- **Input:** Text content (e.g., `/akasha-capture "Zettelkasten: atomic notes, one idea each, linked by wikilinks"`).
- **Output:** Creates a new file in `Inbox/` with a timestamp-based filename (e.g., `2025-01-15T14-30-00.md`) containing the text. Minimal frontmatter (date, status: seed).
- **Behavior:** Quick, one-shot, no interaction needed. This is the cmdc-native capture rail — complements the photo sync rail (math/photos) and direct Obsidian typing (code/concepts).
- **Edge cases:** Multi-line text → handled gracefully, preserves formatting. Empty input → prompts for content. This rail is text-only; images still go through the photo sync path.

#### `/akasha-goal-set <level> [file]` — comprehensive goal-setting

Interactive goal creation at any level of the cascade. Supports both file ingestion and CLI brainstorming.

- **When:** Setting up a new 4-year vision, starting a semester, planning a month, or planning a week. Also when ingesting a goal document from a file.
- **Input:** Level (`4year`, `semester`, `monthly`, `weekly`) and optionally a file path (markdown or PDF).
- **Output:** Creates or updates the appropriate goal file in `Goals/`. For file ingestion: parses the file into the universal YAML structure. For CLI brainstorming: comprehensive interactive conversation that walks through each section.
- **Behavior:** Always reads cascade context first (surfaces what already exists). For semester level and above, produces a proposal and stops for confirmation before writing. For file ingestion, asks "Adopt wholly or adjust?" — if adjust, runs a guided conversation to modify the file's content before structuring it.
- **Edge cases:** Goal already exists at that level → offers to update rather than overwrite. PDF file → calls `bin/pdf-extract.sh` for text extraction, then parses content. No cascade context (first time) → creates from scratch with guided prompts.

#### `/akasha-goal-adjust` — deliverable rescheduling + pattern surfacing

Runs the `akasha-goal-tracker` agent to adjust slipped deliverables and surface patterns.

- **When:** After `/akasha-nightly` (automatically), or on-demand when you want to rebalance.
- **Input:** Current week's deliverables, today's daily note.
- **Output:** Adjustment summary — which deliverables were rescheduled, which were flagged (3+ slips), staleness warnings, Start/Stop/Continue if >50% slipped. Updates weekly goal file with new due dates.
- **Behavior:** Auto-reschedules forward. Never marks as "failed." Surfaces patterns gently. If structural changes are needed (dropping a goal, changing semester scope), stops for confirmation.
- **Edge cases:** No active weekly goal → "No weekly deliverables to adjust." All deliverables done → "All clear."

#### `/akasha-material-ingest` — PDF → structured TOC

Extracts table of contents from a PDF ebook and creates a structured material note.

- **When:** When adding a new study material for the semester. Drop the PDF in `StudyMaterials/inbox/` first.
- **Input:** PDF filename (or scans `inbox/` if not specified).
- **Output:** Creates `StudyMaterials/active/<material-name>.md` with extracted TOC, per-chapter page counts, and difficulty estimates. Moves PDF to `StudyMaterials/pdfs/`.
- **Behavior:** Uses `bin/pdf-extract.sh` for TOC extraction. Presents structured TOC to user for confirmation/adjustment before writing. Difficulty is estimated (page count + content complexity) and user-confirmed.
- **Edge cases:** PDF has no built-in TOC → falls back to text extraction + agent-based chapter identification. PDF already ingested → warns and offers to update existing material file.

#### `/akasha-semester-setup` — new semester initialization

Archives previous semester materials and sets up a new term.

- **When:** Start of a new semester or summer term.
- **Input:** Term name (e.g., `2027-spring`).
- **Output:** Archives `StudyMaterials/active/` + `pdfs/` to `archive/<previous-term>/`, clears active directories, creates new semester goal file (`Goals/semester/<term>.md`), prompts for materials.
- **Behavior:** Multi-step interactive process. First archives (non-destructive — files move, not delete). Then reads 4-year vision and last semester's goal to propose the new semester's focus. Asks about course load, commitments, materials. If PDFs are already in `inbox/`, offers to run `/akasha-material-ingest` for each.
- **Edge cases:** No previous semester → skips archive step. Previous semester not completed → warns about unfinished goals, asks which to carry forward vs. drop.

#### `/akasha-recap <weekly|monthly|semester>` — period snapshot

Produces a factual, backward-looking recap at the requested cadence with interactive biggest-win selection.

- **When:** Sunday (weekly), month end (monthly), or as part of semester transition (semester). Also on-demand.
- **Input:** Level (`weekly`, `monthly`, or `semester`).
- **Output:** Creates `Recaps/<level>/<period>.md` with deliverable stats, streak data, knowledge growth, material progress, study load, biggest win, and upcoming deliverables. Proposes 3 auto-generated "biggest win" candidates from the period's data — user picks one or writes their own. Resets the corresponding scratch file in `.akasha/` for the new period.
- **Behavior:** Reads the accumulated scratch file + cross-references `Daily/`, `Goals/`, `Knowledge/`, `StudyMaterials/`, and `.akasha/streak.md` for a complete picture. Writes nothing until the user confirms the biggest win. Read-only except for the final recap file and scratch reset.
- **Edge cases:** No scratch data → produces a minimal recap from cross-referenced source data alone. Recap already exists → warns and offers to append. No active goals → skips goal sections, produces knowledge-only recap. Weekend day not Sunday → produces the recap for the most recently completed week.

### 5.8 Goal cascade (ported from PKM, adapted for college lifecycle)

A **4-level goal cascade** grounded in the 4-year college timeline. Each level is a Markdown file with YAML frontmatter, connected by `[[wikilinks]]` up the cascade. Six life areas: **academic**, **career**, **health**, **relationships**, **soul**, **financial**. Academic goals map to Knowledge domains via `_goal-domain-map.md`.

```
4-year vision (Goals/4year/vision.md)
  ↓ decomposed into
Semester goal (Goals/semester/<term>.md) ← references StudyMaterials/active/
  ↓ decomposed into
Monthly goals (Goals/monthly/YYYY-MM.md) — 3-tier: Must/Should/Nice
  ↓ decomposed into
Weekly deliverables (Goals/weekly/YYYY-WXX.md) — ONE Thing + daily targets
  ↓ surfaces into
Daily (/akasha-daily suggestions + /akasha-nightly adjustment)
```

#### Goal data model (universal across all levels)

```yaml
---
type: goal
level: 4year | semester | monthly | weekly
area: academic | career | health | relationships | soul | financial
status: active | paused | completed | dropped
term: "2026-fall"              # semester-level and below
deadline: YYYY-MM-DD           # hard deadlines (exams, certs) — optional
supports: [[parent goal]]      # wikilink up the cascade
domain: math | cs | quant      # academic goals only — maps to Knowledge/
material: [[material-file]]    # optional — links to StudyMaterials/active/
progress: 0-100                # auto-calculated from deliverables
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

## Deliverables (system-managed)
<!-- YAML-driven, agent-managed. Statuses: pending, done, slipped, rescheduled -->
- [ ] Finish chapters 1–3 of Strang — due: 2026-09-15
- [ ] Problem sets 1–4 — due: 2026-09-22

## Notes (manual)
<!-- Checkbox-based sub-tasks you add yourself. Agents don't touch these. -->
- [ ] Review lecture notes from Tuesday
```

**Hybrid tracking:** YAML frontmatter + deliverables section is system-managed (agents parse, adjust, reschedule). The `## Notes` section is human-only — manual checkboxes for sub-tasks. Agents never modify manual notes.

#### Level-specific structures

**4-year vision** (`Goals/4year/vision.md`): One file. Life-area vision statements, year-by-year milestones (Year 1–4), quarterly reflection questions. Reviewed once per semester. No deliverables — this is directional, not actionable.

**Semester goal** (`Goals/semester/<term>.md`): One file per term (e.g., `2026-fall.md`, `2026-summer.md`). Course load, study commitments, material references (`material: [[strang-linear-algebra]]`), monthly breakdown. Summer terms are first-class — same structure, lighter load.

**Monthly goal** (`Goals/monthly/YYYY-MM.md`): 3-tier priority system:
- **Must Complete** — non-negotiable, deadline-driven (exams, assignment due dates)
- **Should Complete** — important but flexible (chapter completion, problem sets)
- **Nice to Complete** — stretch goals (extra reading, side projects)

Each item has a `due` date and `status`. Weekly milestones within the month.

**Weekly deliverables** (`Goals/weekly/YYYY-WXX.md`): ONE Thing (the single most important deliverable), daily targets derived from monthly goals. This is where auto-adjustment lives — slipped items get rescheduled forward.

#### Goal ↔ domain mapping

`Goals/_goal-domain-map.md` maps academic goals to Knowledge domains:

```markdown
| Goal | Domain | Subarea |
|------|--------|---------|
| Linear Algebra (Strang) | math | linear-algebra |
| AWS AI Practitioner | cs | cloud/ai |
| Probability Theory | quant | probability |
```

This creates a bridge: the goal system says *what to study*, the Knowledge system captures *what you've learned*. When reviewing a goal, the agent can check how many Knowledge notes exist in the linked domain to gauge actual learning progress.

#### Adjustment rules

- **Slipped deliverables** → rescheduled to tomorrow or next available slot. Status changes from `pending` to `slipped`, then `rescheduled` with new `due` date.
- **3+ slips on same deliverable** → flagged as "needs rescheduling." Agent suggests moving to a different week or lowering priority tier. Requires explicit confirmation.
- **Weekly deliverables >50% slipped** → agent surfaces Start/Stop/Continue prompt during nightly. No automatic structural changes.
- **14-day staleness** → goals untouched for 14+ days get a gentle nudge: "This goal hasn't had activity in 2 weeks. Still relevant?"
- **Never marked "failed"** — only `pending`, `done`, `slipped`, `rescheduled`. Dropped goals get `status: dropped` with an explicit note in `_not-doing.md`.

#### Cascade context surfacing

Before any goal-setting or daily interaction, the agent reads *up* the cascade and displays context:

```markdown
### Cascade Context
- **4-year vision:** [area summary from vision.md]
- **This semester:** [active semester goal, materials in use]
- **This month:** [Must/Should/Nice priorities]
- **This week:** [ONE Thing + deliverable count]
```

This ensures every decision is grounded in long-term intent.

### 5.9 Study materials system

Manages ebook PDFs and their extracted structure. Materials are semester-scoped — active during a term, archived when a new semester starts.

#### Directory structure

```
StudyMaterials/
├── inbox/              # drop PDFs here (raw intake)
├── active/             # extracted TOC + metadata files (current semester)
├── pdfs/               # full PDFs for active semester (agent reference)
└── archive/            # past semesters
    └── 2025-fall/
```

#### Material data model (`StudyMaterials/active/*.md`)

```yaml
---
type: material
title: "Linear Algebra and Its Applications"
author: "Gilbert Strang"
source: strang-linear-algebra.pdf    # filename in pdfs/
term: "2026-fall"
status: active | completed | archived
chapters_total: 12
chapters_covered: 0
difficulty_estimate: medium          # overall: easy | medium | hard
---

## Table of Contents

| # | Title | Pages | Difficulty | Status |
|---|-------|-------|-----------|--------|
| 1 | Introduction to Vectors | 1–22 (22p) | easy | not started |
| 2 | Solving Linear Equations | 23–58 (36p) | medium | not started |
| 3 | Vector Spaces and Subspaces | 59–94 (36p) | hard | not started |
| ... | ... | ... | ... | ... |

## Notes
<!-- Agent or user notes about pacing, difficulty adjustments, etc. -->
```

#### Difficulty estimation

The `akasha-material-parser` agent estimates per-chapter difficulty using two signals:

1. **Page count** — longer chapters need more time (primary signal)
2. **Content complexity** — chapters dense with theorems/proofs or new notation are harder than review/application chapters

The agent proposes difficulty; the user confirms or adjusts during ingestion. Difficulty drives pacing — hard chapters get more weekly deliverable slots. Pacing adjusts automatically when the user falls behind (§5.8 adjustment rules).

#### Semester lifecycle

**Active semester:** PDFs in `StudyMaterials/pdfs/`, TOCs in `StudyMaterials/active/`. Semester goal files reference materials via `material: [[material-file]]` frontmatter.

**Semester transition** (`/akasha-semester-setup`):
1. Archive current `active/` + `pdfs/` → `archive/<previous-term>/`
2. Clear `active/` and `pdfs/` for new term
3. Prompt for new materials (PDFs already in `inbox/` or to be added)
4. Extract TOCs for new materials
5. Create new semester goal file with material references

### 5.10 PDF parsing helper

Because open-source models cannot read PDFs natively, a shell helper extracts text and TOC structure from ebook PDFs.

**Dependencies:** `pdftotext` (from `poppler-utils`) for text extraction, `python3` + `pymupdf` (`pip install pymupdf`) for TOC/bookmark extraction.

**`bin/pdf-extract.sh`** — two modes:

```bash
# Extract TOC (bookmarks/outline) → JSON
./bin/pdf-extract.sh toc input.pdf
# Output: [{"level": 1, "title": "Chapter 1: Vectors", "page": 1}, ...]

# Extract full text (for agent reading)
./bin/pdf-extract.sh text input.pdf
# Output: plain text to stdout, layout-preserved
```

**TOC extraction priority:**
1. Try PDF built-in bookmarks/outline (fastest, most reliable)
2. If no bookmarks, fall back to text extraction + agent-based TOC parsing (reads first few pages of each chapter to identify structure)

The `akasha-material-parser` agent calls this helper, then structures the output into the material data model (§5.9). If the PDF has no built-in TOC, the agent reads the extracted text and identifies chapter boundaries from headings, page numbering patterns, and content shifts.

### 5.11 Goal-related agents

#### `akasha-goal-setter` — interactive goal creation

```markdown
---
name: akasha-goal-setter
description: Create or modify goals at any level (4-year, semester, monthly, weekly). Reads cascade context, asks level-appropriate questions, decomposes higher-level goals into deliverables. Supports both file ingestion and CLI brainstorming.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
You help set goals at any level of the 4-year → semester → monthly → weekly cascade.

Process (adapts based on level):

FOR 4-YEAR VISION:
1. Read existing vision (if any). Ask about each life area: academic, career,
   health, relationships, soul, financial.
2. For academic: "What are you studying? What's the end goal? What skills do
   you want by graduation?"
3. Produce vision.md with year-by-year milestones.

FOR SEMESTER:
1. Read 4-year vision. Read last semester's goal (if any).
2. Ask: "What courses/commitments this term? Any self-study? What materials
   will you use?"
3. If materials exist in StudyMaterials/active/, reference their TOCs.
4. Propose semester goal with monthly breakdown. STOP for confirmation.
5. On approval, create Goals/semester/<term>.md with material references.

FOR MONTHLY:
1. Read semester goal. Read study material TOCs for pacing context.
2. Identify what's due this month (exams, assignments, deadlines).
3. Propose Must/Should/Nice deliverables with due dates.
4. Create Goals/monthly/YYYY-MM.md.

FOR WEEKLY:
1. Read monthly goal. Read last week's deliverables + completion status.
2. Identify the ONE Thing for this week.
3. Derive daily targets from monthly Must/Should items.
4. Auto-adjust: carry forward any slipped items from last week.
5. Create Goals/weekly/YYYY-WXX.md.

FILE INGESTION MODE:
1. Read the provided file (markdown or PDF).
2. Ask: "Adopt wholly or adjust?"
3. If adopt: parse into universal YAML structure, place in correct Goals/
   subdirectory.
4. If adjust: guided conversation — agent asks which parts to keep/modify/drop,
   proposes changes, gets confirmation.

CLI BRAINSTORMING MODE:
Full interactive conversation. Reads cascade context first, then walks through
each section of the goal file. Comprehensive — covers all fields, suggests
deliverables, estimates pacing from materials, asks probing questions about
commitments and capacity.

Never: create goals without reading cascade context first, auto-create domain
folders, or skip confirmation for semester-level and above.
```

#### `akasha-goal-tracker` — progress and adjustment

```markdown
---
name: akasha-goal-tracker
description: Track goal progress, detect staleness, adjust slipped deliverables, and surface patterns. Runs during nightly and on-demand.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
You track goal progress and handle deliverable adjustment.

Process:
1. Read current week's deliverables (Goals/weekly/).
2. Read today's daily note (Daily/) for completed items.
3. For each deliverable:
   - If done → mark with status: done
   - If missed and first time → reschedule to tomorrow, status: rescheduled
   - If missed 3+ times → flag: "needs rescheduling" — suggest different week
     or lower priority tier
4. Update weekly progress percentage.
5. Check 14-day staleness across all active goals.
6. If >50% weekly deliverables slipped → surface Start/Stop/Continue:
   - Start: what to add (under-served goals)
   - Stop: what to drop (misaligned activity)
   - Continue: what's working
7. Check goal-domain mapping: for academic goals, count Knowledge notes in
   linked domain to gauge actual learning progress.

Output: adjustment summary (rescheduled count, flagged items, staleness
warnings, alignment notes). Written to .akasha/hot.md for session continuity.

Never: mark deliverables as "failed", delete dropped goals without moving them
to _not-doing.md, or make structural changes to semester goals without
explicit confirmation.
```

#### `akasha-material-parser` — PDF → structured TOC

```markdown
---
name: akasha-material-parser
description: Extract table of contents from a PDF ebook, estimate per-chapter difficulty, and create a structured material note in StudyMaterials/active/. Also moves the PDF to StudyMaterials/pdfs/.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
You extract structure from ebook PDFs for semester goal planning.

Process:
1. Run bin/pdf-extract.sh toc <pdf> to get bookmarks/outline.
2. If TOC exists: structure into the material data model with page counts and
   per-chapter difficulty estimates.
3. If no TOC: run bin/pdf-extract.sh text <pdf>, read the extracted text,
   identify chapter boundaries from headings and content structure.
4. Estimate per-chapter difficulty:
   - Page count: >40 pages = harder, <20 pages = easier
   - Content signals: heavy theorem/proof density = hard, review/application =
     easier
5. Present the structured TOC to the user for confirmation/adjustment.
6. On approval: create StudyMaterials/active/<material-name>.md
7. Move the PDF from StudyMaterials/inbox/ to StudyMaterials/pdfs/.
8. Report: title, author, chapter count, difficulty distribution, total pages.

Never: overwrite an existing material file, skip the confirmation step, or
estimate difficulty without showing the basis for the estimate.
```

### 5.12 Period recaps (weekly / monthly / semester)

Automated, factual backward-looking snapshots at three cadences. Distinct from the weekly review (§5.5, §5.7 `/akasha-review`) which is a reflective 5-question ritual — the recap answers "what actually happened" before the review asks "how did it feel." Hybrid trigger: nightly silently appends raw data to scratch files; the user explicitly invokes `/akasha-recap <level>` to produce a formatted recap with an interactive "biggest win" flow.

#### What's in each level

**Weekly recap** (`Recaps/weekly/YYYY-WXX.md`):
- **Deliverable stats** — X/Y completed, rescheduled, slipped; any patterns
- **Streak** — floors held (study/move/consume), any breaks this week
- **Knowledge** — notes created this week, domains touched, top MOC growth (notes added to each MOC)
- **Inbox** — items processed this week
- **Materials** — chapters started and completed this week
- **Study load** — energy tag distribution from dailies (high/medium/low counts), approximate study hours from schedule adherence
- **Biggest win** — single highlight, user-picked from 3 agent-proposed candidates or user-written
- **What's upcoming** — next week's ONE Thing + key deliverables from the goal cascade

**Monthly recap** (`Recaps/monthly/YYYY-MM.md`): aggregates 4-5 weeklies plus:
- Must/Should/Nice completion rates from the monthly goal
- Staleness warnings surfaced during the month
- Domain growth trend (note count delta per domain)
- Semester-progress gauge (% of semester chapters covered across all materials)

**Semester recap** (`Recaps/semester/<term>.md`): aggregates monthlies plus:
- Full material coverage (chapters done / total per material)
- Total Knowledge notes created, evergreen count, stale seed notes
- Domain growth summary across the term (full note count per domain from `_domains.md`)
- Goal cascade retrospect — how the 4-year vision translated to this semester's execution
- Carried-forward items for the next term (from `_not-doing.md` or unflagged incomplete deliverables)

#### Directory & scratch files

```
Recaps/
├── weekly/
│   └── 2026-W40.md
├── monthly/
│   └── 2026-09.md
└── semester/
    └── 2026-fall.md

.akasha/
├── recap-weekly-scratch.md       # nightly appends raw data
├── recap-monthly-scratch.md      # nightly appends (month rollups)
└── recap-semester-scratch.md     # nightly appends (term rollups)
```

#### Scratch file format (three files, same structure)

```markdown
# Weekly Recap Scratch (2026-W40)
<!-- Nightly appends. Raw data, no formatting. Read by akasha-recap agent. -->

## 2026-09-28
- streak: study=yes, move=yes, consume=yes
- deliverables done: "Finish chapter 3 Strang"
- notes created: 2
- inbox processed: 1
- energy: high

## 2026-09-29
...
```

The agent reads this accumulated scratch file during `/akasha-recap`, cross-references it with `Daily/`, `Goals/`, `Knowledge/`, `StudyMaterials/active/`, `.akasha/streak.md`, and `_moc-registry.md` files to produce the formatted recap. The scratch file resets after a successful recap run (the agent writes an empty scratch file for the new period).

#### Hybrid trigger

**Nightly appends** (`/akasha-nightly`, as a 4th headless step after goal-adjust): append 2-3 lines to `.akasha/recap-weekly-scratch.md` — today's streak status, deliverable completions, notes created count. No formatting, no user-facing output. The monthly and semester scratch files are updated on period boundaries only (month-end / term-end), not nightly.

**Manual invocation** — `/akasha-recap weekly|monthly|semester`:
1. Agent reads the corresponding scratch file
2. Cross-references vault data to produce the formatted recap
3. Proposes 3 "biggest win" candidates auto-generated from the period's data
4. User picks one (or writes their own) — agent writes the choice into the recap
5. Saves to `Recaps/<level>/<period>.md`
6. Resets the scratch file to empty for the new period

#### Period boundary detection

- **Weekly:** Sunday is the natural recap day. The agent detects "is today Sunday and does a recap not yet exist?" on nightly, and surfaces a hint: "Weekly recap ready."
- **Monthly:** Last day of the month triggers the hint. Monthly scratch is written on the last nightly of the month.
- **Semester:** Tied to `/akasha-semester-setup`. No auto-detection needed — the semester transition flow includes the recap as a step.

#### Biggest win flow

The agent scans the period's data and proposes 3 candidates based on what's factually notable. Examples of auto-generated candidates:

- "5-day study streak completed this week"
- "Finished 3 Strang chapters"
- "10 new Knowledge notes created across 3 domains"
- "First week all three floors held every day"
- "Completed AWS AI Practitioner practice exam"

Candidates are derived from: streak milestones, deliverable completion counts, chapter completions, note creation spikes, and floor consistency. User picks one or writes their own. The agent writes the final choice into the recap.

#### `akasha-recap` agent

```markdown
---
name: akasha-recap
description: Produce a period recap (weekly, monthly, semester) by reading the corresponding scratch file and cross-referencing vault data. Proposes 3 biggest-win candidates for the user to pick from.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
You produce a factual, backward-looking period recap.

Process:
1. Determine the target period from today's date and `level` parameter.
2. Read the corresponding scratch file from .akasha/.
3. Cross-reference with source data:
   - Daily/<period-dates>.md (energy tags, handwritten top-3 items)
   - Goals/weekly/ + Goals/monthly/ (deliverable stats, completion rates)
   - Knowledge/_index.md + _moc-registry.md per domain (note count, MOC growth)
   - StudyMaterials/active/*.md (chapter completion status)
   - .akasha/streak.md (floors held, any breaks)
   - Inbox/_processed/ (count of items processed in the period)
4. Produce the formatted recap under Recaps/<level>/<period>.md using the
   appropriate structure for the level (weekly/monthly/semester sections).
5. Generate 3 biggest-win candidates from data patterns.
6. Present the candidates and ask the user to pick one or write their own.
7. On user confirmation, write the chosen win into the recap and save.
8. Reset the scratch file to empty for the new period.

Never: write the recap without user confirmation on the biggest win,
overwrite an existing recap, or alter data in Daily/, Goals/, or Knowledge/.
Read-only except for the final recap file and scratch reset.
```

---

## 6. Key flows

### 6.1 Capture (manual, always-on, no agent)

- **Math/graphs:** paper → phone photo → synced into `Inbox/` (Obsidian mobile or a synced folder).
- **Code/concepts:** typed in Obsidian, either authored directly in `Knowledge/` or dropped as a fleeting `.md` in `Inbox/`.

### 6.2 Nightly run — `/akasha-nightly` skill

The nightly pipeline is wrapped in a skill so it's invokable as a slash command — no manual shell commands needed.

**Invocation:** `/akasha-nightly` (or `/akasha-nightly` typed in any cmdc session in the vault).

**Under the hood**, the skill runs four headless `cmd` calls sequentially:

```bash
cd "$HOME/akasha"
cmd -p "$(cat bin/prompts/process-inbox.md)"       --yolo --skip-onboarding --max-turns 60
cmd -p "$(cat bin/prompts/goal-adjust.md)"         --yolo --skip-onboarding --max-turns 15
cmd -p "$(cat bin/prompts/append-recap-scratch.md)" --yolo --skip-onboarding --max-turns 5
cmd -p "$(cat bin/prompts/update-hotcache.md)"     --yolo --skip-onboarding --max-turns 8
```

`process-inbox.md` instructs the main session: *"List every file in `Inbox/` (excluding `_processed/`). For each, delegate to the `akasha-ingest` agent. After all are filed, update `Knowledge/_index.md`."* (Delegation works headlessly; slash commands don't — hence prompt-driven, not `/skill`-driven.)

`goal-adjust.md` instructs: *"Read `Goals/weekly/` for the current week. Read today's `Daily/` note. For each pending deliverable, check if it was completed. Reschedule slipped items forward. Flag items slipped 3+ times. If >50% slipped, surface Start/Stop/Continue. Update the weekly goal file."*

`append-recap-scratch.md` instructs: *"Read today's `Daily/` note and `.akasha/streak.md`. Append 2-3 lines to `.akasha/recap-weekly-scratch.md` — today's streak status, deliverable completions, notes created count. No output needed."* If it's the last day of the month or the last week of a semester, update the monthly/semester scratch files as well.

**Error surfacing:** The skill captures exit codes and stderr from all three `cmd` runs. If any fails, it surfaces the error summary to the user — e.g. which agent errored, how many items processed before failure, and the relevant log tail. No silent failures.

**Trigger: manual, anchored to the 10:00 planning ritual — not cron.** A commuter laptop isn't reliably on at 11pm, and an invisible daemon is exactly the kind of ignorable plumbing that died before. Running `/akasha-nightly` as the last step of the existing nightly planning peg keeps it rhythm-based and keeps you in the loop. Cron/launchd is an optional later add, not a dependency.

**`bin/akasha-nightly.sh`** still exists as the script the skill delegates to — it can also be run directly if needed, but the skill is the primary interface.

### 6.3 Hygiene (weekly, opt-in)

`akasha-lint` (ported autonote `wiki-lint`, stripped of DragonScale checks): orphans, dead `[[links]]`, missing frontmatter, empty sections, stale `seed` notes >30d. MOC hierarchy checks: orphaned MOCs, registry drift, overfull/underfull MOCs, depth warnings. **Reports only, never auto-fixes.** Run it as part of the Sunday review.

### 6.4 Goal-setting flow

Goals are set via `/akasha-goal-set <level> [file]`. Two input modes, one output structure.

**CLI brainstorming (comprehensive):**
1. Agent reads cascade context (what exists above the target level).
2. For semester: asks about courses, commitments, materials, capacity.
3. For monthly: reads semester goal + material TOCs, identifies deadlines, proposes Must/Should/Nice.
4. For weekly: reads monthly goal, last week's deliverables, identifies ONE Thing, derives daily targets.
5. Agent proposes the full goal file. User confirms or adjusts. File is written.

**File ingestion:**
1. User provides file path (markdown or PDF).
2. Agent reads content (PDF via `bin/pdf-extract.sh text`).
3. Asks: "Adopt wholly or adjust?"
4. If adopt: parses into universal YAML structure, places in correct `Goals/` subdirectory.
5. If adjust: guided conversation — agent asks which parts to keep/modify/drop, proposes changes, gets confirmation.

### 6.5 Daily goal integration

**Morning (`/akasha-daily`):**
1. Read current week's deliverables (`Goals/weekly/`).
2. Read current month's Must/Should priorities (`Goals/monthly/`).
3. Read `.akasha/hot.md` for recent context.
4. Surface cascade context block + 1–3 suggestions ("you might focus on today").
5. Carry over unfinished items from yesterday.
6. Scaffold daily note.

**Evening (`/akasha-nightly`):**
1. Process inbox (existing flow).
2. Run goal adjustment: check today's daily for completed deliverables, reschedule slipped items.
3. Update hot cache with adjustment summary.
4. Auto-commit.

The suggestions are prompts, not assignments. The adjustment is quiet — reschedule forward, no failure markers.

### 6.6 Semester transition flow

Via `/akasha-semester-setup <term>`:

1. Archive current materials: `StudyMaterials/active/` + `pdfs/` → `archive/<previous-term>/` (uses `bin/prompts/semester-archive.md` for headless execution).
2. Read 4-year vision + last semester's goal.
3. Ask: "What's the focus this term? Course load? Materials?"
4. If PDFs in `inbox/`: offer to run `/akasha-material-ingest` for each.
5. Create semester goal file with monthly breakdown and material references.
6. Generate first monthly goal with Must/Should/Nice deliverables.

Summer terms follow the same flow — they're just another semester entry with lighter expected load.

### 6.7 Recap flow

Via `/akasha-recap <weekly|monthly|semester>`:

1. Agent determines the target period from today's date and the level parameter.
2. Reads the corresponding scratch file from `.akasha/` (`.akasha/recap-weekly-scratch.md` for weekly, etc.).
3. Cross-references with `Daily/`, `Goals/`, `Knowledge/_index.md`, `StudyMaterials/active/`, `.akasha/streak.md`, and domain `_moc-registry.md` files for a complete picture.
4. Proposes 3 biggest-win candidates auto-generated from the period's data.
5. User picks one (or writes their own) — agent writes the final recap to `Recaps/<level>/<period>.md`.
6. Resets the scratch file to empty for the new period.
7. If invoked during `/akasha-semester-setup` for semester-level recap, the recap runs before archiving the previous term's materials.

---

## 7. Design invariants

- **I-1 — Agent layer is enrichment, never plumbing.** Capture and reading work with zero `cmd` runs. The agent only files/links/transcribes. If Akasha is down for a week, the Inbox is still a readable pile of notes. *This is the hard line between the Phase 0 life layer and the Phase 1 build layer.*
- **I-2 — No accusing backlog.** No surfaced "N unprocessed" counter, ever. The Inbox empties nightly; the streak is positive-only. (Notion died of this.)
- **I-3 — One home.** No split-by-mood. Rails split by *content type* only (photo-math vs typed-code), both landing in one vault.
- **I-4 — Idempotent ingest.** Re-running on an already-filed source updates, never duplicates (index check in `akasha-ingest` step 2).
- **I-5 — Raw sources immutable.** Enforced by `raw-guard.sh`, not by trust.
- **I-6 — Goals suggest, never dictate.** Daily suggestions from the goal cascade are prompts, not assignments. You choose what to adopt. The system never blocks or warns if you ignore a suggestion.
- **I-7 — No failure markers.** Deliverables are `pending`, `done`, `slipped`, or `rescheduled` — never "failed" or "missed." Dropped goals go to `_not-doing.md` with an explicit note, not a deletion.
- **I-8 — Structural changes require confirmation.** Auto-adjustment only reschedules deliverables forward. Dropping goals, changing semester scope, or modifying the 4-year vision always requires explicit user confirmation.

---

## 8. Build plan — sprints, worktrees, subagent ownership, merge order

**Dev subagents** (live in the *build repo's* `.commandcode/agents/`, distinct from the runtime `akasha-*` agents which are the product):

| Dev subagent              | Owns                                                                    |
| ------------------------- | ----------------------------------------------------------------------- |
| `substrate-engineer`      | vault folders, templates, index/hot-cache/streak stubs                  |
| `harness-engineer`        | `.commandcode/` config, hooks, `AGENTS.md`, `bin/` wrappers             |
| `pipeline-engineer`       | `akasha-ingest`, process-inbox prompt, image→LaTeX path, `akasha-adopt` |
| `accountability-engineer` | daily/streak/floors, `akasha-weekly`, `akasha-goal-align`               |
| `goals-engineer`          | goal cascade, study materials, PDF parsing, `akasha-goal-setter`, `akasha-goal-tracker`, `akasha-material-parser` |
| `hygiene-engineer`        | `akasha-lint`, lightweight query prompt                                 |
| `recap-engineer`          | period recaps, scratch files, biggest-win flow, nightly integration     |
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
| 1   | `feat/substrate`  | substrate-engineer | folder tree, 8 templates (6 knowledge + 2 accountability), `_index.md`, `_domains.md`, `hot.md`/`streak.md` stubs, MOC template with `moc_level`/`parent` frontmatter fields, `_moc-registry.md` template | —               |
| 2   | `feat/harness`    | harness-engineer   | `settings.json`, `auto-commit.sh`, `raw-guard.sh`, `AGENTS.md`, `bin/` stubs, `/akasha-nightly` skill | substrate paths |

**Merge order:** `substrate` → `harness` → `sprint-1` → `main`.
**Acceptance:** a `cmd` session in the vault loads `hot.md` via `AGENTS.md`; a write to `Knowledge/` triggers an auto-commit; a write to `Inbox/_processed/` is denied by the guard; `/akasha-nightly` runs the pipeline and surfaces any errors; MOC template includes `moc_level` and `parent` frontmatter fields; `_moc-registry.md` template exists and is valid markdown table.

### Sprint 2 — Capture & Ingest (the engine)

| #   | Worktree / branch | Owner             | Scope                                                                           | Depends on             |
| --- | ----------------- | ----------------- | ------------------------------------------------------------------------------- | ---------------------- |
| 1   | `feat/ingest`     | pipeline-engineer | `akasha-ingest` agent, `process-inbox.md`, MOC registry navigation, cross-domain listing, split threshold proposals, index update, idempotency (I-4)      | Sprint 1               |
| 2   | `feat/vision`     | pipeline-engineer | photo→LaTeX transcription rules, `math` template wiring, `_processed/` archival | `feat/ingest` contract |
| 3   | `feat/capture`    | pipeline-engineer | `/akasha-capture` skill for cmdc-native quick capture to Inbox                  | Sprint 1               |

**Merge order:** `ingest` → `vision` → `capture` → `sprint-2` → `main`.
**Acceptance:** dropping one typed note + one math photo in `Inbox/`, then running `/akasha-nightly`, yields two linked Knowledge notes (math one in LaTeX), an updated `_index.md`, both sources in `_processed/`, and a re-run creates no duplicates. The ingest agent navigates `_moc-registry.md` to place each note in the deepest matching MOC, cross-lists across domains when relevant, and updates the registry's `Notes` count. `/akasha-capture "test note"` creates a file in `Inbox/` that gets processed on the next nightly run.

### Sprint 2.5 — Adopt existing vault (one-shot)

| #   | Worktree / branch | Owner             | Scope                                                                                 | Depends on              |
| --- | ----------------- | ----------------- | ------------------------------------------------------------------------------------- | ----------------------- |
| 1   | `feat/adopt`      | pipeline-engineer | `akasha-adopt` agent, `/akasha-adopt` skill, tag hierarchy inference, MOC hierarchy proposal table, `_moc-registry.md` seeding, non-destructive migration | Sprint 2 (needs ingest) |

**Merge order:** `adopt` → `sprint-2.5` → `main`.
**Acceptance:** a dry run produces a folder→target mapping report and changes nothing; the agent infers a tag hierarchy from link patterns and produces a proposal table (tag → MOC name, `moc_level`, `parent`, `domain`, referencing notes) and stops for confirmation; on approval the existing vault's notes land in Akasha with frontmatter backfilled, `4 - Indexes/` files become domain-level MOCs (`moc_level: domain`), `3 - Tags/` hub notes become topic/subtopic MOCs with inferred hierarchy, `_moc-registry.md` is seeded for each domain, templates merged (none overwritten), `_domains.md` seeded from index files — all reversible via git, no atomic-note bodies rewritten. `/akasha-adopt` is invokable as a slash command and handles the interactive confirmation flow.

### Sprint 3 — Accountability & Review

| #   | Worktree / branch | Owner                   | Scope                                                                     | Depends on    |
| --- | ----------------- | ----------------------- | ------------------------------------------------------------------------- | ------------- |
| 1   | `feat/streak`     | accountability-engineer | daily-note flow, `streak.md` positive tracker, floors, fried-day fallback | Sprint 1      |
| 2   | `feat/review`     | accountability-engineer | `akasha-weekly` + `akasha-goal-align` agents, `/akasha-review` + `/akasha-goal-check` + `/akasha-daily` skills | `feat/streak` |

**Merge order:** `streak` → `review` → `sprint-3` → `main`.
**Acceptance:** `/akasha-daily` creates today's daily from template with carry-over from yesterday (cascade context surfaces "No active goals" until Sprint 5); `/akasha-review` reads the week's dailies + streak and produces the five-question review under the 15-min format; `/akasha-goal-check` audits recent dailies against goals and reports drift; no accusing backlog is surfaced anywhere (I-2 check).

### Sprint 4 — Hygiene & Query (polish)

| #   | Worktree / branch | Owner            | Scope                                                             | Depends on |
| --- | ----------------- | ---------------- | ----------------------------------------------------------------- | ---------- |
| 1   | `feat/lint`       | hygiene-engineer | `akasha-lint` agent, `/akasha-lint` skill (orphans/dead-links/frontmatter, MOC hierarchy checks: orphaned MOCs, registry drift, overfull/underfull MOCs, depth warnings), report-only | Sprint 2   |
| 2   | `feat/query`      | hygiene-engineer | `akasha-query` agent, `/akasha-search` + `/akasha-status` skills  | Sprint 2   |

**Merge order:** `lint` → `query` → `sprint-4` → `main`.
**Acceptance:** `/akasha-lint` flags a deliberately-orphaned note, flags an overfull MOC (15+ notes) as a split candidate, detects registry drift between MOC frontmatter and `_moc-registry.md`; `/akasha-search linear algebra` returns matching Knowledge notes with snippets; `/akasha-status` shows inbox count, streak, domain breakdown, and last nightly timestamp; all three are read-only and invokable as slash commands.

### Sprint 5 — Goal Cascade & Study Materials

| #   | Worktree / branch    | Owner           | Scope                                                                                                | Depends on             |
| --- | -------------------- | --------------- | ---------------------------------------------------------------------------------------------------- | ---------------------- |
| 1   | `feat/goals`         | goals-engineer  | `Goals/` directory structure, goal YAML data model, goal templates, `_goal-domain-map.md`, `_not-doing.md` | Sprint 1               |
| 2   | `feat/materials`     | goals-engineer  | `StudyMaterials/` structure, `bin/pdf-extract.sh`, `akasha-material-parser` agent, `/akasha-material-ingest` skill | Sprint 1               |
| 3   | `feat/goal-setter`   | goals-engineer  | `akasha-goal-setter` agent, `/akasha-goal-set` skill (CLI brainstorming + file ingestion), cascade context surfacing | `feat/goals`           |
| 4   | `feat/goal-tracker`  | goals-engineer  | `akasha-goal-tracker` agent, `/akasha-goal-adjust` skill, auto-adjustment logic, nightly integration | `feat/goals`           |
| 5   | `feat/semester`      | goals-engineer  | `/akasha-semester-setup` skill, archive lifecycle, material ↔ semester linking | `feat/materials`, `feat/goal-setter` |
| 6   | `feat/daily-goals`   | goals-engineer  | Update `/akasha-daily`, `/akasha-nightly`, and `/akasha-review` for cascade surfacing, goal adjustment, and goal progress table integration | `feat/goal-tracker`    |

**Merge order:** `goals` → `materials` → `goal-setter` → `goal-tracker` → `semester` → `daily-goals` → `sprint-5` → `main`.
**Acceptance:** `/akasha-goal-set semester` runs an interactive brainstorming session that produces a semester goal file; dropping a PDF in `StudyMaterials/inbox/` and running `/akasha-material-ingest` creates a structured TOC in `active/`; `/akasha-daily` surfaces cascade context and suggestions from weekly deliverables; `/akasha-nightly` auto-reschedules slipped deliverables; `/akasha-semester-setup` archives previous materials and creates a new semester goal; goal ↔ domain mapping connects academic goals to Knowledge domains.

**Overall merge order:** `sprint-1 → sprint-2 → sprint-2.5 → sprint-3 → sprint-4 → sprint-5 → sprint-6 → main`.

> Solo-dev note: the two worktrees per sprint are *optional* parallelism. If juggling two `cmd` sessions adds friction, run them sequentially on one branch — the dependency arrows already give a safe linear order. Don't let the build orchestration become its own maintenance project.

### Sprint 6 — Period Recaps (snapshots)

| #   | Worktree / branch | Owner           | Scope                                                                                               | Depends on              |
| --- | ----------------- | --------------- | --------------------------------------------------------------------------------------------------- | ----------------------- |
| 1   | `feat/recap`      | recap-engineer  | `Recaps/` directory structure, `.akasha/recap-*-scratch.md` stubs, `akasha-recap` agent, `/akasha-recap` skill, `bin/prompts/append-recap-scratch.md`, nightly pipeline integration (4th headless step), period boundary detection (weekly/monthly), biggest-win candidate generation and interactive flow | Sprint 3 + Sprint 5     |

**Merge order:** `recap` → `sprint-6` → `main`.
**Acceptance:** `/akasha-recap weekly` reads the scratch file and produces `Recaps/weekly/YYYY-WXX.md` with deliverable stats, streak data, knowledge growth, material progress, study load, biggest win, and upcoming deliverables; agent proposes 3 biggest-win candidates from the period's data; user picks one and the recap is saved; scratch file resets to empty; nightly pipeline appends 2-3 lines to the scratch file silently; monthly and semester recaps work with the same flow; period boundary detection surfaces a hint when a recap window opens.

---

## 9. Risks & open questions

- **Vision/LaTeX accuracy** on messy handwriting is the biggest unknown. Mitigation: keep raw photos in `_processed/`; treat transcriptions as `status: seed` for review, not ground truth.
- **`--max-turns 60`** may be tight for a large Inbox; raise per run or chunk the Inbox.
- **commandcode model choice** for vision: confirm which available model handles image input on the $1 plan before Sprint 2 (the docs list Claude Opus/Sonnet/Haiku among providers).
- **Sync reliability** of phone→`Inbox/` is outside the harness; pick the sync mechanism (Obsidian mobile vs synced folder) before Sprint 2.
- **PDF TOC extraction quality** varies widely. Some ebooks have clean built-in bookmarks; others have none. Mitigation: fallback to text extraction + agent-based chapter identification, but this is slower and less reliable. Test with actual study materials before Sprint 5.
- **Difficulty estimation accuracy** — the agent's page-count + content-complexity heuristic may not match actual difficulty for a given student. Mitigation: user confirms/adjusts during ingestion; pacing auto-adjusts from real completion data over time.
- **Goal cascade maintenance burden** — 4 levels of goal files is more surfaces to keep updated than the current streak-only system. Mitigation: auto-adjustment handles weekly deliverables; monthly and semester levels are reviewed during existing review rituals (weekly review, semester setup). The system should feel like it's working *for* you, not creating more work.

## 10. Decisions — resolved

1. **Vault path** — `~/akasha`. ✅
2. **Domains** — flexible via `Knowledge/_domains.md`: `akasha-ingest` files into existing domains only and *proposes* new ones under a `## Proposed` heading; you promote them by hand. Auto-suggest, manual-confirm — no silent sprawl. ✅
3. **Trigger** — manual, anchored to the nightly planning ritual. ✅
4. **Build style** — linear single-branch (two-worktree parallelism stays optional, per §8). ✅

**Methodology (new):** Zettelkasten + LYT MOCs, hardcoded; PARA explicitly not used in the knowledge vault (§5.0).
**Existing vault (new):** folded in via the one-shot `akasha-adopt` agent (§5.6 / Sprint 2.5), non-destructive and reversible.

**Goal cascade (new):** 4-year → semester → monthly → weekly. 6 life areas: academic, career, health, relationships, soul, financial. Academic goals map to Knowledge domains via `_goal-domain-map.md`. Hybrid tracking: YAML for system-managed deliverables, checkboxes for manual sub-tasks. No effort allocation percentages.
**Study materials (new):** `StudyMaterials/` with `inbox/`, `active/`, `pdfs/`, `archive/`. PDF parsing via `pdftotext` + `pymupdf` (not LLM-native — open-source models can't read PDFs). TOC extraction with difficulty estimation, user-confirmed. Semester lifecycle: archive previous, setup new.
**Auto-adjustment (new):** Slipped deliverables reschedule forward. 3+ slips → flag for rescheduling. >50% slipped → Start/Stop/Continue. Never "failed." Structural changes require confirmation.
**Daily integration (new):** Cascade context surfacing in `/akasha-daily` (ONE Thing + monthly priorities + suggestions). Goal adjustment in `/akasha-nightly` (reschedule slipped items, update hot cache).
**Goal areas (new):** 6 areas — academic, career, health, relationships, soul, financial. "Growth" dropped (vague). "Creativity" replaced by "soul" (broader). "Academic" added (primary study area).
**Period recaps (new):** 3-level recap system — weekly / monthly / semester. Hybrid trigger: nightly silently appends raw data to scratch files; user invokes manually to produce formatted snapshot. Biggest win is user-picked from 3 agent-proposed candidates. Sprint 6, depends on Sprint 3 (dailies/streak) and Sprint 5 (goals/materials).
