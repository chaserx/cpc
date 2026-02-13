---
description: Run and analyze Rails tests
argument-hint: [file-or-pattern]
allowed-tools: Read, Grep, Bash(rails:*, bundle:*, rspec:*, ruby:*)
---

Run Rails tests and analyze results.

Test target: $ARGUMENTS

Determine the testing framework by checking for:
- `spec/` directory with `_spec.rb` files = RSpec
- `test/` directory with `_test.rb` files = Minitest

If specific file or pattern provided ($ARGUMENTS is not empty):

For RSpec:
```bash
bundle exec rspec $ARGUMENTS
```

For Minitest:
```bash
rails test $ARGUMENTS
```

If no arguments provided, run the full test suite:

For RSpec:
```bash
bundle exec rspec
```

For Minitest:
```bash
rails test
```

After running tests:

1. **Analyze failures**: For each failing test:
   - Identify the specific assertion that failed
   - Determine the root cause (code bug vs test bug)
   - Suggest a fix with specific code changes

2. **Performance check**: Note any slow tests (>1 second)

3. **Coverage summary**: If coverage tool is configured, summarize coverage

4. **Next steps**: Recommend what to do based on results:
   - If all pass: Suggest any additional test cases
   - If failures: Provide prioritized list of fixes
   - If errors: Explain the error and how to resolve

Focus on actionable insights, not just repeating test output.
