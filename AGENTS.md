# Akasha — Agent Bootstrap

> **Harness:** Command Code (`cmdc`), `.commandcode/` config, $1/mo plan.

---

## Startup

At the start of any session, silently read context in this order, respecting token budgets:

1. **`.akasha/hot.md`** — ≤500 tokens. Establishes active context (streak, goals, yesterday's carry-over, today's ONE Big Thing, inbox count).
2. **`Knowledge/_domains.md`** — ≤1000 tokens. Establishes the domain landscape and which Knowledge areas exist.
3. **3-5 specific pages** relevant to today's work — ≤300 tokens each. Scan `Knowledge/_index.md` note titles or infer from hot.md's goals/ONE Big Thing to identify relevant pages.

Total pre-work: ≤3000 tokens before executing any user request.
If hot.md is empty or contains only a placeholder, skip step 3 (no relevant pages known yet).

---

### Output Quality

All agents produce valid Obsidian Flavored Markdown. Reference `.commandcode/references/obsidian-flavored-markdown.md` for exact syntax: wikilinks, embeds, callouts, frontmatter, tags, comments, highlights, math, footnotes, and Mermaid.

---

## Vault Conventions

### Inbox / Knowledge Boundary

- **Inbox/** — Human-owned capture drop zone. Agents read from here but never edit captures in place.
- **Inbox/_processed/** — Immutable archive. Raw sources are moved here after ingest. Never edit or delete.
- **Knowledge/** — Agent-owned atomic notes. This is where all generated content lives.

### Capture Rails

Two rails, zero decisions at capture time:

1. **Math/photos** — Paper → phone photo → synced into `Inbox/`. Agent transcribes to LaTeX.
2. **Code/concepts** — Typed in Obsidian, either directly in `Knowledge/` or as fleeting `.md` in `Inbox/`.

### Note Types

Six knowledge types, determined by frontmatter `type:` field — never by folder:

| Type     | Purpose                                    |
| -------- | ------------------------------------------ |
| concept  | Atomic idea or principle                   |
| math     | LaTeX-heavy, transcribed from photo source |
| source   | Reference material summary                 |
| entity   | Person, tool, or thing                     |
| question | Open question or inquiry                   |
| moc      | Map of Content — curated hub               |

### Status Lifecycle

```
seed → growing → evergreen
```

All new notes start as `seed`.

---

## Design Invariants

### I-1 — Agent layer is enrichment, never plumbing

Capture and reading work with zero `cmd` runs. The agent only files/links/transcribes. If Akasha is down for a week, the Inbox is still a readable pile of notes.

### I-2 — No accusing backlog

No surfaced "N unprocessed" counter, ever. The Inbox empties nightly; the streak is positive-only.

### I-3 — One home

No split-by-mood. Rails split by content type only (photo-math vs typed-code), both landing in one vault.

### I-4 — Idempotent ingest

Re-running on an already-filed source updates, never duplicates (index check).

### I-5 — Raw sources immutable

Enforced by `raw-guard.sh` hook, not by trust.

---

## Methodology

**Zettelkasten + LYT MOCs** — hardcoded, no router.

- Atomic notes, one idea each, connected by `[[wikilinks]]`.
- Structure emerges from links, not folders.
- MOCs are curated, hand-ordered hub notes for navigation.
- Domain folders (`math/`, `cs/`, etc.) are coarse buckets only.
- PARA is NOT used in the knowledge vault — action tracking lives in `Daily/` and `Reviews/`.

### MOC Hierarchy

Notes must remain freely linkable across MOCs without restriction — MOCs are navigational aids that provide hierarchy, not boundaries that limit cross-MOC wikilinks. The system is a wiki (not a tree), and linking patterns must never be constrained by MOC placement.

MOCs form a recursive tree within each domain, navigated via `_moc-registry.md`:

- **`moc_level: domain`** — root MOC, one per domain folder
- **`moc_level: topic`** — major topic within a domain
- **`moc_level: subtopic`** — any depth below topic (recursive)

Each MOC has one structural parent (frontmatter `parent:` field), except domain-level MOCs. A note can be listed in any number of MOCs, cross-domain. The MOC tree overlays the wiki graph — it doesn't constrain it.

Each domain folder contains `_moc-registry.md` — a derived index maintained by `akasha-ingest` and `akasha-lint`. The MOC frontmatter is the source of truth; the registry is a fast-lookup cache.
