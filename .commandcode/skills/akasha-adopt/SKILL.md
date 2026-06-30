# Akasha Vault Migration

Migrate an existing Obsidian vault into Akasha structure. One-time, non-destructive, reversible via git.

**When:** Once, when setting up Akasha with an existing vault that has `1- Rough Notes/`, `2- Source Material/`, `3 - Tags/`, `4 - Indexes/`, and `5 - Templates/` folders.

**Process:**

1. **Scan** — The agent reads the vault structure and produces a folder→target mapping report, mapping `4 - Indexes/` files to domain folders (cs/, math/, quant/, humanities/, entities/). Seeds `Knowledge/_domains.md` from this mapping. Skip Organization.md.

2. **Infer Tag Hierarchy** — The agent reads all tags in `3 - Tags/`, analyzes link patterns between tags and rough notes, and produces a hierarchy proposal table:

   | Tag | → MOC Name | moc_level | Parent | Domain | Notes that reference it |
   |-----|-----------|-----------|--------|--------|------------------------|

   The agent stops here for your confirmation. Nothing is moved yet.

3. **Create MOCs** (on your approval) — Each tag becomes a MOC note with proper frontmatter, placed in its domain folder. `_moc-registry.md` is created per domain. Cross-referenced MOCs are linked.

4. **Migrate Notes** — Rough notes move to domain folders with frontmatter backfilled, listed under the deepest matching MOC. Source material becomes `type: source` notes. All `[[wikilinks]]` preserved as-is.

5. **Merge Templates** — `5 - Templates/` merged into `Templates/`. Existing Akasha templates never overwritten.

6. **Report** — Full summary: domains created, MOCs created per level, notes migrated per domain, cross-listings, items needing manual review, ambiguous tag placements.

**Input:** None — scans the current vault automatically.

**Output:** Multi-step interactive — proposal table first, then migration on confirmation.

**Edge cases:**
- Already adopted → detects existing Akasha structure and warns
- Partial migration → can resume from where it left off (checks what's moved)
- Ambiguous tag hierarchy → flagged in proposal with "needs review" marker

**Guarantee:** Non-destructive. Atomic note bodies never rewritten — only missing frontmatter backfilled. Templates never overwritten. Each step is a separate git commit for full reversibility.
