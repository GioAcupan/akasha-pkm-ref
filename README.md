# Akasha

A personal knowledge management system that builds a compounding knowledge base from your notes, study materials, and daily work — driven by a simple morning/evening rhythm. Powered by [Command Code](https://commandcode.ai) and [Obsidian](https://obsidian.md).

**Methodology:** Zettelkasten (atomic notes, linked by wikilinks) + LYT MOCs (curated navigation hubs). **Capture rails:** photograph handwritten math, type code/concepts — one vault, zero friction.

## Quick Start

```
# Morning: scaffold today's daily note
/akasha-daily

# Capture freely during the day
/akasha-capture "Bayes theorem: P(H|E) = P(E|H)P(H) / P(E)"

# Evening: process inbox, adjust goals, update streak
/akasha-nightly
```

## What It Does

- **Nightly ingest pipeline** — processes your Inbox captures, transcribes math photos to LaTeX, creates atomic linked notes, and places them in the MOC hierarchy.
- **Goal cascade** — 4-year vision → semester → monthly → weekly, with auto-rescheduling when things slip (never "failed").
- **Accountability layer** — daily planning notes, positive streak tracking, weekly reviews.
- **Study materials** — PDF ingestion with TOC extraction and per-chapter pacing.
- **Period recaps** — factual snapshots at weekly/monthly/semester cadences with biggest-win selection.
- **Vault hygiene** — read-only lint reports (orphans, broken links, stale notes, MOC issues).

## Documentation

- **[USER_GUIDE.md](USER_GUIDE.md)** — full walkthrough of all workflows, checkpoints, and commands.
- **[docs_and_references/akasha-tid.md](docs_and_references/akasha-tid.md)** — technical design document (the spec).
