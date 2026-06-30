# /akasha-material-ingest -- PDF → Structured TOC

Extracts table of contents from a PDF ebook and creates a structured material note in `StudyMaterials/active/`. Moves the PDF to `StudyMaterials/pdfs/` after processing.

## Behavior

1. Delegates to the `akasha-material-parser` agent
2. Takes optional PDF filename argument (e.g., `/akasha-material-ingest strang.pdf`). If no argument, scans `StudyMaterials/inbox/` for PDFs.
3. Agent extracts TOC (bookmarks first, falls back to text extraction)
4. Agent estimates per-chapter difficulty based on page count and content complexity
5. Agent presents structured TOC to user for confirmation/adjustment
6. On approval: creates `StudyMaterials/active/<material-name>.md`, moves PDF to `StudyMaterials/pdfs/`
7. Reports: title, author, chapter count, difficulty distribution, total pages

## Output

```
Material ingested: "Linear Algebra and Its Applications"

Author: Gilbert Strang
Chapters: 12
Difficulty: medium (4 easy, 5 medium, 3 hard)
Total pages: 587
Material note: StudyMaterials/active/strang-linear-algebra.md
PDF moved to: StudyMaterials/pdfs/strang-linear-algebra.pdf
```

## Edge Cases

- **No PDF specified, none in inbox:** "No PDFs found. Drop one in `StudyMaterials/inbox/` first."
- **Multiple PDFs in inbox:** Lists them, asks which to process.
- **No built-in TOC:** Falls back to text extraction + agent-based chapter identification (slower, may need more user adjustment).
- **PDF already ingested:** "This material already has a note in `active/`. Update existing or skip?"
- **PDF is not readable:** Reports the error and leaves the PDF in `inbox/` for manual review.

## Usage

1. Drop PDF in `StudyMaterials/inbox/`.
2. Run `/akasha-material-ingest [optional: filename]`.
3. Confirm/adjust the structured TOC when prompted.
4. The material note is ready -- fill in `term:` when you create a semester goal.

## Output

- Creates `StudyMaterials/active/<material-name>.md`
- Moves PDF to `StudyMaterials/pdfs/`
- Read-only otherwise -- no changes to Knowledge/, Goals/, or other vault areas
