# Contributing to Claude Plugin Compendium

First off, thank you for considering contributing to Claude Plugin Compendium! This project grows through community contributions, and we genuinely appreciate the time and effort you put in — whether it's fixing a typo, improving an existing plugin, or building an entirely new one.

By participating in this project, you agree to abide by our [Code of Conduct](./CODE_OF_CONDUCT.md).

## How Can I Contribute?

There are many ways to help, and not all of them involve writing code:

- **Report bugs or suggest improvements** — Open an [issue][issues] describing what you found or what you'd like to see.
- **Improve documentation** — Fix typos, clarify instructions, or add missing details to READMEs, skills, or agent descriptions.
- **Enhance existing plugins** — Add new agents, skills, commands, or hooks to a plugin like `rails-specialist`.
- **Create a new plugin** — Build a plugin for a framework or workflow that isn't covered yet.
- **Review pull requests** — Test out proposed changes and share your feedback.

## Getting Started

### 1. Fork and clone the repo

```bash
git clone git@github.com:your-username/claude-plugin-compendium.git
cd claude-plugin-compendium
```

### 2. Understand the project structure

```
cpc/
├── plugins/
│   └── rails-specialist/       # Example plugin
│       ├── .claude-plugin/
│       │   └── plugin.json     # Plugin manifest
│       ├── agents/             # Agent definitions (.md)
│       ├── skills/             # Knowledge documents (skills/<name>/SKILL.md)
│       ├── commands/           # Slash commands (.md)
│       ├── hooks/              # Validation hooks
│       └── .mcp.json           # MCP server configuration
├── .claude-plugin/
│   └── marketplace.json        # Registry of all plugins
├── CLAUDE.md                   # Claude Code project instructions
└── README.md
```

### 3. Try out the plugin you want to work on

Install the plugin in a Claude Code project to see how it works before making changes. The [rails-specialist README](plugins/rails-specialist/README.md) has setup instructions.

## Plugin Component Guide

Each plugin can contain any combination of these components. Refer to the existing `rails-specialist` plugin for working examples.

### Agents

Agent files are Markdown with YAML frontmatter. They live in `agents/` and define specialized sub-agents that Claude Code can delegate to.

**Frontmatter fields:** `name`, `description` (with `<example>` blocks), `model` (use `sonnet`), `color`

### Skills

Skills are reusable knowledge documents at `skills/<skill-name>/SKILL.md`. They provide domain expertise that agents and users can reference.

**Frontmatter fields:** `name`, `description`, `version`

### Commands

Commands are slash commands (e.g., `/rails-test`) defined as Markdown files in `commands/`. They reference `$ARGUMENTS` for user input.

**Frontmatter fields:** `description`, `argument-hint`, `allowed-tools`

### Hooks

Hooks run shell scripts in response to Claude Code events (like `PreToolUse`). They're defined in `hooks/hooks.json` with scripts in `hooks/scripts/`. Use exit code `0` to allow and `2` to block with a message.

### MCP Servers

MCP server configuration goes in `.mcp.json` at the plugin root. This connects external tools (like language servers or framework-specific analyzers) to the plugin.

## Making Changes

### Branch naming

Use descriptive branch names:

- `add-agent-rails-mailer-pro` — Adding a new agent
- `improve-active-record-patterns-skill` — Enhancing a skill
- `fix-hook-validation-edge-case` — Fixing a bug

### Commit messages

Write clear commit messages that explain **why**, not just what. A good format:

```
Add Rails mailer agent for email delivery patterns

Introduces rails-mailer-pro agent covering ActionMailer configuration,
delivery strategies, and preview testing. Includes examples for common
transactional email patterns.
```

### What to check before submitting

- [ ] Your plugin follows the directory structure described above
- [ ] Agent files have valid YAML frontmatter with all required fields
- [ ] Skill files include `name`, `description`, and `version` in frontmatter
- [ ] Command files include `description` and `allowed-tools` in frontmatter
- [ ] Any shell scripts in hooks are executable (`chmod +x`)
- [ ] You've tested the plugin with Claude Code in a real project
- [ ] New plugins are registered in `.claude-plugin/marketplace.json`
- [ ] The plugin's `plugin.json` manifest is complete and valid JSON

## Submitting Your Contribution

1. **Create a branch** from `main` for your changes.
2. **Make your changes** following the conventions described above.
3. **Push to your fork** and [open a pull request][pr].
4. **Describe your changes** in the PR — what you added, why, and how to test it.

We aim to review pull requests within a few days. We may suggest changes or improvements — this is a normal part of the process and not a reflection on the quality of your work.

## Creating a New Plugin

If you want to contribute an entirely new plugin:

1. Create a directory under `plugins/` (e.g., `plugins/django-specialist/`).
2. Add a `.claude-plugin/plugin.json` manifest with `name`, `version`, `description`, `author`, `category`, and `tags`.
3. Add at least one useful component (an agent, skill, or command).
4. Include a `README.md` explaining what the plugin does and how to set it up.
5. Register the plugin in the root `.claude-plugin/marketplace.json`.

Start small. A plugin with one well-crafted agent and a couple of skills is more valuable than a sprawling plugin that's half-finished.

## Questions?

Not sure where to start? Have an idea but want to talk it through first? [Open a discussion][issues] — we're happy to help you find the right approach.

[issues]: https://github.com/chaserx/claude-plugin-compendium/issues
[pr]: https://github.com/chaserx/claude-plugin-compendium/compare/
