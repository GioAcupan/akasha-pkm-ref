# Sprint 1 - Track 1: Substrate Implementation Plan

**Plan:** `docs/superpowers/plans/sprint-1-track-substrate.md`
**Source:** TASK.md (feat/substrate)

## Task 1: Create directory structure

- [ ] Create `Inbox/` directory with `.gitkeep`
- [ ] Create `Inbox/_processed/` directory with `.gitkeep`
- [ ] Create `Knowledge/` directory with `.gitkeep`
- [ ] Create `Knowledge/math/` directory with `.gitkeep`
- [ ] Create `Knowledge/cs/` directory with `.gitkeep`
- [ ] Create `Knowledge/quant/` directory with `.gitkeep`
- [ ] Create `Daily/` directory with `.gitkeep`
- [ ] Create `Reviews/` directory with `.gitkeep`
- [ ] Create `Recaps/` directory
- [ ] Create `Recaps/weekly/` directory with `.gitkeep`
- [ ] Create `Recaps/monthly/` directory with `.gitkeep`
- [ ] Create `Recaps/semester/` directory with `.gitkeep`
- [ ] Create `Goals/` directory
- [ ] Create `Goals/4year/` directory with `.gitkeep`
- [ ] Create `Goals/semester/` directory with `.gitkeep`
- [ ] Create `Goals/monthly/` directory with `.gitkeep`
- [ ] Create `Goals/weekly/` directory with `.gitkeep`
- [ ] Create `StudyMaterials/` directory
- [ ] Create `StudyMaterials/inbox/` directory with `.gitkeep`
- [ ] Create `StudyMaterials/active/` directory with `.gitkeep`
- [ ] Create `StudyMaterials/pdfs/` directory with `.gitkeep`
- [ ] Create `StudyMaterials/archive/` directory with `.gitkeep`
- [ ] Create `Templates/` directory with `.gitkeep`
- [ ] Create `.akasha/` directory with `.gitkeep`

## Task 2: Create knowledge templates (6 files)

- [ ] Create `Templates/concept.md` - YAML frontmatter (type, title, status:seed, domain, created, updated, tags, related, sources) + body sections (Definition, Why it matters, Connections)
- [ ] Create `Templates/math.md` - Same as concept + image_source field + body sections (LaTeX, Why it matters, Connections)
- [ ] Create `Templates/source.md` - Standard frontmatter + body sections (Summary, Key takeaways, Relevance)
- [ ] Create `Templates/entity.md` - Standard frontmatter + body sections (Definition, Significance, Connections)
- [ ] Create `Templates/question.md` - Standard frontmatter + body sections (Question, Context, Possible answers)
- [ ] Create `Templates/moc.md` - Standard frontmatter + moc_level (domain|topic|subtopic) + parent wikilink + empty body (## Notes heading)

## Task 3: Create accountability templates (2 files)

- [ ] Create `Templates/daily.md` - Frontmatter (date, energy:high|medium|low) + body sections (Top-3, Cascade Context, Suggestions, Carry-over, Notes) with fried-day fallback text
- [ ] Create `Templates/weekly.md` - Frontmatter (week, created, status) + body (5 review questions, Goal progress table, Start/Stop/Continue, Carried over)

## Task 4: Create Knowledge stubs

- [ ] Create `Knowledge/_index.md` - Master index: Domains table (Domain | Folder | MOC Registry | Notes), MOCs flat list, Status counts. Empty generated structure.
- [ ] Create `Knowledge/_domains.md` - Domain registry: Approved table (math/cs/quant) + Proposed section. Each domain maps to _moc-registry.md.
- [ ] Create `Knowledge/math/_moc-registry.md` - Table: | MOC | Level | Parent | Notes | (header only)
- [ ] Create `Knowledge/cs/_moc-registry.md` - Same empty table
- [ ] Create `Knowledge/quant/_moc-registry.md` - Same empty table

## Task 5: Create accountability stubs

- [ ] Create `.akasha/hot.md` - Content: "No data yet — first session."
- [ ] Create `.akasha/streak.md` - YAML frontmatter (streak_count:0, longest_streak:0, last_entry:"") + body: table header | Date | Study | Move | Consume | Notes |

## Task 6: Create goal stubs

- [ ] Create `Goals/_not-doing.md` - ## Dropped table (Goal, Reason, Date) + ## Rationale
- [ ] Create `Goals/_goal-domain-map.md` - | Goal | Domain | Subarea | (header only)

## Task 7: Verification

- [ ] Verify all directories exist and are populated
- [ ] Verify all 8 templates have valid YAML frontmatter
- [ ] Verify _index.md and _domains.md are valid markdown
- [ ] Verify _moc-registry.md tables parse correctly
- [ ] Verify .akasha/ files exist with correct content
- [ ] Verify Goals/ stubs exist
- [ ] Verify no .commandcode/, bin/, or AGENTS.md was created
