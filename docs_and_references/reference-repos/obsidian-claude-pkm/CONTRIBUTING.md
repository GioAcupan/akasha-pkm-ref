# Contributing to Obsidian + Claude Code PKM

Thanks for your interest in contributing! This project aims to be the best AI-powered accountability system for Obsidian, and community contributions make it better for everyone.

## Ways to Contribute

### Report Bugs
- Open an [issue](https://github.com/ballred/obsidian-claude-pkm/issues/new) with steps to reproduce
- Include your OS, Claude Code version, and relevant vault structure

### Suggest Features
- Open an issue with the `enhancement` label
- Describe the problem you're solving, not just the solution
- Bonus: explain how it connects to the goal cascade

### Submit Code
1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-improvement`)
3. Make your changes in `vault-template/`
4. Test by copying to a fresh vault and running the affected skills
5. Commit with a clear message
6. Open a PR against `main`

### Improve Documentation
- Fix typos, clarify instructions, add examples
- Documentation PRs are always welcome and easy to review

## Good First Issues

Look for issues labeled [`good first issue`](https://github.com/ballred/obsidian-claude-pkm/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22). These are scoped tasks that don't require deep knowledge of the full system.

Good candidates for first contributions:
- **New goal templates** — Add alternative goal structures (OKRs, SMART goals, theme-based)
- **New output styles** — Create personas beyond Productivity Coach (Socratic tutor, stoic mentor, etc.)
- **Template variations** — Alternative daily/weekly note formats
- **Documentation** — Improve setup guides, add workflow examples, fix unclear instructions
- **Rule files** — Add new path-specific conventions (e.g., health tracking, learning logs)

## Architecture Overview

Understanding the system helps you contribute effectively:

```
vault-template/
├── .claude/
│   ├── skills/          # Slash commands — each has a SKILL.md
│   │                    # user-invocable: true → shows in /skill-name
│   │                    # user-invocable: false → auto-triggered
│   ├── agents/          # Multi-turn personas with memory
│   ├── hooks/           # Bash scripts triggered by events
│   ├── rules/           # Always-loaded context conventions
│   ├── output-styles/   # Tone/persona configurations
│   └── settings.json    # Permissions, env vars, hook config
├── Goals/               # The cascade files
├── Templates/           # Note templates
└── CLAUDE.md            # Root context file
```

### Key Design Principles

1. **Zero dependencies** — No npm, no Python, no external tools. Everything is bash + markdown. This is intentional — keep it that way.

2. **The cascade is the moat** — Every feature should strengthen the connection between goals → projects → daily tasks. If a feature doesn't connect to the cascade, it probably doesn't belong.

3. **Skills, not scripts** — Skills are markdown files that instruct Claude, not executable code. They describe *what to do*, and Claude figures out *how*.

4. **Agents have opinions** — Agents aren't generic assistants. The goal-aligner should challenge you. The weekly-reviewer should ask uncomfortable questions. The productivity coach should hold you accountable.

5. **User content is sacred** — Never modify Daily Notes, Goals, Projects, or Archives without explicit user confirmation. System files in `.claude/` are fair game for upgrades.

## Adding a New Skill

1. Create `vault-template/.claude/skills/your-skill/SKILL.md`
2. Add YAML frontmatter:
   ```yaml
   ---
   name: your-skill
   description: One-line description of what it does.
   allowed-tools: Read, Write, Edit, Glob, Grep
   model: sonnet
   user-invocable: true
   ---
   ```
3. Write the skill prompt — describe the workflow, output format, and integration points
4. Add it to `vault-template/CLAUDE.md` skills table
5. Update `README.md` skills table
6. Test in a fresh vault

## Adding a New Agent

1. Create `vault-template/.claude/agents/your-agent.md`
2. Add frontmatter with `memory: project` for cross-session learning
3. Define the agent's personality, responsibilities, and output format
4. Add to `vault-template/CLAUDE.md` agents table
5. Test multi-turn interactions

## Code Style

- **Markdown** — Follow `vault-template/.claude/rules/markdown-standards.md`
- **Bash scripts** — POSIX-compatible where possible, handle both macOS and Linux
- **Commit messages** — Imperative mood, concise summary, body for context
- **File naming** — Skills: `SKILL.md`. Agents: `kebab-case.md`. Rules: `kebab-case.md`.

## Testing

There's no automated test suite (yet). To test your changes:

1. Copy `vault-template/` to a temporary location
2. Open it as an Obsidian vault
3. Start Claude Code in that directory
4. Run the affected skills/agents
5. Verify the output matches expectations

## Questions?

Open an issue or start a discussion. We're happy to help you find the right place to contribute.
