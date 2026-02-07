---
description: Rails console helper for debugging and exploration
argument-hint: [ruby-code-or-query]
allowed-tools: Read, Grep, Bash(mise:*, rails:*, bundle:*, ruby:*)
---

Help with Rails console operations.

Query or code: $ARGUMENTS

If a specific query or code is provided:
1. Analyze what the user wants to accomplish
2. Provide the exact Rails console command(s) to run
3. Explain what the command does
4. Suggest safer alternatives if the command modifies data

Common tasks and their console commands:

**Finding records:**
```ruby
# Find by ID
User.find(1)

# Find by attribute
User.find_by(email: 'user@example.com')

# Search with conditions
User.where(active: true).where('created_at > ?', 1.week.ago)

# With associations loaded
User.includes(:posts).find(1)
```

**Inspecting data:**
```ruby
# View attributes
user.attributes

# Check associations
user.posts.count
user.posts.pluck(:title)

# Model introspection
User.column_names
User.reflect_on_all_associations.map(&:name)
```

**Testing queries:**
```ruby
# See SQL generated
User.where(active: true).to_sql

# Explain query plan
User.where(active: true).explain
```

**Debugging:**
```ruby
# Reload code changes
reload!

# Enable SQL logging
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Check method source location
User.instance_method(:full_name).source_location
```

If no specific query provided, ask what the user wants to accomplish:
- Find specific records
- Inspect data structure
- Test a query
- Debug an issue
- Explore associations
- Check database state

Provide safe, read-only commands when possible. Warn before suggesting any data-modifying operations.
