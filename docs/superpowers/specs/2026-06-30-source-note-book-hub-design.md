# Source Note as Book Hub — Design

> A `type: source` note is both a metadata card about the book and a private link hub to everything extracted from it. It lives in a Knowledge domain folder like any other note, but it's invisible to the MOC machinery — no registry entry, no lint split/merge proposals. The book is where you found the idea, not what the idea is.

## 1. Template

```yaml
---
type: source
title: ""
author: ""
source_type: book           # book | paper | article | video | course
status: seed                # seed → growing → evergreen
domain: ""
created: YYYY-MM-DD
updated: YYYY-MM-DD
rating:                     # optional, 1-5
tags: []
related: []                 # [[wikilinks]] to related sources
---

## Summary

## Notes Derived from This Source

<!-- Agent appends [[wikilinks]] to atomic notes created from this book. -->
```

`## Notes Derived from This Source` is agent-managed — ingest appends `[[wikilinks]]` here as it creates atomic notes. The rest is human-maintained. Users can add H3 chapter subheadings underneath the derived notes section as they refine the note toward evergreen.

## 2. Ingest Agent Behavior

Added to `akasha-ingest`:

1. **Source detection.** When processing an Inbox capture, check if it references a known source (explicit mention of author/title in body, or filename matches a source note). Check existing source notes' `title` and `author` frontmatter fields via `Knowledge/_index.md`.
2. **Link back.** When creating an atomic note from a recognized source, append a `[[wikilink]]` to that atomic note under the source note's `## Notes Derived from This Source` section.
3. **Chapter dumps.** When the Inbox item *is* a raw chapter/quote dump from a book (e.g., `The Intellectual Life` passage collection), create atomic concept notes from the extracted ideas, then batch-update the source note with all derived links.
4. **No match.** If the agent can't identify the source, file the atomic note normally and suggest creating a source note for the book.

Non-source captures (random thoughts, standalone concepts) skip this step — only captures linked to a known source trigger source-note updating.

## 3. Lint Exclusion

`akasha-lint` skips source notes for:

- **Orphan checks.** A source note with zero incoming wikilinks is expected for unfinished books, not a defect.
- **Empty-section checks.** `## Notes Derived from This Source` is allowed to be empty (book not yet extracted from).

Source notes are still checked for broken outgoing links, missing frontmatter fields, and stale seed status (>30 days).

## 4. Adopt Mapping

When `/akasha-adopt` migrates `2- Source Material/` files:

1. **Skeleton stubs** (empty files like `Mastery by Robert Greene.md`) → create the skeleton template with empty sections, source_type inferred from the note's nature.
2. **Content-bearing notes** (quote collections, chapter summaries like `The Intellectual Life`, structured breakdowns like `Justin Sung`) → wrap existing body content in `## Summary`, seed `## Notes Derived from This Source` as empty, backfill frontmatter (`title`, `author`, `source_type: book`).
3. **Link-only notes** (e.g., `Investments — [[Finance]] [[Investing]]`) → migrate the links to `related:`, wrap any text in summary, apply template.
4. **Resource lists** (e.g., `AI Study Resources`, `AI ENGINEER LEARNING TIMELINE`) → treat as `source_type: course` or `article` depending on content.

## 5. Scope

- New template: `Templates/source.md`
- Updated agent: `akasha-ingest` (source detection + link-back)
- Updated agent: `akasha-lint` (source-note exclusion)
- Updated agent: `akasha-adopt` (source-material mapping rules)
