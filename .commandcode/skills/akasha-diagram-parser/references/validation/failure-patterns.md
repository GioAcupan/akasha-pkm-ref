# Failure Patterns

## Common garbage Canvas output
1. **Single giant node** — LLM puts all text into one node instead of splitting by bubble
2. **No edges** — LLM describes nodes but doesn't connect them
3. **All nodes at (0,0)** — LLM fails to extract positional layout
4. **Overlapping coordinates** — Multiple nodes at the same position
5. **Prose description disguised as Canvas** — LLM writes {"nodes": [{"text": "This is a diagram showing..."}]} in a single node
6. **Malformed IDs** — IDs that are not 16-char hex (will be caught by linter)

## Common garbage Mermaid output
1. **Wrong diagram type** — LLM uses `graph` instead of `flowchart`, or `sequence` instead of `sequenceDiagram`
2. **Inline text before diagram declaration** — Prose explanation before the ```mermaid delimiter
3. **Unclosed brackets** — Node labels with `[` but no `]`, or `{` without `}`
4. **Special characters in labels** — Curly braces `{}` inside node texts (breaks Mermaid rendering)
5. **Nested code blocks** — ```mermaid inside another code block
