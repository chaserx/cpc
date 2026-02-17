# Rails Specialist Plugin

A comprehensive Claude Code plugin for Ruby on Rails development, providing specialized agents, skills, and MCP integrations for Rails 7+ applications.

## Features

### Agents (9)
- **rails-architect-pro** - High-level architecture, coordination, and service layer patterns
- **rails-model-pro** - ActiveRecord models, associations, validations, and database layer
- **rails-controller-pro** - Controller logic, strong params, and request handling
- **rails-api-pro** - API design, serializers, and versioning
- **rails-view-pro** - Views, partials, helpers, and Hotwire/Turbo/Stimulus
- **rails-background-pro** - Background jobs, Active Job, Action Mailer, and Sidekiq
- **rails-test-pro** - Testing strategies for RSpec and Minitest
- **rails-migration-pro** - Database migrations and schema changes
- **rails-debugger** - Debugging, troubleshooting, and N+1 detection

### Skills (10)
- **rails-conventions** - Project structure and naming conventions
- **active-record-patterns** - ActiveRecord query and association patterns
- **action-controller-patterns** - Controller design patterns
- **rails-testing** - Testing strategies and frameworks
- **rails-security** - Security best practices
- **rails-performance** - Performance optimization techniques
- **service-patterns** - Service objects, form objects, and interactors
- **hotwire-patterns** - Turbo Frames, Turbo Streams, and Stimulus
- **rails-antipatterns** - Common anti-patterns, code smells, and refactoring guidance
- **mcp-tools-guide** - Guide to using the plugin's MCP tools

### Commands (4)
- `/rails-generate` - Interactive Rails generator
- `/rails-test` - Run and analyze tests
- `/rails-console` - Rails console helper
- `/rails-routes` - Route inspection

### MCP Integrations
- **rails-mcp-server** - Rails introspection (routes, models, schema, controller analysis)
- **ruby-lsp** - Ruby Language Server for code intelligence

## Prerequisites

- Node.js (for rails-mcp-server)
- mise with Ruby installed (for ruby-lsp)
- Ruby on Rails 7+ project

## Installation

```bash
# Install from marketplace

/plugin install rails-specialist@claude-plugin-compendium 


## MCP Server Setup

### rails-mcp-server
Automatically starts via npx. No additional configuration needed.

### ruby-lsp
Requires ruby-lsp gem in your project:
```bash
gem install ruby-lsp
# Or add to Gemfile
gem 'ruby-lsp', group: :development
```

## Configuration

The plugin uses strict Rails convention validation. Files written to Rails directories must follow Rails naming conventions.

## Usage

Agents trigger proactively when working on Rails files:
- Working on a model? rails-model-pro activates
- Writing tests? rails-test-pro helps with RSpec or Minitest
- Debugging issues? rails-debugger analyzes the problem

Use commands for specific tasks:
```
/rails-generate model User name:string email:string
/rails-test spec/models/user_spec.rb
/rails-routes users
```

## License

MIT
