# /akasha-diagram-parser — Parse handwritten diagrams from photos into structured outputs (Canvas JSON, Mermaid, or image-link notes)

Invoked by akasha-mobile-parser or akasha-ingest when an image is classified as non-math (diagram, flowchart, sketch, or mixed content).

## Behavior

1. Classify image content using the rubric below
2. Select output format based on classification
3. Read reference from `references/` for the chosen format (if ref file is missing, fall back to image-link note)
4. Generate output following the reference spec
5. Validate output — run `bin/akasha-diagram-lint.js <file>` for Canvas/Mermaid, or check confidence thresholds internally
6. If validation fails or confidence is low, fall back to image-link note

## Classification Rubric

**Math** — Equations, derivations, proofs with symbols  
→ NOT handled here, pass to math path

**Mind map / spatial** — Central concept with branching nodes, free-form positioning  
→ Canvas (.canvas)

**Flowchart / process** — Sequential steps, decision diamonds, labeled arrows  
→ Mermaid (flowchart)

**System architecture** — Box-and-arrow layers, components, services  
→ Canvas (.canvas)

**Concept sketch** — Freehand drawing of data structures, trees, graphs  
→ Canvas (.canvas)

**Annotated code** — Written code with margin scribbles, arrows between lines  
→ Image-link note

**Mixed (math + diagram)** — Both equations and a diagram on the same page  
→ Math in .md body + Canvas embed with `![[diagram.canvas]]`

If unsure, prefer Canvas over image-link. If image is completely unreadable, create image-link note with `> [!warning] Could not classify`.

## Output Specifications

### Canvas path
- Read `references/canvas/spec.md` for JSON Canvas 1.0 spec (if missing, fall back to image-link)
- Read `references/canvas/examples.md` for examples (if missing, use spec only)
- Produce a valid `.canvas` file with text nodes, edges, group nodes as needed
- Include the original image as a file node in the canvas for reference
- Save `.canvas` alongside `.md` note
- The `.md` note embeds the canvas with `![[filename.canvas]]`
- Canvas files are NOT registered in `_moc-registry`

### Mermaid path
- Read `references/mermaid/flowchart.md` for flowchart syntax (if missing, fall back to image-link)
- Use `flowchart TD` or `flowchart LR` for process/algorithm diagrams
- Use `mindmap` for hierarchical diagrams (ref: `references/mermaid/mindmap.md`)
- Produce a valid ` ```mermaid` code block — goes directly in `.md` body
- No separate file needed

### Image-link path (fallback)
- Create a `.md` concept note with `type: concept`, `domain: <detected>`, `status: seed`
- Do NOT embed the image (`![[image.jpg]]`) — link instead: `[[_assets/session-id/image.jpg]]`
- Write a brief description of what the diagram shows
- Set `image_source` frontmatter to the referenced file

## Edge Cases

- **Unreadable image** — Create image-link note with `> [!warning] Could not classify`, still archive to `_assets/`
- **Mixed math + diagram** — Math transcribes to .md body, diagram to .canvas, embedded mid-body
- **Validation failure** — Agent falls back to image-link note silently
- **Low-confidence output** (many `[?]` markers) — Still produce output but add `> [!warning] Transcription may be inaccurate` callout
- **Missing reference file** — Agent falls back to image-link note and reports the missing ref in output
- **Unfamiliar diagram type** — Default to Canvas over image-link

## Validation

- Run `bin/akasha-diagram-lint.js <file>` after generating Canvas or Mermaid output (if linter doesn't exist yet, validate manually against confidence thresholds)
- If the linter exits with non-zero, fall back to image-link note
- If the output has many `[?]` markers or unreadable text, consider this low confidence
