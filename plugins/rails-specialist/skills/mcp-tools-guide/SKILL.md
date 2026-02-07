---
name: MCP Tools Guide for Rails Development
description: |
  Comprehensive guide to using the Rails MCP Server, Context7, and Ruby LSP MCP servers for Rails development. Covers tool discovery, codebase analysis, documentation lookup, and code intelligence. Use when you need detailed instructions on leveraging MCP tools.
version: 0.1.0
---

# MCP Tools Guide for Rails Development

Three MCP servers are available for Rails development. Use them to analyze codebases faster and more accurately than reading files manually.

## Rails MCP Server

The primary tool for Rails codebase analysis.

### Tool Discovery

```
mcp__rails__search_tools
```

Returns available analyzers organized by category:
- **models** — Model analysis, associations, validations
- **database** — Schema, migrations, indexes
- **routing** — Route analysis and listing
- **controllers** — Controller structure, actions, filters
- **files** — File listing and reading
- **project** — Project-wide analysis
- **guides** — Rails guides and documentation

### Execute Analyzers

```
mcp__rails__execute_tool(tool_name: "tool_name", params: {...})
```

| Tool | Purpose | Example Params |
|------|---------|----------------|
| `analyze_models` | Model associations, validations, scopes | `{ model_name: "User" }` (optional) |
| `get_schema` | Database schema and indexes | `{}` |
| `get_routes` | Application routing table | `{}` |
| `analyze_controller` | Controller actions and filters | `{ controller_name: "UsersController" }` |
| `list_files` | Find files by pattern | `{ pattern: "app/models/**/*.rb" }` |
| `get_file` | Read a specific file | `{ path: "app/models/user.rb" }` |

### Ruby Execution

```
mcp__rails__execute_ruby(code: "...")
```

Read-only Ruby execution for custom analysis. Common queries:

```ruby
# Model introspection
User.reflect_on_all_associations.map { |a| [a.macro, a.name] }
User.validators.map { |v| [v.class.name, v.attributes] }

# Database introspection
ActiveRecord::Base.connection.indexes(:users).map(&:columns)
ActiveRecord::Base.connection.columns(:users).map { |c| [c.name, c.type] }

# Migration status
ActiveRecord::Base.connection.execute(
  "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 10"
)

# Route inspection
Rails.application.routes.routes.map { |r|
  [r.verb, r.path.spec.to_s, r.defaults[:controller], r.defaults[:action]].join(' ')
}

# File discovery
Dir.glob('app/services/**/*.rb')
Dir.glob('app/javascript/controllers/**/*.js')
Dir.glob('app/views/**/*.turbo_stream.erb')
Dir.glob('app/channels/**/*.rb')
Dir.glob('app/components/**/*.rb')
Dir.glob('spec/**/*_spec.rb')
Dir.glob('spec/factories/**/*.rb')
Dir.glob('spec/support/**/*.rb')
```

## Context7 MCP Server

Retrieves up-to-date documentation and code examples for any library.

### Workflow

1. **Resolve library ID first:**
   ```
   mcp__plugin_context7_context7__resolve-library-id(
     libraryName: "rails",
     query: "your question"
   )
   ```

2. **Query documentation:**
   ```
   mcp__plugin_context7_context7__query-docs(
     libraryId: "/rails/rails",
     query: "your question"
   )
   ```

### When to Use

- Verifying current Rails API behavior or method signatures
- Looking up gem documentation (Devise, Pundit, Sidekiq, etc.)
- Checking for deprecations in newer Rails versions
- Finding code examples for specific patterns
- Confirming configuration options and defaults

### Common Library IDs

| Library | ID |
|---------|-----|
| Rails | `/rails/rails` |
| Ruby | `/ruby/ruby` |

For other gems, always call `resolve-library-id` first.

## Ruby LSP

Provides language-aware intelligence for Ruby code.

### Capabilities

- **Go to definition** — Navigate to method, class, or module definitions
- **Find references** — Locate all usages of a symbol across the codebase
- **Type checking** — Infer and validate types
- **Intelligent completions** — Context-aware code suggestions
- **Symbol search** — Find classes, modules, and methods by name
- **Diagnostics** — Identify issues in Ruby code

### When to Use

- When Rails MCP tools don't provide enough detail about specific method implementations
- When tracing method calls across the codebase
- When investigating inheritance hierarchies or module mixins
- When you need type information for complex Ruby code

## Quick Reference

| Need | Tool |
|------|------|
| Understand models/schema | Rails MCP: `analyze_models`, `get_schema` |
| Check routes | Rails MCP: `get_routes` |
| Analyze controllers | Rails MCP: `analyze_controller` |
| Find files | Rails MCP: `list_files` |
| Custom analysis | Rails MCP: `execute_ruby` |
| Verify API docs | Context7: `resolve-library-id` + `query-docs` |
| Navigate code | Ruby LSP: go-to-definition, find references |
| Check types | Ruby LSP: type checking |
