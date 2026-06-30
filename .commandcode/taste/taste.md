# Taste (Continuously Learned by [CommandCode][cmd])

[cmd]: https://commandcode.ai/

# init
- When initializing from a TID/design document, do NOT execute the full build (directories, templates, files). Instead, create only the AGENTS.md bootstrap file and a plan. Confidence: 0.75

# workflow
- Wrap any automated/scripted process in a skill (via commandcode agent or prompt) rather than instructing the user to run shell commands manually. Confidence: 0.85
- Systematically audit all workflow operations to ensure comprehensive skill coverage — every agent invocation, manual file operation, and shell command should be accessible as a cmdc skill, not just isolated processes. Confidence: 0.70

# note-organization
- Use domain-level folders only (e.g., Knowledge/math/, Knowledge/cs/) with topic/subtopic hierarchy expressed through agent-maintained MOC/index notes, never physical subdirectories below the domain level. Confidence: 0.75
- Use a recursive MOC hierarchy with explicit level tracking (not fixed depth) — any MOC can nest another MOC, and the agent follows a clear protocol for creating/maintaining additional layers. Maintain a MOC registry file per domain or per Knowledge root for tracking the hierarchy. Confidence: 0.70
- Notes must remain freely linkable across MOCs without restriction — MOCs are navigational aids that provide hierarchy, not boundaries that limit cross-MOC wikilinks. The system is a wiki (not a tree), and linking patterns must never be constrained by MOC placement. Confidence: 0.65

# workflow
- Wrap any automated/scripted process in a skill (via commandcode agent or prompt) rather than instructing the user to run shell commands manually. Confidence: 0.85
- Systematically audit all workflow operations to ensure comprehensive skill coverage — every agent invocation, manual file operation, and shell command should be accessible as a cmdc skill, not just isolated processes. Confidence: 0.70
- During weekend rituals, run recap (automated snapshot of what happened) before review (reflective 5-question ritual) as separate sequential steps, not merged into a single command. Confidence: 0.55
- Use a hybrid trigger for periodic recaps: nightly silently appends raw data to a running scratch file, and the formatted summary is only produced when the user explicitly invokes the recap command. Confidence: 0.65

# documentation
- Insert feature designs directly into the TID document rather than creating separate spec files. The TID is the single source of truth for system design. Confidence: 0.65

# recap
- Recap content must include both quantitative data (deliverable completion stats, streak data, knowledge notes created, inbox processed, material chapters, study hours, top domains) and a qualitative highlight — the "biggest win" or essence of the period, not just raw stats. Confidence: 0.70

# goal-tracking
See [goal-tracking/taste.md](goal-tracking/taste.md)
