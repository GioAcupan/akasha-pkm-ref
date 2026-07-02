# Reference Adaptation — Ingest Quality, Health, Session, & Review

**Date:** 2026-07-02
**Status:** Seed
**Source repos:** `obsidian-skills` (Steph Ango), `claude-obsidian` (AgriciDaniel), `obsidian-claude-pkm` (ballred)

---

## Summary

Three self-contained packages that tighten the Akasha core loop by adapting patterns from the three reference repos. No new subsystems, no scope creep — only output quality and UX improvements on existing infrastructure.

---

## Package A: Ingest Quality

### A1 — Defuddle skill

New file: `.commandcode/skills/akasha-defuddle/SKILL.md`

Instructions:
- When the ingest pipeline receives a URL as source, use `npx defuddle parse <url> --md` to extract clean readable markdown
- defuddle strips navigation, ads, sidebars, and comments — saving tokens and improving content quality
- Uses `npx defuddle` — no global install needed. npx auto-downloads and caches.
- Falls back to `web_fetch` if defuddle errors or returns empty output

Modification to `akasha-ingest` agent: one behavior line added — "when source is a URL, invoke `akasha-defuddle` to get clean markdown before processing."

Source: `docs_and_references/reference-repos/obsidian-skills/skills/defuddle/SKILL.md`

### A2 — Obsidian Flavored Markdown reference

New file: `.commandcode/references/obsidian-flavored-markdown.md`

A single comprehensive reference doc ported from the official repo covering all Obsidian Flavored Markdown syntax that Akasha agents produce:
- **Frontmatter** — required fields, quoting rules for values with colons
- **Wikilinks** — `[[Note]]`, `[[Note|display]]`, `[[Note#Heading]]`, `[[Note#^block-id]]`, `[[#heading]]`
- **Embeds** — `![[note]]`, `![[note#section]]`, `![[image.png|300]]`, `![[doc.pdf#page=3]]`
- **Callouts** — all 13+ types with aliases: note, tip, warning, info, example, quote, bug, danger, success, failure, question, abstract, todo. Foldable variants (`> [!faq]-` collapsed, `> [!faq]+` expanded). Nesting.
- **Tags** — inline vs frontmatter
- **Comments** — `%%hidden text%%`
- **Highlights** — `==highlighted==`
- **Math** — `$inline$` and `$$block$$` with LaTeX
- **Footnotes** — `[^1]` and `[^1]: definition`
- **Mermaid** — basic diagram types

Modification to `AGENTS.md`: one line appended to startup — "All agents produce valid Obsidian Flavored Markdown per the reference doc."

Source: `docs_and_references/reference-repos/obsidian-skills/skills/obsidian-markdown/SKILL.md` and `references/`

---

## Package B: Health & Session Continuity

### B1 — wiki-lint upgrade

Modification to `.commandcode/agents/akasha-lint.md`

Current: checks 10 categories (orphans, broken links, missing frontmatter, empty sections, stale seeds, orphaned MOCs, registry drift, overfull/underfull MOCs, depth warnings). Unstructured report format.

Upgrades:
- **Stale claim detection**: grep notes for claims without `source:` or `via:` frontmatter — flags notes that assert something unbacked. New section in report: `## 8. Unbacked claims (no source/via)`
- **Structured summary banner**: add `## Summary: X issues across Y categories` at top of report (computed after all sections)
- **Stale seed age column**: add `Age (days)` column to section 5 so you see how stale each seed is
- **Stale seed threshold clamp**: only flag seeds older than 30 days, but show age up to 999+ days for visibility

No new tools or structural changes. Read-only remains enforced.

Source: `docs_and_references/reference-repos/claude-obsidian/skills/wiki-lint/SKILL.md` (report format pattern, stale-claim detection concept)

### B2 — Hot cache formalization

Modification to `AGENTS.md` startup section and `.commandcode/agents/akasha-daily.md`

AGENTS.md change:
```
## Startup
1. Read `.akasha/hot.md` — ≤500 tokens. Establishes active context.
2. Read `Knowledge/_domains.md` — ≤1000 tokens. Establishes domain landscape.
3. Read 3-5 specific pages relevant to today's work — ≤300 tokens each.
Total pre-work: ≤3000 tokens before executing any user request.
```

akasha-daily change: when writing `.akasha/hot.md`, include only:
- Active streak (from `.akasha/streak.md`)
- Current goals cascade summary (from `Goals/` files)
- Yesterday's top-3 deliverables and one-line reflection
- Current inbox count
- ONE Big Thing for today

No dump of full session logs, file listings, or raw command output.

Source: `docs_and_references/reference-repos/claude-obsidian/skills/wiki/SKILL.md` (hot cache reading protocol)

### B3 — Session-init hook

New file: `.commandcode/hooks/SessionStart.sh`
Registration: `.commandcode/settings.json` → `hooks.SessionStart`

A bash script (Git Bash on Windows) that runs at session start and outputs a context injection block:

```
# Session Context — 2026-07-02 (Thursday)
Daily: ✅ today's note exists
Weekly: 4 days since last review
Streak: 12 days (study ✅ move ✅ consume ✅)
Inbox: 3 pending
Active material: "Linear Algebra Done Right" (ch.4)
```

The script reads:
- `Daily/YYYY-MM-DD.md` existence → daily status
- Latest `Reviews/YYYY-W*.md` filename → days since last weekly
- `.akasha/streak.md` → streak length and floor status
- `Inbox/*.md` count (excluding `_processed/`) → inbox load
- `StudyMaterials/active/*.md` → active materials list (max 3)

Compiled to stdout. SessionStart hooks inject stdout into the system context automatically (advisory, non-blocking).

---

## Package C: Review & Cascade Completion

### C1 — Review smart router

New file: `.commandcode/skills/akasha-review/SKILL.md`

A routing skill that reads the current date/time and dispatches to the appropriate agent:

| Condition | Route |
|-----------|-------|
| Before 12:00 (any day) | `/akasha-daily` scaffold (morning set-up) |
| After 18:00, Mon-Thu | `/akasha-daily` evening reflection |
| Friday 18:00 – Sunday 23:59 | `/akasha-weekly` full review |
| Last 3 days of any month | `/akasha-recap monthly` (takes priority over weekly on conflict) |

Edge cases:
- **Month end + Friday overlap**: monthly recap takes priority, weekly gets postponed
- **No daily note yet**: morning route creates one, evening route prompts first
- **Already reviewed this week**: skill detects existing weekly file for current week, asks before re-running
- **First-time user**: if no daily/weekly files exist at all, defaults to morning daily scaffold with setup guidance

No new agents. The skill invokes existing agents via the task tool.

### C2 — Forward monthly planning

Modification to `.commandcode/agents/akasha-recap.md`

Current: backward-looking only. Reads scratch file, produces recap, proposes 3 biggest-win candidates.

Upgrade: after the backward-looking recap, the agent:
1. Reads the current month's `Goals/monthly/*.md` — finds Must/Should/Nice
2. Cross-references with Recap scratch data — identifies which deliverables completed, slipped, or over-performed
3. Proposes next month's Must/Should/Nice deliverables inline (e.g., "Based on this month, should we carry over 'Complete chapter 5' to next month's Must?")
4. User confirms or tweaks via conversation
5. If confirmed, writes new `Goals/monthly/YYYY-MM.md` with the proposed Must/Should/Nice
6. If no monthly goals exist yet (first month), proposes from scratch based on semester goals

### C3 — Skill-discovery hook

New file: `.commandcode/hooks/Stop.sh` (or append to existing Stop configuration)
Registration: `.commandcode/settings.json` → `hooks.Stop`

Uses the `Stop` event (fires when assistant finishes a turn, can force revision). The hook:
1. Reads the user's last message from stdin (JSON payload)
2. Checks for trigger keywords: `help`, `skills`, `what can you do`, `commands`, `available`
3. Anti-spam: tracks last trigger time in `.commandcode/.skill-discovery-cache` — only triggers if 3+ turns have passed since last injection
4. On match: injects a compact listing of `/akasha-*` commands:

```
Available Akasha commands:
  /akasha-review    — Smart router: daily/weekly/monthly
  /akasha-ingest    — Process one inbox item
  /akasha-lint      — Vault hygiene report (read-only)
  /akasha-query     — Search or status dashboard
  /akasha-daily     — Scaffold today's daily note
  /akasha-weekly    — Weekly review ritual
  /akasha-recap     — Period recap (weekly/monthly/semester)
  /akasha-capture   — Quick seed note creation
  /akasha-goal-set  — Create goals at any cascade level
  /akasha-goal-check— Audit goals vs recent activity
  /akasha-search    — Search knowledge base
```

The hook uses the Stop event's force-revision mechanism (up to 3 retries) to inject the listing as a system message, then exits cleanly. No revision if no trigger matched.

Trigger-only — never blocks unrelated messages. The keyword set is deliberately small to avoid false positives.

---

## Files Changed Summary

| File | Action |
|------|--------|
| `.commandcode/skills/akasha-defuddle/SKILL.md` | **Create** |
| `.commandcode/references/obsidian-flavored-markdown.md` | **Create** |
| `.commandcode/skills/akasha-review/SKILL.md` | **Create** |
| `.commandcode/hooks/SessionStart.sh` | **Create** |
| `.commandcode/hooks/Stop.sh` | **Create** |
| `.commandcode/agents/akasha-lint.md` | **Edit** (report format, stale claims) |
| `.commandcode/agents/akasha-daily.md` | **Edit** (hot.md writer instructions) |
| `.commandcode/agents/akasha-recap.md` | **Edit** (forward planning pass) |
| `.commandcode/agents/akasha-ingest.md` | **Edit** (defuddle integration) |
| `AGENTS.md` | **Edit** (hot cache protocol, OFM production) |
| `.commandcode/settings.json` | **Edit** (SessionStart and Stop hook registration) |

All changes are additive or modifications to existing agent prompts. No agents removed, no architecture changed.
