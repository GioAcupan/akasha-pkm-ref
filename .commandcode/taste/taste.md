# Taste (Continuously Learned by [CommandCode][cmd])

[cmd]: https://commandcode.ai/

# init
- When initializing from a TID/design document, do NOT execute the full build (directories, templates, files). Instead, create only the AGENTS.md bootstrap file and a plan. Confidence: 0.75

# workflow
- Wrap any automated/scripted process in a skill (via commandcode agent or prompt) rather than instructing the user to run shell commands manually. Confidence: 0.85
- Systematically audit all workflow operations to ensure comprehensive skill coverage — every agent invocation, manual file operation, and shell command should be accessible as a cmdc skill, not just isolated processes. Confidence: 0.70
