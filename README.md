> **Early Stage Project** — This project is new and has not been extensively validated or tested. Agentic coding workflows evolve rapidly, and some patterns here may need updating. Use with caution. Feedback is welcome — please [open an issue](https://github.com/chaserx/cpc/issues/new) to report problems or suggest improvements.

# Claude Plugin Compendium

A collection of [Claude Code Plugins](https://code.claude.com/docs/en/plugins) for specialized development workflows.

## Plugins

| Plugin                                        | Description                                           | Version |
|-----------------------------------------------|-------------------------------------------------------|---------|
| [rails-specialist](plugins/rails-specialist/) | Agents, Skills, and Commands for Rails 7+ development | 0.1.0   |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Node.js (for rails-mcp-server)
- Ruby, Bundler, and Rails installed (for ruby-lsp and Rails commands)
- Ruby on Rails 7+ project

## Repository Structure

```
cpc/
├── plugins/
│   └── rails-specialist/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── agents/           # 9 specialized agent definitions
│       ├── skills/           # 10 skill knowledge documents
│       ├── commands/         # 4 slash commands
│       ├── hooks/            # Convention validation hook
│       ├── .mcp.json         # MCP server configuration
│       └── README.md
├── .claude-plugin/
│   └── marketplace.json
├── CLAUDE.md
└── README.md
```

## Installation

### Claude Code (via Plugin Marketplace)

1. Add this marketplace

```shell
/plugin marketplace add chaserx/cpc
```

2. Install the rails-specialist plugin from this marketplace:

```shell
/plugin install cpc@rails-specialist
```

## Contributing

[Contributions](CONTRIBUTING.md) are welcome. Each plugin lives in its own directory under `plugins/` and follows the Claude Code plugin structure with a `.claude-plugin/plugin.json` manifest.

## License

MIT
