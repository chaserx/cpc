---
description: Interactive Rails generator wrapper
argument-hint: [generator] [name] [attributes...]
allowed-tools: Read, Write, Edit, Bash(rails:*, bundle:*)
---

Run the Rails generator for the specified type.

Parse the generator type, name, and any additional attributes from: $ARGUMENTS

If no arguments provided, ask what to generate from this list of frequently used generators:
- model - Generate ActiveRecord model with migration
- controller - Generate controller with actions
- migration - Generate database migration
- scaffold - Generate full CRUD scaffold with routes, controllers, views, models, and migrations
- job - Generate background job
- mailer - Generate Action Mailer
- channel - Generate Action Cable channel
- helper - Generate view helper
- task - Generate Rake task
- resource - Generate RESTful resource with a migration, model, controller with RESTful actions, view directory, and a full resources call in routes.rb

Execute the appropriate generator:

For model:
```bash
rails generate model $ARGUMENTS
```

Common model generator options:
- password:digest - adds the `:password_digest` field to the migration and include the `has_secure_password` method in the generated model
- refereces:another_model - adds `references` to a field generates an id column, which is great for `belongs_to` associations

For controller:
```bash
rails generate controller $ARGUMENTS
```
Controller command arguments: ControllerName [action action] (options)
Example: `rails generate controller Books index show new edit`

To generate just the controller without views, helpers, assets, or tests use the following options:
- --no-helper
- --no-assets
- --no-test-framework
- --skip-routes
- --skip

For migration:
```bash
rails generate migration $ARGUMENTS
```

For scaffold:
```bash
rails generate scaffold $ARGUMENTS
```

For job:
```bash
rails generate job $ARGUMENTS
```

For mailer:
```bash
rails generate mailer $ARGUMENTS
```

For channel:
```bash
rails generate channel $ARGUMENTS
```

For helper:
```bash
rails generate helper $ARGUMENTS
```

For task:
```bash
rails generate task $ARGUMENTS
```

Less commonly used generators are:

Rails:
  application_record -
  benchmark
  generator
  integration_test
  jbuilder
  mailbox
  resource
  system_test

ActiveRecord:
  active_record:application_record
  active_record:multi_db

Stimulus:
  stimulus

After generation:
1. Review the generated files
2. Suggest any improvements or additions based on Rails best practices
3. If a migration was created, remind about running `rails db:migrate`
4. For models, suggest appropriate validations and associations
5. For controllers, suggest authentication/authorization if needed
