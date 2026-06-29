# Akasha — Agent Bootstrap

> **Harness:** Command Code (`cmdc`), `.commandcode/` config, $1/mo plan.

---

## Startup

At the start of any session, silently read `.akasha/hot.md` to restore recent context. Do not announce it.

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
