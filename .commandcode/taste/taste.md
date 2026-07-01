# Taste (Continuously Learned by [CommandCode][cmd])

[cmd]: https://commandcode.ai/

# init
- When initializing from a TID/design document, do NOT execute the full build (directories, templates, files). Instead, create only the AGENTS.md bootstrap file and a plan. Confidence: 0.75

# workflow
- Wrap any automated/scripted process in a skill (via commandcode agent or prompt) rather than instructing the user to run shell commands manually. Confidence: 0.85
- Systematically audit all workflow operations to ensure comprehensive skill coverage — every agent invocation, manual file operation, and shell command should be accessible as a cmdc skill, not just isolated processes. Confidence: 0.70
- When executing implementation plans, prefer subagent-driven execution (fresh subagent per task, review between tasks) over inline execution in the current session. Confidence: 0.70
- When adapting existing skill reference repositories, port all available reference documents by default rather than selecting a conservative subset. Confidence: 0.70

# note-organization
- Use domain-level folders only (e.g., Knowledge/math/, Knowledge/cs/) with topic/subtopic hierarchy expressed through agent-maintained MOC/index notes, never physical subdirectories below the domain level. Confidence: 0.75
- Use a recursive MOC hierarchy with explicit level tracking (not fixed depth) — any MOC can nest another MOC, and the agent follows a clear protocol for creating/maintaining additional layers. Maintain a MOC registry file per domain or per Knowledge root for tracking the hierarchy. Confidence: 0.70
- Notes must remain freely linkable across MOCs without restriction — MOCs are navigational aids that provide hierarchy, not boundaries that limit cross-MOC wikilinks. The system is a wiki (not a tree), and linking patterns must never be constrained by MOC placement. Confidence: 0.65
- Use type: source for book/reference hub notes that link to derived atomic notes — a source note acts as a personal reference hub (with author, status, rating metadata) but is invisible to the MOC machinery (no registry entry, no lint checking, no split proposals). Books are private reference attachments, not navigational MOCs. The book is where you found the idea, not what the idea is. Confidence: 0.70

# workflow
- Wrap any automated/scripted process in a skill (via commandcode agent or prompt) rather than instructing the user to run shell commands manually. Confidence: 0.85
- Systematically audit all workflow operations to ensure comprehensive skill coverage — every agent invocation, manual file operation, and shell command should be accessible as a cmdc skill, not just isolated processes. Confidence: 0.70
- During weekend rituals, run recap (automated snapshot of what happened) before review (reflective 5-question ritual) as separate sequential steps, not merged into a single command. Confidence: 0.55
- Use a hybrid trigger for periodic recaps: nightly silently appends raw data to a running scratch file, and the formatted summary is only produced when the user explicitly invokes the recap command. Confidence: 0.65
- When creating custom skills, use a references/ subdirectory for examples, templates, and reference materials alongside the main SKILL.md file (following the json-canvas skill's references/EXAMPLES.md pattern). Confidence: 0.70

# documentation
- Insert feature designs directly into the TID document rather than creating separate spec files. The TID is the single source of truth for system design. Confidence: 0.65

# recap
- Recap content must include both quantitative data (deliverable completion stats, streak data, knowledge notes created, inbox processed, material chapters, study hours, top domains) and a qualitative highlight — the "biggest win" or essence of the period, not just raw stats. Confidence: 0.70

# cli
- Use `--model` (long form flag) instead of `-m` when invoking Command Code CLI in project scripts. Confidence: 0.70
- Use `cmdc` instead of `cmd` in project scripts since `cmd` does not work reliably on Windows. Confidence: 0.70

# agent-architecture
- Design agents with a single focused responsibility — do not bundle disparate workflows (e.g., PDF parsing AND image/LaTeX processing) into one agent; split into separate specialist agents instead. Confidence: 0.60

# transcription
- For mobile capture transcriptions: use normal markdown for explanatory text and LaTeX for math, with inline math when equations appear mid-sentence and block math (own section like a textbook) when the original page presents standalone equations. Confidence: 0.75

# transcription
- For mobile capture transcriptions: use normal markdown for explanatory text and LaTeX for math, with inline math when equations appear mid-sentence and block math (own section like a textbook) when the original page presents standalone equations. Confidence: 0.75
- For fallback diagram/sketch notes: use image wikilinks (`[[image.jpg]]`) instead of embedded images (`![[image.jpg]]`) to keep notes cleaner and reduce immersion breaks — link to the image rather than embedding it inline in the note body. Confidence: 0.70

# templates
- Concept templates should contain only: YAML frontmatter (type, domain, status, tags, related, sources), `# {{Title}}` heading (for Obsidian Ctrl+O auto-creation), and a light `## Connections` or `## References` section at the bottom — no rigid prescribed body sections like Definition or Why it matters. The body is a blank canvas. Confidence: 0.80
- Math templates should be identical to concept templates (YAML frontmatter + `# {{Title}}` + `## Connections`) with only `type: math` and `image_source` in YAML to differentiate — no dedicated `## LaTeX` section or `## Why it matters`, since the mobile parser outputs blended markdown+LaTeX as the body. Confidence: 0.70

# goal-tracking
See [goal-tracking/taste.md](goal-tracking/taste.md)
