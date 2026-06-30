Archive the previous semester's study materials.

## Process

1. **Determine the previous term.** Read `Goals/semester/` for the most recently active semester goal. Extract `term:` from its frontmatter (e.g., "2026-fall").

2. **Archive active materials.** Move all `.md` files from `StudyMaterials/active/` to `StudyMaterials/archive/<previous-term>/active/`. Create the target directory if needed.

3. **Archive PDFs.** Move all `.pdf` files from `StudyMaterials/pdfs/` to `StudyMaterials/archive/<previous-term>/pdfs/`. Create the target directory if needed.

4. **Update material notes.** For each moved `.md` file in the archive, update `status:` from `active` to `archived` in the frontmatter. Do not modify the body content.

5. **Update semester goal.** In the previous semester's goal file, update `status:` from `active` to `completed` (or leave as `active` if the user wants to carry things forward).

6. **Report:** Term archived, files moved, material notes updated, semester goal status.
