---
name: akasha-diagram-parser
description: Parse handwritten diagram photos into structured outputs — Canvas JSON, Mermaid, or image-link notes. Use when the mobile parser or ingest agent encounters non-math image content.
---

# Akasha Diagram Parser

Transcribe handwritten diagrams from photos into structured formats.

## Classification Rubric

Given a photo of a notebook page, classify the content:

| Content type | Characteristics | Output format |
|---|---|---|
| Math | Equations, derivations, proofs with symbols | NOT handled here — pass to math path |
| Mind map / spatial | Central concept with branching nodes, free-form positioning | Canvas (.canvas) |
| Flowchart / process | Sequential steps, decision diamonds, labeled arrows | Mermaid (flowchart) |
| System architecture | Box-and-arrow layers, components, services | Canvas (.canvas) |
| Concept sketch | Freehand drawing of data structures, trees, graphs | Canvas (.canvas) |
| Annotated code | Written code with margin scribbles, arrows between lines | Image-link note |
| Mixed (math + diagram) | Both equations and a diagram on the same page | Canvas + math note with ![[.canvas]] embed |

If unsure, prefer Canvas over image-link. If image is completely unreadable, create image-link note with `> [!warning] Could not classify`.

## Workflow

1. **Classify** image content using the rubric above
2. **Select format** based on classification
3. **Read reference** from `references/` for the chosen format
4. **Generate** output following the reference spec
5. **Validate** output using validation rules
6. **If validation fails**, fall back to image-link note

## Output Specifications

### Canvas path
- Read `references/canvas/spec.md` for JSON Canvas 1.0 spec
- Read `references/canvas/examples.md` for mind map and system diagram examples
- Produce a valid `.canvas` file with text nodes, edges, group nodes as needed
- Include the original image as a file node in the canvas for reference
- Save `.canvas` alongside `.md` note
- The `.md` note embeds the canvas with `![[filename.canvas]]`
- Canvas files are NOT registered in `_moc-registry`

### Mermaid path
- Read `references/mermaid/flowchart.md` for flowchart syntax
- Read `references/mermaid/mindmap.md` for mind map syntax
- Read other `references/mermaid/*.md` files as needed for specific diagram types
- Produce a valid ` ```mermaid` code block for inclusion in the note body
- Use `flowchart TD` or `flowchart LR` for process/algorithm diagrams
- Use `mindmap` for hierarchical diagrams
- No separate file needed — Mermaid block goes directly in the `.md` body

### Image-link path (fallback)
- Create a `.md` concept note
- Do NOT embed the image (`![[image.jpg]]`)
- Instead, link to it: `[[_assets/session-id/image.jpg]]`
- Write a brief description of what the diagram shows
- Include frontmatter: type, domain, tags, image_source pointing to the file

## Validation

- Run `bin/akasha-diagram-lint.js <file>` after generating Canvas or Mermaid output
- If the linter exits with non-zero, fall back to image-link note
- If the output has many `[?]` markers or unreadable text, consider this low confidence

## Mixing with math

If the same image contains both math and a diagram:
1. Transcribe the math to LaTeX/markdown
2. Transcribe the diagram to Canvas
3. Create a `.md` note with the math content in the body
4. Embed the canvas at the natural break point: `![[diagram.canvas]]`
