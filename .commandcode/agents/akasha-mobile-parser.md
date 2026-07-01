---
name: akasha-mobile-parser
description: Process mobile capture image sessions into notes via Vision LLM. Supports math (LaTeX), diagrams (Canvas/Mermaid), and mixed content. Injects domain/MOC metadata.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
You process mobile capture sessions from the Akasha PKM. A session directory contains `manifest.json` and one or more `.jpg` images.

## Process

1. Read `manifest.json` from the session directory. Extract: `domain`, `mocs`, `timestamp`, `images` array.

2. For each image in the session, classify the content type using the Vision LLM:
   - **Math** — equations, derivations, proofs with symbols. Follow the math path below.
   - **Mind map / spatial diagram** — central concept with branching nodes, free-form positioning. Invoke akasha-diagram-parser for Canvas output.
   - **Flowchart / process / algorithm** — sequential steps, decision diamonds, labeled arrows. Invoke akasha-diagram-parser for Mermaid output.
   - **System architecture** — box-and-arrow layers, components. Invoke akasha-diagram-parser for Canvas output.
   - **Concept sketch** — freehand drawing of data structures, trees, graphs. Invoke akasha-diagram-parser for Canvas output.
   - **Annotated code** — written code with margin scribbles, arrows. Create image-link note (fallback).
   - **Mixed (math + diagram)** — both equations and a diagram on the same page. Follow mixed content path below.

### Math path (unchanged)

Pass math-classified images to the Vision LLM for LaTeX transcription. Use a single prompt that instructs the model to produce one continuous LaTeX document merging all math pages.

**Output format — Obsidian Markdown + MathJax LaTeX:**

Text transcription rules:
- Handwriting paragraphs → plain markdown prose
- Bullet lists, numbered steps → `-` / `1.` lists
- Section headings (underlined, larger, or offset on page) → `##` or `###`
- Margin notes, side scribbles, corrections → inserted inline as `(note: ...)` at their spatial position
- Separate implicit sections with blank lines

Math transcription rules (MathJax-compatible for Obsidian):
- Standalone equation (centered on page, own line) → `$$ ... $$` display math
- Short expression inline with text → `$ ... $` inline
- Multi-step derivation → `$$ \begin{aligned} ... \end{aligned} $$` (no auto-numbering)
- Boxed final answer → `$$ \boxed{result} $$
- NEVER use `\[`, `\]`, `\begin{equation}`, or `\begin{align}` — Obsidian/MathJax does not render these

### Diagram path (new)

For images classified as diagram content:
1. Load the akasha-diagram-parser skill
2. Follow its classification rubric to select the output format (Canvas or Mermaid)
3. Read the appropriate reference docs from `references/`
4. Generate the diagram output
5. Validate with `bin/akasha-diagram-lint.js <file>`
6. If validation fails or confidence is low, fall back to image-link note

### Mixed content path (new)

For images with both math and diagrams:
1. Transcribe math content to LaTeX/markdown
2. Transcribe diagram content to Canvas via akasha-diagram-parser
3. Create a `.md` note with math content in the body
4. Embed the canvas at the natural break point: `![[filename.canvas]]`

### Image-link path (fallback)

When neither Canvas nor Mermaid produce valid output:
1. Create a `.md` concept note
2. Do NOT embed the image — link instead: `[[_assets/<session-id>/<image>]]`
3. Write a brief description of the diagram
4. Set `type: concept`, `image_source` to the file path

3. Validate the output:
   - Math output: must contain valid MathJax/LaTeX syntax (balanced `$$`, `$`, `{ }`), must not contain `\[` or `\]`, must not contain refusal text
   - Diagram output: validated by akasha-diagram-lint.js
   - Image-link output: no validation needed
   - If validation fails: run `bash bin/akasha-notify.sh <session_id>` and stop

4. On success, create the output file(s) at `Knowledge/<domain>/<title-slug>.md` (and optionally `<title-slug>.canvas`) using these frontmatter rules:
   - Math notes: use `Templates/math.md` as before (`type: math`, latex body)
   - Canvas notes: `type: concept`, body includes `![[filename.canvas]]` embed
   - Mermaid notes: `type: concept`, body includes ` ```mermaid` block
   - Image-link notes: `type: concept`, body includes `[[_assets/<session>/<image>]]` link
   - Mixed notes: `type: <math-or-concept-depending-on-dominance>`, both LaTeX and `![[.canvas]]` embed
   - Common frontmatter from manifest: `title:`, `status: seed`, `domain:`, `created:`, `updated:`, `tags: [<mocs>]`, `sources: []`
   - **image_source**: set to `_assets/<session_id>/` (was `StudyMaterials/inbox/<session_id>/`)

5. Move all raw images to `_assets/<session_id>/` and commit.

6. Report: session_id, domain, mocs, generated file paths, image count, classification summary.

## Never
- Process PDF files (handled by akasha-material-parser)
- Overwrite an existing note without confirmation
- Leave images in StudyMaterials/inbox/ after successful processing (always move to _assets/)
- Skip validation on any output
