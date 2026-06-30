# Source Note Book Hub — Implementation Plan

> Implementation plan for the source-note book hub design spec. Four files to change, dependency order: template → ingest → lint → adopt.

## 1. Update source template

**File:** `Templates/source.md`

Replace the current template (which has `## Key takeaways` and `## Relevance`) with the new book-hub template from the design spec. Changes:

- Add frontmatter fields: `author`, `source_type`, `rating`
- Replace body sections with `## Summary` and `## Notes Derived from This Source`
- Keep existing frontmatter fields: `type`, `title`, `status`, `domain`, `created`, `updated`, `tags`, `related`, `sources`

## 2. Teach ingest agent source detection & link-back

**File:** `.commandcode/agents/akasha-ingest.md`

Add a new step between current step 3 (Determine domain) and step 4 (Create or update atomic notes). The new step covers:

- Source detection: read `_index.md` for existing `type: source` notes, check `author`/`title` frontmatter, scan Inbox item body for known author/title mentions
- Link-back: after creating each atomic note, append the `[[wikilink]]` under the source note's `## Notes Derived from This Source` section
- No-match fallback: when source can't be identified, file the atomic note normally and suggest creating a source note

Rename existing steps 4-10 to 5-11 to accommodate the new step 4.

## 3. Exclude source notes from lint

**File:** `.commandcode/agents/akasha-lint.md`

Add exclusions for `type: source` notes:

- **Section 1 (Orphaned notes):** skip `type: source` — source notes are expected to have few or no incoming links while books are being read
- **Section 4 (Empty body sections):** skip `## Notes Derived from This Source` for `type: source` — allowed to be empty

Source notes remain checked for: broken outgoing links, missing frontmatter, stale seed status (>30 days).

## 4. Update adopt agent source material migration

**File:** `.commandcode/agents/akasha-adopt.md`

Update step 5 (Migrate source material) with the new template conventions:

- Skeleton stubs (empty files) → create the skeleton template with empty sections
- Content-bearing notes (quotes, summaries) → wrap existing body in `## Summary`, seed `## Notes Derived from This Source` as empty
- Link-only notes → migrate links to `related:` frontmatter, apply template
- Resource lists → treat as `source_type: course` or `article` depending on content
- Backfill frontmatter: `author`, `source_type`, `title`, `domain`, `status: seed`
