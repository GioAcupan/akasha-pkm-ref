---
name: akasha-ingest
description: Process one Inbox item — text note or photo of math. Read it, (transcribe to LaTeX if an image), route into an existing domain from _domains.md (propose new ones, never auto-create), navigate the MOC registry to place the note in the deepest matching MOC, cross-list across domains if relevant, extract concepts/entities, create or update atomic notes under Knowledge/, cross-link, update _index.md, then move the raw source to Inbox/_processed/. Delegate one agent per Inbox item.
tools: read_file, write_file, edit_file, glob, grep, shell_command, think
---
You integrate ONE source into the Knowledge base.

## 1. Read and classify the source

Detect the file extension:

**Image files** (`.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.tiff`, `.webp`):
Route to the photo-to-LaTeX transcription sub-flow below.

**Non-image files** (`.md`, `.txt`, `.pdf`, etc.):
Read as plain markdown/text and skip the transcription sub-flow. Proceed directly to step 2.

### Photo-to-LaTeX transcription sub-flow (images only)

1. Read the image using `read_file`. Command Code supports image reading natively — the vision model handles the actual transcription.
2. Transcribe handwritten math into clean LaTeX within Markdown. Use `$...$` for inline math and `$$...$$` for display/block math.
3. Preserve diagrams as described figures using the callout syntax:
   ```
   > [!figure] Brief description of the diagram
   ```
4. Maintain the original mathematical structure:
   - **Problem statement** — what is being solved
   - **Solution steps** — logical progression of work
   - **Final result** — answer or conclusion
5. Flag any uncertain transcription with `[?]` notation immediately after the uncertain portion (e.g., `$x^2 + y^2 = r^2$[?]` or `The [?] theorem states...`).
6. If the image is completely unreadable (too blurry, garbled, not an image of math), do NOT attempt transcription. Instead, handle as unreadable (see step 9a).

## 2. Check for duplicates

Read `Knowledge/_index.md` and `Knowledge/_domains.md`. Avoid duplicates — check if an equivalent note already exists by title similarity and topic overlap.

## 3. Determine domain

Pick the closest EXISTING domain from `Knowledge/_domains.md`.

### Domain detection for math content

When the source is a math image, analyze the transcribed content for keywords to route to the correct domain:

| Keywords | Domain |
|----------|--------|
| Linear algebra, matrices, vectors, eigenvalues, eigenvectors, span, basis, linear transformations | `math` |
| Calculus, derivatives, integrals, limits, differential equations, series, convergence | `math` |
| Probability, distributions, statistics, expectation, variance, hypothesis testing, Bayesian | `math` or `quant` (see note) |
| ML notation, neural networks, gradients, loss functions, backpropagation, tensors, activation functions | `cs` |
| Finance, economics, optimization, utility, portfolio, pricing, risk, stochastic processes, time value | `quant` |

**Note on probability/statistics**: If the content is theoretical (proofs, derivations, pure probability theory), route to `math`. If it has applied/financial framing (portfolio returns, risk modeling, economic data), route to `quant`.

**Default**: If no keywords clearly match, default to `math`.

If nothing fits, file under the nearest domain anyway and append a one-line candidate under the `## Proposed` section of `_domains.md`. Do NOT create a new domain folder yourself.

## 4. Create or update atomic notes

For each significant concept/entity: create OR update the atomic note under `Knowledge/<domain>/` using the matching template.

### Template selection for image (math) sources

When the source is an image, use `Templates/math.md` as the primary template. Populate as follows:

- **`type`**: `math`
- **`image_source`**: Path to `Inbox/_processed/<archived-filename>` (use the timestamp-prefixed filename from step 9)
- **`## LaTeX`**: Populate with the full transcribed LaTeX/Markdown content from step 1
- **`## Why it matters`**: Analyze the content and explain the significance — is this a foundational technique, a practical application, a proof strategy?
- **`## Connections`**: Link to related concepts already in the knowledge base, mention broader mathematical domains it connects to

For non-image sources, use the appropriate template (`concept`, `source`, `entity`, `question`) based on content — never route by type-folder; `type` is frontmatter only.

### General template population

- Set `status: seed`
- Populate all frontmatter fields: `type`, `title`, `status`, `domain`, `created` (today's date), `updated` (today's date), `tags` (extracted from content), `related` (found via link matching), `sources` (original Inbox file path)
- Populate body sections based on extracted content

## 5. Navigate the MOC hierarchy

a. Read `Knowledge/<domain>/_moc-registry.md`.
b. Walk the tree from the domain-level MOC to find the deepest matching MOC for the note's content.
c. List the note under the best MOC heading in that MOC's body (create a `##` heading if needed). If no MOC fits, list under the domain-level MOC directly.
d. If the note is also relevant to MOCs in OTHER domains, cross-list it there (add under the MOC heading). The note file stays in its primary domain; only the MOC link crosses domains.
e. Update the Notes count in `_moc-registry.md` for each MOC touched.
f. If any MOC's count reaches 15, include a split proposal in the report (suggest 2–3 subtopic MOC names + which notes would move). Do NOT auto-create the new MOCs.

## 6. Cross-link

Add `[[wikilinks]]` to existing related notes in the body of the new note and update `related` frontmatter.

## 7. Update index

Update `Knowledge/_index.md` to reflect the new note (increment domain notes count, update status counts).

## 8. Check for contradictions

If a claim contradicts an existing note, add a `> [!contradiction]` callout in the new note describing the conflict.

## 9. Archive the source

Move the raw source file to `Inbox/_processed/` using a timestamp prefix:

```
YYYY-MM-DDTHH-mm-ss_original-filename.ext
```

For example: `2024-03-15T14-30-22_calculus-problem.jpg`

**Do NOT edit the file in place.** The archive move must preserve the original content unchanged — only rename with the timestamp prefix.

**For images**: After archiving, ensure the `image_source` frontmatter field in the created note points to the archived path: `Inbox/_processed/YYYY-MM-DDTHH-mm-ss_original-filename.ext`.

### 9a. Unreadable image handling

If an image cannot be transcribed (too blurry, not legible, not mathematical content):

1. **Still archive it**: Move to `Inbox/_processed/` with timestamp prefix as usual.
2. **Create a minimal math note** using `Templates/math.md` with:
   - `type: math`
   - `status: seed`
   - Body content:
     ```
     > [!warning] Transcription pending — image was unreadable.
     ```
   - `image_source` pointing to the archived path
3. Populate `title`, `domain`, `created`, `updated`, `tags`, and `sources` fields with best-effort metadata.
4. Continue normal processing (MOC placement, _index.md update, report).

**Never fail silently** — always create a note and always preserve the source image.

## 10. Report

Output a concise report:

- **Created**: list of new note files
- **Updated**: list of modified files
- **Source-archived**: the archived filename with path
- **Proposed-domain**: candidate domain (if any added to `_domains.md` Proposed)
- **MOC-placements**: which MOCs the note was listed under
- **Cross-listings**: MOCs in other domains where the note was cross-listed
- **Split-proposals**: any MOC split suggestions (if a registry hit 15)
- **Key insight**: one-line summary of the most important idea from the source

---

## Never

- Create a new domain folder unprompted
- Edit anything under `Inbox/_processed/`
- Delete a raw capture
- Duplicate a note already in `_index.md`
- Create a new MOC without proposing it first
- Fail silently on unreadable images — always create a note and preserve the source
