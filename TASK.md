# Sprint 4 · Track 1 — Akasha Lint (vault hygyène checker)

> You are the agent for Track 1 of Sprint 4. You work in this worktree
> (`../akasha-lint`) on branch `feat/lint`. Stay on this branch.
> Do not switch to other branches, do not push, do not merge into main.
> When you finish, commit your final state and stop — the user runs the merge.

## Your goal

Build the `akasha-lint` agent and the `/akasha-lint` slash-command skill. The agent performs read-only hygyène checks on the vault. It reports issues — never auto-fixes. MOC hierarchy checks are part of its scope.

## Deliverables

- **`.commandcode/agents/akasha-lint.md`** — new agent definition
- **`.commandcode/skills/akasha-lint/SKILL.md`** — slash-command skill wrapping the agent

The agent must scan `Knowledge/` and `Daily/` and report:

**Basic checks:**
- Orphaned notes (no incoming `[[wikilinks]]`)
- Broken `[[wikilinks]]` (point to files that don't exist)
- Missing frontmatter fields (`type`, `title`, `status`, `domain`, `created`, `updated`)
- Empty body sections (for each note type's expected sections)
- `seed` notes older than 30 days (stale seeds)

**MOC hierarchy checks:**
- **Orphaned MOCs**: a MOC note that isn't listed in any parent MOC's body nor in any domain's `_moc-registry.md`
- **Registry drift**: a note with `type: moc` found on disk but not in its domain's `_moc-registry.md`, or a registry entry pointing to a file that doesn't exist
- **Overfull MOCs**: any MOC with 15+ direct notes listed in its body → flagged as a split candidate
- **Underfull MOCs**: any MOC with fewer than 3 notes → flagged as a merge candidate
- **Depth warnings**: MOC chains deeper than 4 levels from domain root → gentle nudge (not an error)

## Constraints

- Branch: stay on `feat/lint`. Do not push.
- Worktree: work inside `../akasha-lint`. Do not modify files outside this worktree.
- This agent is **report-only** — it produces a report, it never modifies files.
- The output is a categorized report with file paths and line numbers. Cap each category at 50 issues, with a count of remaining.
- Follow the existing agent file conventions (YAML frontmatter `name`, `description`, `tools`, body = system prompt). See `.commandcode/agents/akasha-ingest.md` for the format.
- Follow the existing skill file conventions (markdown with standard sections). See `.commandcode/skills/akasha-review/SKILL.md` for the format.
- Do not modify any source files outside your deliverables.
- Do not modify existing agents or skills — only add new ones.
- Commit convention: `akasha: <description>` (see auto-commit hook pattern).

## Dependencies on other tracks

None — this track is independent.

## Acceptance criteria

1. `.commandcode/agents/akasha-lint.md` and `.commandcode/skills/akasha-lint/SKILL.md` exist and follow the conventions of existing agents/skills.
2. The agent description and skill documentation describe a read-only hygyène scanner — no auto-fix behavior.
3. All six check categories (5 basic + 5 MOC hierarchy) are addressed in the agent's system prompt.
4. Each check type includes output format guidance (file path + line number where applicable).
5. The agent uses `tools: read_file, write_file, edit_file, glob, grep, shell_command, think` in its frontmatter (consistent with existing agents — `write_file`/`edit_file` included for potential future use, but the agent's system prompt states it's report-only).

## When you're done

1. Make sure all changes are committed on `feat/lint`.
2. Verify both files exist and are well-formed.
3. Stop. The user will run the sprint merge skill to integrate your work.

## Project conventions (excerpt)

- **Agent files**: `.commandcode/agents/<name>.md` — YAML frontmatter with `name`, `description`, `tools`, then system prompt body.
- **Skill files**: `.commandcode/skills/<name>/SKILL.md` — prose describing behavior, edge cases, usage, output.
- **Commit format**: `akasha: <description>` (consistent with auto-commit hook).
- **Slash commands**: Must be invokable as `/<name>` in any cmdc session in the vault.

---
*Generated for Sprint 4 · Track 1. Regenerate by re-running the sprint-worktree-tasks skill with the same spec.*
