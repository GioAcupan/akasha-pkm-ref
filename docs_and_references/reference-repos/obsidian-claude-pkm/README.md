**📊 [Take the quick poll](https://github.com/ballred/obsidian-claude-pkm/discussions/4)** - Help shape what gets built next!

---

# Obsidian + Claude Code: AI Accountability System

**Not another PKM starter kit.** This is an execution system that connects your 3-year vision to what you do today — and holds you accountable with AI.

```
3-Year Vision ──→ Yearly Goals ──→ Projects ──→ Monthly Goals ──→ Weekly Review ──→ Daily Tasks
                                      ↑
                              /project new
                         (the bridge layer)
```

Every layer connects. `/daily` surfaces your ONE Big Thing from the weekly review. `/weekly` shows project progress. `/monthly` checks quarterly milestones. `/goal-tracking` knows which goals have no active project. Nothing falls through the cracks.

**v3.1** · Zero dependencies · MIT License

## The Cascade

The #1 reason people star this repo: **"I want goals → projects → daily notes → tasks to actually connect."**

| Layer | File | Skill | What It Does |
|-------|------|-------|-------------|
| Vision | `Goals/0. Three Year Goals.md` | `/goal-tracking` | Life areas, long-term direction |
| Annual | `Goals/1. Yearly Goals.md` | `/goal-tracking` | Measurable objectives, quarterly milestones |
| Projects | `Projects/*/CLAUDE.md` | `/project` | Active initiatives linked to goals |
| Monthly | `Goals/2. Monthly Goals.md` | `/monthly` | Roll up weekly reviews, check quarterly progress |
| Weekly | `Goals/3. Weekly Review.md` | `/weekly` | Reflect, realign, plan next week |
| Daily | `Daily Notes/YYYY-MM-DD.md` | `/daily` | Morning planning, evening reflection |

### How It Flows

**Morning** — `/daily` creates today's note, shows your week's ONE Big Thing and active project next-actions. You pick your focus.

**Evening** — `/daily` summarizes which goals and projects got attention today. Unlinked tasks get flagged.

**Sunday** — `/weekly` reads all your daily notes, scans project status, calculates goal progress, and helps you plan next week. Optional agent team mode parallelizes the collection.

**End of month** — `/monthly` rolls up the weekly reviews, checks quarterly milestones against yearly goals, and sets next month's priorities.

**Ad hoc** — `/project new` creates a project linked to a goal. `/project status` shows a dashboard. `/review` auto-detects the right review type based on context.

## Quick Start

### Prerequisites
- [Obsidian](https://obsidian.md/) installed
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed
- Git installed

### Setup

```bash
# Clone and set up
git clone https://github.com/ballred/obsidian-claude-pkm.git
cd obsidian-claude-pkm
chmod +x scripts/setup.sh && ./scripts/setup.sh

# Open vault in Obsidian, then start Claude Code:
cd ~/your-vault-location
claude
```

On first run, you'll see a welcome message with the cascade visualization. Run `/onboard` to personalize your vault — it asks your name, preferred review day, and goal areas, then configures everything.

### Already have a vault?

You don't need to start from the template. Run `/adopt` from the root of your existing Obsidian vault — it scans your folder structure, detects your organization method (PARA, Zettelkasten, LYT, etc.), maps your folders interactively, and generates all config files scoped to your directory names. Your vault structure stays untouched.

```bash
cd ~/your-existing-vault
claude
# then type: /adopt
```

### Windows

```bash
git clone https://github.com/ballred/obsidian-claude-pkm.git
cd obsidian-claude-pkm
scripts\setup.bat
```

## Skills (Slash Commands)

| Skill | Command | Purpose |
|-------|---------|---------|
| Daily | `/daily` | Morning planning, midday check-in, evening reflection |
| Weekly | `/weekly` | 30-min weekly review with project rollup |
| Monthly | `/monthly` | Monthly review, quarterly milestone check |
| Project | `/project` | Create, track, archive projects linked to goals |
| Review | `/review` | Smart router — detects morning/Sunday/end-of-month context |
| Push | `/push` | Commit and push vault changes to Git |
| Onboard | `/onboard` | Interactive setup + load vault context |
| Adopt | `/adopt` | Scaffold onto an existing vault (BYOV) |
| Upgrade | `/upgrade` | Update to latest version, preserving your content |
| Goal Tracking | *(auto)* | Track progress across the full cascade |
| Vault Ops | *(auto)* | Read/write files, manage wiki-links |

## AI Agents

Four specialized agents with cross-session memory:

| Agent | What It Does |
|-------|-------------|
| `goal-aligner` | Audits daily activity against stated goals. Flags misalignment. |
| `weekly-reviewer` | Facilitates the 3-phase weekly review. Learns your reflection style. |
| `note-organizer` | Fixes broken links, consolidates duplicates, maintains vault hygiene. |
| `inbox-processor` | GTD-style inbox processing — categorize, clarify, organize. |

```bash
claude "Use the goal-aligner agent to analyze my last 2 weeks"
claude "Use the inbox-processor agent to clear my inbox"
```

Agents use `memory: project` to learn your patterns across sessions — the goal-aligner remembers recurring misalignment patterns, the weekly-reviewer learns what reflection questions resonate.

## Productivity Coach

An output style that transforms Claude into an accountability partner:

```bash
/output-style coach
```

The coach challenges assumptions, points out goal-action misalignment, asks powerful questions, and holds you to your commitments. Pairs naturally with `/daily` and `/weekly`.

## Automation

**Zero dependencies.** Everything runs on bash and markdown.

- **Auto-commit** — Every file write/edit triggers a Git commit via PostToolUse hook
- **Session init** — Surfaces your ONE Big Thing, active project count, and days since last review
- **First-run welcome** — New vaults get a guided onboarding experience
- **Skill discovery** — Mention "skill" or "help" and available commands are listed automatically
- **Path-specific rules** — Markdown standards, productivity workflow, and project management conventions loaded contextually

## Structure

```
Your Vault/
├── CLAUDE.md                    # AI context and navigation
├── .claude/
│   ├── agents/                  # 4 specialized AI agents (with memory)
│   ├── skills/                  # 10 skills (8 listed above + 2 auto)
│   ├── hooks/                   # Auto-commit, session init, skill discovery
│   ├── rules/                   # Path-specific conventions
│   ├── output-styles/           # Productivity Coach
│   └── settings.json            # Permissions, env vars, hooks config
├── Daily Notes/                 # YYYY-MM-DD.md
├── Goals/                       # The cascade (3-year → weekly)
├── Projects/                    # Active projects with CLAUDE.md each
├── Templates/                   # Reusable note structures
├── Archives/                    # Completed/inactive content
└── Inbox/                       # Quick captures (optional)
```

## Upgrading

### Built-in upgrade (v3.1+)

```bash
/upgrade check    # Preview what's changed
/upgrade          # Interactive upgrade with backup
```

The upgrade skill creates a timestamped backup, shows diffs for each changed file, and never touches your content folders (Daily Notes, Goals, Projects, etc.).

### Manual upgrade from v2.1

```bash
# Copy new skill directories
cp -r vault-template/.claude/skills/project your-vault/.claude/skills/
cp -r vault-template/.claude/skills/monthly your-vault/.claude/skills/
cp -r vault-template/.claude/skills/review your-vault/.claude/skills/
cp -r vault-template/.claude/skills/upgrade your-vault/.claude/skills/

# Update agents, hooks, settings
cp vault-template/.claude/agents/*.md your-vault/.claude/agents/
cp vault-template/.claude/hooks/* your-vault/.claude/hooks/
cp vault-template/.claude/settings.json your-vault/.claude/
chmod +x your-vault/.claude/hooks/*.sh
```

### From v1.x

```bash
cp -r vault-template/.claude-plugin your-vault/
cp -r vault-template/.claude your-vault/
cp vault-template/CLAUDE.md your-vault/
chmod +x your-vault/.claude/hooks/*.sh
```

## Documentation

- **[Setup Guide](docs/SETUP_GUIDE.md)** — Detailed installation instructions
- **[Customization](docs/CUSTOMIZATION.md)** — Make it yours
- **[Workflow Examples](docs/WORKFLOW_EXAMPLES.md)** — Daily routines and best practices
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** — Common issues and solutions
- **[Contributing](CONTRIBUTING.md)** — How to help

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. Good first issues are labeled — check the [issues page](https://github.com/ballred/obsidian-claude-pkm/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).

## License

MIT — Use this freely for your personal knowledge management journey.
