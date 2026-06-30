# Sprint 2.5 — Adopt Existing Vault Plan

**Plan:** `docs/superpowers/plans/sprint-2.5-track-adopt.md`
**Source:** TASK.md (feat/adopt)
**Depends on:** Sprint 2 complete

## Task 1: Create akasha-adopt agent

- [ ] Create `.commandcode/agents/akasha-adopt.md` with YAML frontmatter (name, description, tools list)
- [ ] Implement Step 1 (SCAN): map `4 - Indexes/` files to Akasha domains, seed `_domains.md`, skip Organization.md
- [ ] Implement Step 2 (INFER): for each tag in `3 - Tags/`, read referenced notes, detect parent-child relationships, determine domain and moc_level, produce proposal table, STOP for confirmation
- [ ] Implement Step 3 (CREATE MOCs): on approval, convert tags to MOC notes with hierarchy, create `_moc-registry.md` per domain, link cross-references
- [ ] Implement Step 4 (MIGRATE NOTES): domain detection, frontmatter backfill, placement in domain folder, MOC listing, cross-listing
- [ ] Implement Step 5 (MIGRATE SOURCES): `2- Source Material/` → `type: source` with frontmatter
- [ ] Implement Step 6 (MERGE TEMPLATES): `5 - Templates/` → `Templates/`, never overwrite
- [ ] Implement Step 7 (REPORT): domains/MOCs/notes/ambiguous tags/manual review items

## Task 2: Create /akasha-adopt skill

- [ ] Create `.commandcode/skills/akasha-adopt/SKILL.md`
- [ ] Document when to use, input, output
- [ ] Document multi-step interactive process with confirmation gate
- [ ] Document edge cases: already adopted, partial migration
- [ ] Document non-destructive guarantee

## Task 3: Guardrails

- [ ] Verify agent never rewrites atomic note bodies (only backfills missing frontmatter)
- [ ] Verify agent never overwrites existing Akasha templates
- [ ] Verify agent stops at proposal table before any file moves
- [ ] Verify agent flags ambiguous hierarchy placements
- [ ] Verify incremental commits for reversibility

## Task 4: Commit

- [ ] Commit to feat/adopt with message: "akasha: Sprint 2.5 — one-shot vault migration (akasha-adopt agent + /akasha-adopt skill)"
