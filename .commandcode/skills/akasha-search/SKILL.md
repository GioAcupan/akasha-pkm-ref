# /akasha-search — Query the knowledge base

Searches Knowledge for notes matching a topic string. Read-only, no side effects.

## Behavior

1. Delegates to the `akasha-query` agent in search mode
2. Takes a topic string argument (e.g., `/akasha-search linear algebra`)
3. Searches `Knowledge/` by default — `.md` files, looking in title, `[[wikilinks]]`, and body content
4. Ranks results: exact title matches first, then wikilink matches, then body content matches
5. Each result shows: note title, domain, status, and brief snippet with match context

## Output

Ranked list of matching notes:

```
### Results for "linear algebra"

1. **Linear Algebra MOC** (cs, moc) — 15 notes
   Map of Content for linear algebra topics

2. **Eigenvalues and Eigenvectors** (math, seed)
   ...eigenvalues, eigenvectors, characteristic polynomial...

3. **Gaussian Elimination** (math, seed)
   ...solving linear systems via Gaussian elimination...

N results
```

## Edge Cases

- **No results in Knowledge:** Offers to search `Inbox/` and `Inbox/_processed/`
- **No results anywhere:** "No notes found for this topic. Consider creating a seed note."
- **Very broad query (e.g., "math"):** Caps results at 20 and suggests narrowing: "Broad query — showing top 20 results. Try a more specific search term."
- **Multi-word query:** Searches for all terms, ranks by relevance (more term matches = higher)
- **Query with special chars:** Escapes regex-special characters before searching

## Usage

Type `/akasha-search <topic>` in any cmdc session within the vault.

## Output

- Read-only — no files written
- Results printed directly to the session
