# /akasha-lint -- Vault hygiene check

Runs the `akasha-lint` agent for read-only health checks on the vault. Reports issues across 10 check categories -- never auto-fixes.

## Behavior

1. Delegates to the `akasha-lint` agent
2. Agent scans `Knowledge/` and `Daily/`
3. Produces a categorized report grouped by issue type
4. Each issue includes file path and line number where applicable
5. Output is capped at 50 issues per type, with a count of remaining

## Check categories

**Basic checks:**
- Orphaned notes -- notes with no incoming `[[wikilinks]]`
- Broken `[[wikilinks]]` -- links pointing to files that don't exist
- Missing frontmatter -- required fields (`type`, `title`, `status`, `domain`, `created`, `updated`) absent
- Empty body sections -- sections expected by the note type are empty
- Stale seeds -- `seed` notes older than 30 days

**MOC hierarchy checks:**
- Orphaned MOCs -- MOC note not listed in any parent MOC body or registry
- Registry drift -- MOC in filesystem but not registry, or registry entry with no file
- Overfull MOCs -- 15+ direct notes listed in body (split candidate)
- Underfull MOCs -- fewer than 3 notes (merge candidate)
- Depth warnings -- MOC chains deeper than 4 levels

## Output

Categorized markdown report, grouped by check type. Clean vault -> No issues found.

## Edge Cases

- **Clean vault:** No issues found. -- no error
- **Many issues:** Capped at 50 per type, with X more not shown count
- **No MOCs:** MOC hierarchy checks silently skipped
- **No registries:** Registry drift check reports no registries found as info, not error
- **No dailies:** Basic checks run on `Knowledge/` only

## Usage

Type `/akasha-lint` in any cmdc session within the vault.

## Output

- Report printed to the session -- no files written
- Read-only -- no changes to the vault
