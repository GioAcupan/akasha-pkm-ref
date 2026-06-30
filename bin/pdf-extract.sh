#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: pdf-extract.sh <mode> <pdf-file>"
    echo "  toc  - Extract table of contents (bookmarks/outline) as JSON"
    echo "  text - Extract full text to stdout"
    exit 1
}

[ $# -ne 2 ] && usage
MODE="$1"
PDF="$2"

[ -f "$PDF" ] || { echo "Error: $PDF not found" >&2; exit 1; }

case "$MODE" in
    toc)
        # Try pymupdf first (best bookmark extraction)
        if python3 -c "import fitz" 2>/dev/null; then
            python3 -c "
import fitz, json, sys
doc = fitz.open('$PDF')
toc = doc.get_toc(simple=False)
if not toc:
    print('[]')
    sys.exit(0)
entries = []
for entry in toc:
    level, title, page, *_ = entry
    entries.append({'level': level, 'title': title.strip(), 'page': page})
print(json.dumps(entries, indent=2))
"
        else
            # Fallback: pdftotext with layout, grep for TOC-like patterns
            echo '{"error":"pymupdf not installed. Install with: pip install pymupdf","fallback":"use text mode instead"}' >&2
            exit 1
        fi
        ;;
    text)
        if command -v pdftotext >/dev/null 2>&1; then
            pdftotext -layout "$PDF" -
        else
            echo "Error: pdftotext not found. Install poppler-utils." >&2
            exit 1
        fi
        ;;
    *)
        usage
        ;;
esac
