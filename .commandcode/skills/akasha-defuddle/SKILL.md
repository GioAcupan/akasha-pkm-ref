# Defuddle — Web Page to Clean Markdown

A utility skill for the Akasha ingest pipeline. Converts web page URLs to clean, readable markdown by stripping navigation, ads, and clutter.

## When to use

Invoke this skill when the ingest pipeline encounters a URL as source material. Do NOT use for `.md` files, PDFs, or other direct document URLs — those use `web_fetch` or `akasha-material-parser` directly.

## Workflow

1. **Try defuddle** — Run `npx defuddle parse <url> --md`. npx auto-downloads and caches the package; no global install needed.
2. **On success** — Pipe the markdown output back to the calling agent for processing.
3. **On failure** — If defuddle errors (network error, empty output, or non-page URL), fall back to `web_fetch <url>` directly.

## Flags reference

| Flag | Purpose |
|------|---------|
| `--md` | Output as markdown (default when -o omitted) |
| `--json` | Output structured JSON (title, description, content, byline, siteName, domain) |
| `-o file.md` | Write to file instead of stdout |
| `-p title` | Extract a specific field (use --json to see available fields) |

## Examples

```bash
# Write to stdout as markdown
npx defuddle parse https://example.com/article --md

# Save to file
npx defuddle parse https://example.com/article -o /tmp/article.md

# Get structured JSON
npx defuddle parse https://example.com/article --json
```

## Note

Defuddle handles most blog posts, documentation pages, and news articles. It may struggle with JavaScript-heavy SPAs or login-walled pages — fall back to `web_fetch` in those cases.
