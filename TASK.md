# Sprint 2.5 — Adopt Existing Vault (One-Shot Migration)

**Owner:** pipeline-engineer
**Branch:** feat/adopt
**Depends on:** Sprint 2 (needs akasha-ingest agent to exist)

## Scope

Build the `akasha-adopt` agent and `/akasha-adopt` skill. This is a one-time, non-destructive migration that folds the existing vault's structure into Akasha. The existing vault has folders `1- Rough Notes/` (76 files), `2- Source Material/` (9 files), `3 - Tags/` (32 hub notes), `4 - Indexes/` (7 empty domain files), and `5 - Templates/` (existing templates to merge).

## Tasks

### 1. Create `akasha-adopt` agent (§5.6)

Create `.commandcode/agents/akasha-adopt.md` with the full migration protocol:

- **YAML frontmatter:** name, description, tools: read_file, write_file, edit_file, glob, grep, shell_command, think
- **Body:** The full 7-step migration protocol from §5.6:
  1. **SCAN** — map `4 - Indexes/` files to Akasha domains (cs/, math/, quant/, humanities/, entities/). Skip Organization.md (PARA-like). Seed `_domains.md`.
  2. **INFER TAG HIERARCHY** — for each of the 32 tags in `3 - Tags/`: read referenced rough notes, detect child-like relationships, determine domain, propose moc_level and parent. Produce a **proposal table** (Tag | MOC Name | moc_level | Parent | Domain | Notes that reference it) and STOP for confirmation. Nothing moves until confirmed.
  3. **CREATE MOCs** (on approval) — convert each tag to MOC note with moc_level/parent/domain frontmatter, place in domain folder, populate with note links, create `_moc-registry.md` per domain, link cross-referenced MOCs.
  4. **MIGRATE NOTES** — for each rough note: determine domain, backfill frontmatter, place in domain folder, list under deepest MOC, cross-list if relevant, preserve all `[[wikilinks]]`.
  5. **MIGRATE SOURCE MATERIAL** — `2- Source Material/` → `type: source` notes, frontmatter backfilled.
  6. **MERGE TEMPLATES** — `5 - Templates/` → `Templates/`, never overwrite existing Akasha templates.
  7. **REPORT** — domains/mocs created, notes migrated, cross-listings, ambiguous tags, items needing manual review.

### 2. Create `/akasha-adopt` skill (§5.7)

Create `.commandcode/skills/akasha-adopt/SKILL.md`:

- Standard cmdc skill format
- **When:** Once, when setting up Akasha with an existing vault
- **Input:** Scans current vault structure
- **Output:** Multi-step interactive process — folder mapping report, tag hierarchy proposal table (stop for confirmation), then migration execution
- **Behavior:** Non-destructive, reversible via git, never rewrites note bodies, never overwrites templates
- **Edge cases:** Already adopted → warns; partial migration → can resume

### 3. Guardrails

- Never rewrite the body of an existing atomic note
- Never overwrite a template
- Never proceed past step 2 (proposal table) without explicit confirmation
- Never create MOCs without showing the hierarchy proposal first
- Migration is incremental (each step a separate git commit for reversibility)
- Tags with ambiguous hierarchy flagged as "needs review"

## Acceptance Criteria (§8)

- Dry run produces folder→target mapping report, changes nothing
- Agent infers tag hierarchy from link patterns and produces proposal table
- Proposal table stops for explicit user confirmation
- On approval: existing vault notes land in Akasha with frontmatter backfilled
- `4 - Indexes/` → domain-level MOCs (`moc_level: domain`)
- `3 - Tags/` → topic/subtopic MOCs with inferred hierarchy
- `_moc-registry.md` seeded for each domain
- Templates merged, none overwritten
- `_domains.md` seeded from index files
- All reversible via git, no atomic-note bodies rewritten
- `/akasha-adopt` is invokable as a slash command
