# Sprint 1 - Track 1: Substrate (Foundation)

**Owner:** substrate-engineer
**Branch:** feat/substrate
**Depends on:** nothing (first track)

## Scope

Create the vault skeleton from the TID §4 vault layout. Pure scaffolding: directories, templates, and stub files. No logic, no agents, no hooks.

## Tasks

### 1. Directory structure (§4 vault layout)

All directories from the vault layout. Each gets a .gitkeep so git tracks them:

Inbox/
Inbox/_processed/
Knowledge/math/
Knowledge/cs/
Knowledge/quant/
Daily/
Reviews/
Recaps/weekly/
Recaps/monthly/
Recaps/semester/
Goals/4year/
Goals/semester/
Goals/monthly/
Goals/weekly/
StudyMaterials/inbox/
StudyMaterials/active/
StudyMaterials/pdfs/
StudyMaterials/archive/
Templates/
.akasha/

Do NOT create .commandcode/, bin/, or AGENTS.md (harness track owns those).

### 2. Templates - 6 knowledge + 2 accountability (§5.1)

Each template has YAML frontmatter with required fields and body sections matching the TID spec.

**concept.md** - type: concept, fields: type, title, status: seed, domain, created, updated, tags, related, sources. Body: ## Definition, ## Why it matters, ## Connections.

**math.md** - type: math, same fields as concept plus image_source. Body: ## LaTeX, ## Why it matters, ## Connections.

**source.md** - type: source, same standard fields. Body: ## Summary, ## Key takeaways, ## Relevance.

**entity.md** - type: entity, same standard fields. Body: ## Definition, ## Significance, ## Connections.

**question.md** - type: question, same standard fields. Body: ## Question, ## Context, ## Possible answers.

**moc.md** - type: moc, standard fields PLUS moc_level (domain|topic|subtopic) and parent wikilink. Body is curated [[wikilinks]] grouped under ## headings. Empty initially.

**daily.md** - accountability template for Daily/. Frontmatter: date, energy (high|medium|low). Body: ## Top-3, ## Cascade Context, ## Suggestions, ## Carry-over, ## Notes. Includes fried-day fallback text.

**weekly.md** - accountability template for Reviews/. Frontmatter: week, created, status. Body: 5 review questions, ## Goal progress table, ## Start/Stop/Continue, ## Carried over.

### 3. Knowledge stubs (§5.0, §5.1)

- Knowledge/_index.md - Master index with sections: Domains (table), MOCs (flat list), Status (counts). Empty generated structure.
- Knowledge/_domains.md - Domain registry: Approved table (math, cs, quant with descriptions), Proposed section (empty). Agent column references _moc-registry.md.
- Knowledge/math/_moc-registry.md - MOC registry table: | MOC | Level | Parent | Notes | (empty, header only).
- Knowledge/cs/_moc-registry.md - Same empty table.
- Knowledge/quant/_moc-registry.md - Same empty table.

### 4. Accountability stubs (§5.4, §5.5)

- .akasha/hot.md - Content: "No data yet - first session."
- .akasha/streak.md - YAML frontmatter (streak_count: 0, longest_streak: 0, last_entry: ""). Body: | Date | Study | Move | Consume | Notes | (header only).

### 5. Goal stubs (§5.8)

- Goals/_not-doing.md - Sections: ## Dropped (table: Goal, Reason, Date), ## Rationale (free text).
- Goals/_goal-domain-map.md - | Goal | Domain | Subarea | (header only, empty).

### 6. .gitkeep files

Create empty .gitkeep in every directory to ensure git tracks the structure.

## Acceptance Criteria

- All directories from §4 exist and are tracked
- 8 templates in Templates/ with valid YAML frontmatter
- Knowledge/_index.md, Knowledge/_domains.md valid markdown
- _moc-registry.md in each domain folder with valid table
- .akasha/hot.md and .akasha/streak.md exist
- Goals/_not-doing.md, Goals/_goal-domain-map.md exist
- No .commandcode/, bin/, or AGENTS.md created (track boundary)
