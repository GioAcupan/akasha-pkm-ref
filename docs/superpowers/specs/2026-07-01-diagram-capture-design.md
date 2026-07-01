# Diagram Capture for Mobile Photo Pipeline

## Problem

The existing `akasha-mobile-parser` only handles LaTeX math transcription. Hand-drawn diagrams (mind maps, flowcharts, system diagrams, concept sketches, annotated code) are common in CS/quantitative notes but have no capture path. They get skipped or produce a generic `[!figure]` callout that loses the visual structure.

## Approach: tiered capture

A single photo goes through classification → format selection → generation → validation → fallback:

```
Photo → Classify →
  ├── Math → existing LaTeX path (unchanged)
  ├── Mind map / spatial diagram → Canvas (.canvas + .md embed)
  ├── Flowchart / process / algorithm → Mermaid (inline in .md)
  ├── System architecture → Canvas (.canvas + .md embed)
  ├── Sketch / annotation → image link (fallback, no structural capture)
  └── Mixed (math + diagram) → .md note + .canvas embedded mid-body
```

### Fallback chain

One attempt per image, then straight to image-link fallback. No retries with alternative format. The classifier is instructed to be conservative. If we see misclassification patterns in practice, the fallback chain can be extended later.

### Output types

| Content | Primary file | Secondary file | Embedding |
|---------|-------------|----------------|-----------|
| Math | `Knowledge/<domain>/<slug>.md` (type: math) | — | Raw LaTeX/markdown in body |
| Mind map / spatial diagram | `Knowledge/<domain>/<slug>.md` (type: concept) | `<slug>.canvas` | `![[<slug>.canvas]]` in body |
| Flowchart / process | `Knowledge/<domain>/<slug>.md` (type: concept) | — | `` ```mermaid `` block in body |
| System architecture | `Knowledge/<domain>/<slug>.md` (type: concept) | `<slug>.canvas` | `![[<slug>.canvas]]` in body |
| Sketch / annotation | `Knowledge/<domain>/<slug>.md` (type: concept) | — | `[[_assets/<session>/<image>.jpg]]` link in body |
| Mixed (math + diagram) | `Knowledge/<domain>/<slug>.md` (type: math or concept) | `<slug>.canvas` | Canvas embed + LaTeX + math in body |

The `.md` note is always the entry point. Canvas files are supporting artifacts never registered in `_moc-registry`.

## Skill: akasha-diagram-parser

A dedicated skill at `.commandcode/skills/akasha-diagram-parser/` that the mobile parser (and ingest agent) invoke when they encounter non-math content.

### Structure

```
.commandcode/skills/akasha-diagram-parser/
├── SKILL.md
│   Purpose: "Parse handwritten diagram photos into structured outputs"
│   Contents:
│     - Classification rubric (math vs diagram type vs sketch)
│     - Workflow: classify → select format → generate → validate → fallback
│     - Output spec (when to produce .canvas, Mermaid block, or image-link note)
│     - Which reference doc to read per diagram type
│
├── references/
│   ├── canvas/
│   │   ├── spec.md          (JSON Canvas 1.0 from obsidian-skills)
│   │   └── examples.md      (mind map, system diagram, flowchart canvases)
│   │
│   ├── mermaid/
│   │   ├── flowchart.md
│   │   ├── sequenceDiagram.md
│   │   ├── classDiagram.md
│   │   ├── stateDiagram.md
│   │   ├── mindmap.md
│   │   ├── entityRelationshipDiagram.md
│   │   ├── gitgraph.md
│   │   ├── timeline.md
│   │   ├── quadrantChart.md
│   │   ├── requirementDiagram.md
│   │   ├── userJourney.md
│   │   ├── gantt.md
│   │   ├── pie.md
│   │   ├── sankey.md
│   │   ├── xyChart.md
│   │   ├── block.md
│   │   ├── packet.md
│   │   ├── kanban.md
│   │   ├── architecture.md
│   │   ├── radar.md
│   │   ├── treemap.md
│   │   ├── c4.md
│   │   ├── zenuml.md
│   │   ├── config-theming.md
│   │   ├── config-directives.md
│   │   ├── config-layouts.md
│   │   ├── config-configuration.md
│   │   └── examples.md      (hand-drawn-to-mermaid transcription patterns)
│   │
│   └── validation/
│       ├── confidence-thresholds.md  (node counts, [?] detection, coordinate sanity)
│       └── failure-patterns.md       (common garbage output shapes)
```

All 38 Mermaid reference files are ported from `docs_and_references/mermaid_skill_references/mermaid-skill/.claude/skills/mermaid/references/`. The Canvas spec is adapted from `docs_and_references/reference-repos/obsidian-skills/skills/json-canvas/`.

Each Mermaid reference gets a light **transcription context** addition — guidance on how to translate a hand-drawn version of that diagram type (e.g., "read entity boxes from handwriting, extract attribute names, identify relationship lines").

## Linter: bin/akasha-diagram-lint.js

A script-based validation tool that the parser calls after generation. Falls back to image-link if validation fails.

```
bin/akasha-diagram-lint.js <file>
```

### Canvas validation

- Valid JSON parse
- Nodes array exists, each node has required fields (id, type, x, y, width, height)
- type is one of: text, file, link, group
- Text nodes have non-empty text
- 16-char lowercase hex IDs are unique across all nodes and edges
- Edge fromNode/toNode reference existing node IDs
- Coordinates are within reasonable bounds
- Color values are valid presets ("1"-"6") or hex strings

### Mermaid validation

- Diagram type declaration is valid (flowchart, sequenceDiagram, classDiagram, etc.)
- Balanced brackets `[]`, parens `()`, curly braces `{}`
- No unclosed quotes
- Node IDs in edge declarations reference declared nodes
- Edge arrows use valid syntax (-->, ->>, -x, etc.)
- No stray special characters that would break rendering

### Non-goals

- No Chromium-based render validation (avoids mmdc dependency)
- No style correctness checking

## Agent modifications

### akasha-mobile-parser.md

The primary target. Current agent has a single math path. Changes:

1. Add classification step per image (math, diagram-type, sketch, mixed)
2. Add diagram processing sub-flow that invokes akasha-diagram-parser skill
3. Support multiple output types: .md only, .md + .canvas, .md with Mermaid block
4. Update `image_source` frontmatter from `StudyMaterials/inbox/<session>/` to `_assets/<session>/`
5. Move images to `_assets/<session>/` after processing

### akasha-ingest.md

Minor updates:

1. Photo-to-LaTeX sub-flow currently uses `[!figure]` callouts for diagrams → replace with skill invocation
2. Image archiving path: `Inbox/_processed/` → `_assets/` (aligns with mobile parser convention)
3. Remove the separate `[!figure]` handling (unified through skill)

## Storage conventions

### Images

`_assets/<session_id>/` is the single source of truth for all original capture images. Subdirectories by session:

```
_assets/
├── <session_1>/
│   ├── page-01.jpg
│   ├── page-02.jpg
│   └── manifest.json
└── <session_2>/
    ├── page-01.jpg
    └── ...
```

### Canvas files

Alongside their .md note in `Knowledge/<domain>/`. Same slug, different extension:

```
Knowledge/cs/
├── binary-search-trees.md
├── binary-search-trees.canvas
├── sorting-algorithms.md
└── sorting-algorithms.canvas
```

Canvas files are not registered in `_moc-registry`. The .md note carries all frontmatter and navigation metadata.

### Inbox/_processed/

Non-image raw sources only (text notes, PDF excerpts, markdown files). All images go to `_assets/`.

### Frontmatter `image_source`

Always points to the session folder or specific file in `_assets/`:

```yaml
image_source: _assets/session-abc123/
# or
image_source: _assets/session-abc123/page-01.jpg
```

## Mobile capture contract (manifest.json)

**No contract change.** The manifest stays as-is:

```json
{
  "domain": "cs",
  "mocs": ["dsa", "trees"],
  "timestamp": "2026-07-01T08:00:00Z",
  "images": ["page-01.jpg", "page-02.jpg"]
}
```

The parser's Vision LLM classifies each image independently. The `domain` field is a hint but the parser can redirect per-image. If misclassification becomes a problem, an optional `type` field can be added to each image entry in a future contract version.

The pull script (`bin/akasha-pull.sh`) interface does not change — same session directory structure, same invocation.

## Error handling

| Scenario | Response |
|----------|----------|
| Can't classify image | `> [!warning] Could not classify` note with image link |
| Canvas generation fails validation | Fall back to image-link note |
| Mermaid syntax is invalid | Fall back to image-link note |
| Partial output (some good, some bad) | Keep good nodes, add `[?]` node for uncertain content |
| Mixed page (math + diagram) | Math in .md body, diagram in .canvas, embedded via `![[.canvas]]` |
| Multiple sessions for same topic | Update existing note, append new content |
| Completely unreadable image | Minimal note with `> [!warning] Transcription pending` |

## Implementation order

1. Create the `_assets/` directory in vault root
2. Create the `akasha-diagram-parser` skill at `.commandcode/skills/akasha-diagram-parser/`
   - Write SKILL.md with classification rubric and workflow
   - Port json-canvas spec + examples from reference-repo
   - Port all 38 Mermaid references from mermaid-skill
   - Write validation reference docs
3. Create `bin/akasha-diagram-lint.js`
4. Update `akasha-mobile-parser.md` — add classification + diagram sub-flow
5. Update `akasha-ingest.md` — align storage paths, replace `[!figure]` with skill
6. Update `raw-guard.sh` if needed to cover `_assets/`
7. Test with real capture sessions
