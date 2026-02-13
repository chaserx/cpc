# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Plugin Compendium (cpc) — a collection of Claude Code plugins for specialized development workflows. The repo currently contains:

- **`plugins/rails-specialist/`** — A Claude Code plugin for Rails 7+ development, containing agents, skills, commands, hooks, and MCP server integrations.

## Architecture

### Rails Specialist Plugin (`plugins/rails-specialist/`)

A Claude Code plugin following the `.claude-plugin/plugin.json` manifest structure:

- **Agents** (9) — Specialized Rails agents with `-pro` suffix, using `model: sonnet`. The `rails-architect-pro` acts as coordinator, delegating to domain specialists. Agents reference skills, and integrate with Rails MCP, Context7 MCP, and Ruby LSP servers.
  - `rails-architect-pro` — High-level architecture and coordination (includes service layer patterns)
  - `rails-model-pro` — ActiveRecord models and database layer
  - `rails-controller-pro` — Controller logic and request handling
  - `rails-api-pro` — API design and implementation
  - `rails-view-pro` — Views, partials, and Hotwire/Turbo/Stimulus
  - `rails-background-pro` — Background jobs and async processing
  - `rails-test-pro` — Testing strategies and implementation
  - `rails-migration-pro` — Database migrations and schema changes
  - `rails-debugger` — Debugging and troubleshooting
- **Skills** (10) — Reusable knowledge documents in `skills/<name>/SKILL.md`:
  - `rails-conventions` — Project structure and naming conventions
  - `active-record-patterns` — ActiveRecord query and association patterns
  - `action-controller-patterns` — Controller design patterns
  - `rails-testing` — Testing strategies and frameworks
  - `rails-security` — Security best practices
  - `rails-performance` — Performance optimization techniques
  - `service-patterns` — Service objects, form objects, and interactors
  - `hotwire-patterns` — Turbo Frames, Turbo Streams, and Stimulus
  - `rails-antipatterns` — Common anti-patterns, code smells, and refactoring guidance
  - `mcp-tools-guide` — Guide to using the plugin's MCP tools
- **Commands** (4) — Slash commands in `commands/`: `/rails-generate`, `/rails-test`, `/rails-console`, `/rails-routes`.
- **Hooks** — `hooks/hooks.json` defines a `PreToolUse` hook on `Write|Edit` that runs `validate-rails-conventions.sh`. The script validates Rails naming conventions (snake_case models, `_controller.rb` suffix, timestamp migrations, `_spec.rb`/`_test.rb` suffixes, etc.) and blocks non-conforming writes in Rails projects.
- **MCP Servers** — `.mcp.json` configures `rails-mcp-server` (via npx), `ruby-lsp` (via bundler), and `context7` (via npx). The rails MCP provides `analyze_models`, `get_schema`, `get_routes`, `analyze_controller`, and `execute_ruby` tools.

## Key Conventions

- Agent markdown files use YAML frontmatter with `name`, `description` (with `<example>` blocks), `model`, and `color` fields.
- Skill files live at `skills/<skill-name>/SKILL.md` with frontmatter: `name`, `description`. Skills may have a `references/` subdirectory with detailed topic files (e.g., `skills/rails-testing/references/rspec-patterns.md`).
- Command files use frontmatter: `description`, `argument-hint`, `allowed-tools`. Commands reference `$ARGUMENTS` for user input.
- Rails commands in the plugin use bare `rails` or `bundle exec` (e.g., `bundle exec rspec`, `rails test`).
- The convention validator hook uses exit code 0 (allow) and exit code 2 (block with deny message). Hook output format: JSON on stderr with `hookSpecificOutput.permissionDecision` and `systemMessage`.
- Plugin agents use `model: sonnet`.
- New plugins must be registered in the root `.claude-plugin/marketplace.json` and have a `.claude-plugin/plugin.json` manifest.
- Hook scripts use `${CLAUDE_PLUGIN_ROOT}` to reference files relative to the plugin directory.
