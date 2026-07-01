# Confidence Thresholds

## Canvas
- Node count < 3 -> LOW (too sparse to represent a meaningful diagram)
- All node texts are empty or "[?]" -> LOW
- More than 50% of nodes have "[?]" content -> LOW
- All nodes at the same coordinates -> LOW (failed to parse layout)
- Node count > 30 -> FLAG (may be too dense, but still valid)

## Mermaid
- Fewer than 2 node declarations -> LOW (not a real diagram)
- Edge references to non-existent node IDs -> FAIL (linter will catch)
- All node labels are "[unreadable]" -> LOW
- No diagram type declaration -> FAIL

## General
- Vision LLM output contains "I cannot", "I'm unable", "cannot read" -> FAIL
- Output is empty or whitespace-only -> FAIL
- Output is valid but describes the image metadata instead of transcribing -> LOW
