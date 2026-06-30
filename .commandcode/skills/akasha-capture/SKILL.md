# Akasha Quick Capture

Append a quick typed note to the Inbox without opening Obsidian.

**When:** Anytime you have a fleeting thought, code snippet, or concept you want to capture from the terminal.

**Input:** Text content (e.g., `/akasha-capture "Zettelkasten: atomic notes, one idea each, linked by wikilinks"`).

**Process:**
1. Accept the text content provided by the user.
2. If the Inbox/ directory does not exist, create it first.
3. Generate a timestamp-based filename: YYYY-MM-DDTHH-mm-ss.md. If a file with that exact name already exists, append -2, -3, etc. to the seconds part.
4. Create the file with minimal YAML frontmatter:
   ```markdown
   ---
   date: YYYY-MM-DDTHH:mm:ss
   status: seed
   ---
   
   <captured text content>
   ```
5. Write the file to Inbox/<filename>.md
6. Confirm to the user: "Captured to Inbox/<filename>.md"

**Edge cases:**
- Empty input → prompt for content, do NOT create an empty file.
- Multi-line text → preserve all line breaks and formatting as-is.
- Inbox directory doesn't exist → create it before writing the file.
- Filename collision (same second) → append -2, -3 suffix to avoid overwriting.

**Output:** Confirmation with the filename.

**Integration:** The captured file will be processed by the akasha-ingest agent during the next `/akasha-nightly` run — no special handling needed.
