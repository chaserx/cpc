---
description: Interactive Rails generator wrapper
argument-hint: [generator] [name] [attributes...]
allowed-tools: Read, Write, Edit, Bash(rails:*, bundle:*, mise:*)
---

Run the Rails generator for the specified type.

Generator type: $1
Name: $2
Additional arguments: $3

If no generator type provided, ask what to generate:
- model - Generate ActiveRecord model with migration
- controller - Generate controller with actions
- migration - Generate database migration
- scaffold - Generate full CRUD scaffold
- job - Generate background job
- mailer - Generate Action Mailer
- channel - Generate Action Cable channel
- helper - Generate view helper
- task - Generate Rake task

Execute the appropriate generator:

For model:
```bash
mise exec -- rails generate model $2 $3
```

For controller:
```bash
mise exec -- rails generate controller $2 $3
```

For migration:
```bash
mise exec -- rails generate migration $2 $3
```

For scaffold:
```bash
mise exec -- rails generate scaffold $2 $3
```

After generation:
1. Review the generated files
2. Suggest any improvements or additions based on Rails best practices
3. If a migration was created, remind about running `rails db:migrate`
4. For models, suggest appropriate validations and associations
5. For controllers, suggest authentication/authorization if needed
