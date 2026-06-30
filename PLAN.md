# Sprint 2 Track 2 — Vision (Photo-to-LaTeX) Plan

**Plan:** `docs/superpowers/plans/sprint-2-track-vision.md`
**Source:** TASK.md (feat/vision)
**Depends on:** feat/ingest (akasha-ingest agent contract for image handling in step 1)

## Task 1: Update akasha-ingest for image detection

- [ ] Read current `.commandcode/agents/akasha-ingest.md` from ingest merge
- [ ] Add image file extension detection in step 1: `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.tiff`, `.webp`
- [ ] Route image files to photo-to-LaTeX transcription sub-flow
- [ ] Keep non-image files on standard text ingest path

## Task 2: Photo-to-LaTeX transcription rules

- [ ] Extend step 1 with transcription rules when image detected:
  - Use `read_file` to read image (commandcode supports image reading natively)
  - Transcribe handwritten math to clean LaTeX within Markdown
  - Preserve diagrams as described figures: `> [!figure] Description`
  - Maintain structure: problem statement → solution steps → final result
  - Flag uncertain transcriptions with `[?]` notation
  - The model's vision capability handles the actual transcription — the agent's job is to route and structure the output

## Task 3: Math template wiring

- [ ] When creating a Knowledge note from image: select `Templates/math.md`
- [ ] Populate `image_source` frontmatter field with path to `Inbox/_processed/<archived-filename>`
- [ ] Set `type: math` in frontmatter
- [ ] Populate `## LaTeX` section with transcribed content
- [ ] Fill `## Why it matters` and `## Connections` based on content analysis

## Task 4: Domain detection for math content

- [ ] Analyze math content keywords to determine domain:
  - Linear algebra, matrices, vectors, eigenvalues → math
  - Calculus, derivatives, integrals, limits → math
  - Probability, distributions, statistics → math or quant
  - ML notation, neural networks, gradients → cs
  - Finance, economics, optimization, utility → quant
- [ ] Default to math domain if uncertain

## Task 5: Image archival in _processed/

- [ ] Move original image to `Inbox/_processed/YYYY-MM-DDTHH-mm-ss_original-name.ext`
- [ ] Set `image_source` frontmatter in the math note to the archived path
- [ ] Never modify the raw image

## Task 6: Unreadable image handling

- [ ] If image can't be transcribed (too blurry, unreadable):
  - Move to `_processed/` anyway
  - Create minimal math note with `> [!warning] Transcription pending — image was unreadable.` and `status: seed`
  - Include `image_source` link for manual review
- [ ] Never fail silently — always create a note and always preserve the source

## Task 7: Commit

- [ ] Commit to feat/vision with message: "akasha: Sprint 2 Track 2 — photo-to-LaTeX vision transcription"
