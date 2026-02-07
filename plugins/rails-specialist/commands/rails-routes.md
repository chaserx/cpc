---
description: Inspect and analyze Rails routes
argument-hint: [controller-or-pattern]
allowed-tools: Read, Grep, Bash(mise:*, rails:*, bundle:*)
---

Inspect Rails routes.

Filter pattern: $ARGUMENTS

If a pattern is provided, filter routes:
```bash
mise exec -- rails routes -g $ARGUMENTS
```

If no pattern, show all routes:
```bash
mise exec -- rails routes
```

After showing routes:

1. **Analyze the routing structure**:
   - Identify RESTful resources
   - Note any custom routes
   - Check for potential conflicts or issues

2. **Suggest improvements** if any:
   - Missing RESTful actions that might be needed
   - Routes that could be simplified
   - Deeply nested routes that could be flattened
   - Non-standard route patterns

3. **Explain route helpers**:
   - Show the path helper for requested routes
   - Explain URL vs path helpers
   - Demonstrate usage in views/controllers

4. **If looking for a specific route**:
   - Show exact match if found
   - Suggest similar routes if not found
   - Explain how to add the route if missing

Common route patterns to recognize:
- `resources :users` - Full RESTful resource
- `resource :profile` - Singular resource
- `namespace :admin` - Namespaced routes
- `member { ... }` - Actions on specific resource
- `collection { ... }` - Actions on collection
- `concerns` - Shared routing patterns

Provide actionable guidance based on what the user is trying to accomplish.
