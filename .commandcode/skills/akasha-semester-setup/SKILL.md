# /akasha-semester-setup — New semester initialization

Archives previous semester materials and sets up a new term. Multi-step interactive process — non-destructive, files move to archive (not deleted).

## Behavior

1. Takes term name argument (e.g., `2027-spring`)
2. Archives previous semester:
   - Runs headless `cmd` with `bin/prompts/semester-archive.md`
   - Moves `StudyMaterials/active/*.md` → `StudyMaterials/archive/<previous-term>/active/`
   - Moves `StudyMaterials/pdfs/*.pdf` → `StudyMaterials/archive/<previous-term>/pdfs/`
   - Updates material note statuses to `archived`
   - Updates previous semester goal status to `completed`
3. Reads 4-year vision + last semester's goal for context
4. Asks: "What's the focus this term? Course load? Materials?"
5. If PDFs exist in `StudyMaterials/inbox/`: offers to run `/akasha-material-ingest` for each
6. Creates semester goal file via `/akasha-goal-set semester <term>`
7. Generates first monthly goal with Must/Should/Nice deliverables

## Usage

```
/akasha-semester-setup <term>
```

Example:
```
/akasha-semester-setup 2027-spring
```

## Flow

```
Archive previous → Read vision → Prompt for focus → Ingest materials → Create semester goal → Create first monthly
```

## Edge Cases

- **No previous semester:** Skips archive step entirely — just creates fresh
- **Previous semester not completed:** Warns about unfinished goals, asks which to carry forward vs. drop. Carried-forward goals get `status: active` in new semester.
- **Summer term:** Same flow — just a lighter expected load. Term name like `2027-summer`.
- **No PDFs in inbox:** Skips material ingestion step — user can run `/akasha-material-ingest` later
- **Semester goal already exists:** "Semester goal for <term> already exists. Update it instead?" — delegates to `/akasha-goal-set`

## Output

Reports each step:
```
## Semester Setup — 2027-spring

### Archive
- Archived: 2026-fall (3 materials, 4 PDFs)
- Previous semester status: completed

### Vision
- 4-year vision: Active (academic focus: math + CS foundations)

### New Term
- Semester goal: Goals/semester/2027-spring.md
- First monthly: Goals/monthly/2027-01.md
- Materials ingested: 2 (Linear Algebra, Algorithms)
- Materials in inbox: 1 pending
```

## Depends on

- `/akasha-material-ingest` — for PDF → structured TOC
- `/akasha-goal-set semester` — for creating semester goal file
- `/akasha-goal-set monthly` — for first monthly goal
- `bin/prompts/semester-archive.md` — headless archive execution
