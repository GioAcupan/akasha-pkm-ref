# Sprint 2 Track 2 — Vision (Photo-to-LaTeX Transcription)

**Owner:** pipeline-engineer  
**Branch:** feat/vision
**Depends on:** feat/ingest (needs akasha-ingest agent contract for image handling)

## Scope

Add photo-to-LaTeX transcription to the ingest pipeline. When `akasha-ingest` encounters an image file in the Inbox, it transcribes the handwritten math into clean LaTeX and creates a `type: math` note. The raw photo is preserved in `_processed/` for verification.

## Tasks

### 1. Image detection in akasha-ingest

Update the `akasha-ingest` agent to detect image files (`.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.tiff`, `.webp`) in step 1 of the ingest process. When an image is detected:

- Route to the photo-to-LaTeX transcription flow
- Non-image files continue through the standard text ingest flow

### 2. Photo-to-LaTeX transcription rules (§5.2 step 1)

Extend the agent's step 1 with transcription rules:

- Read the image using `read_file` (commandcode's `read_file` supports image files directly — the model sees the image content)
- Transcribe handwritten math into clean LaTeX within Markdown
- Preserve diagrams as described figures (e.g. "> [!figure] Description of the diagram")
- Maintain the structure: problem statement → solution steps → final result
- Flag uncertain transcriptions with `[?]` notation for review

### 3. Math template wiring (§5.1)

When creating a Knowledge note from an image:

- Use `Templates/math.md` as the template
- Populate `image_source` frontmatter field with the path to the original image in `Inbox/_processed/` (for traceability)
- Set `type: math` 
- Populate the `## LaTeX` body section with the transcribed content
- Fill `## Why it matters` and `## Connections` sections based on context

### 4. Domain detection for math content

When transcribing math content:

- Analyze the mathematical content to determine the domain:
  - Linear algebra / matrices / vectors → math domain
  - Calculus / derivatives / integrals → math domain  
  - Probability / statistics → math or quant domain
  - Machine learning notation → cs domain
  - Economics / finance math → quant domain
- Default to math domain if uncertain

### 5. _processed/ archival for images (§5.2 step 9)

When moving image sources to `_processed/`:

- Preserve original filename with timestamp prefix: `YYYY-MM-DDTHH-mm-ss_original-name.jpg`
- Never edit or modify the raw image
- Set the `image_source` frontmatter in the corresponding math note to `Inbox/_processed/<archived-filename>`

### 6. Error handling for unreadable images

If the image cannot be transcribed (too blurry, unreadable handwriting):

- Move the image to `_processed/` anyway
- Create a minimal `type: math` note with status: seed and a note: `> [!warning] Transcription pending — image was unreadable. Please review manually.`
- Include the `image_source` link for manual review

## Acceptance Criteria

- Image files (`.jpg`, `.png`, etc.) in Inbox are detected by the ingest agent
- Handwritten math in images is transcribed to LaTeX
- Transcribed content uses `Templates/math.md` with `image_source` frontmatter
- Original images preserved in `_processed/` with timestamped filenames
- Uncertain transcriptions marked with `[?]`
- Unreadable images create a pending-review note instead of failing silently
- Math content correctly routed to appropriate domain (math/cs/quant)
- Integration: a math photo placed in Inbox, processed via nightly, produces a linked Knowledge note with LaTeX
