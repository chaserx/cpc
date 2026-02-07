---
name: Rails Conventions
description: This skill should be used when the user asks about "Rails conventions", "Rails best practices", "Rails file structure", "Rails naming conventions", "The Rails Way", or needs guidance on how Rails applications should be organized. Also applies when working with any Rails files to ensure proper conventions are followed.
version: 0.1.0
---

# Rails Conventions and Best Practices

Guidance for following Rails conventions, file organization, naming patterns, and "The Rails Way" for Rails 7+ applications.

## Core Principles

### Convention over Configuration

Rails provides sensible defaults. Follow conventions to benefit from:
- Automatic file loading and discovery
- Reduced configuration overhead
- Consistency across Rails projects
- Easier onboarding for new developers

### The Rails Way

- **Don't Repeat Yourself (DRY)**: Extract shared logic into concerns, helpers, or services
- **Fat Models, Skinny Controllers**: Business logic belongs in models, not controllers
- **RESTful Resources**: Design around resources with standard CRUD actions
- **Prefer Convention**: Only customize when Rails conventions don't fit

## File Structure

### Standard Directory Layout

```
app/
├── assets/           # CSS, images, fonts (managed by asset pipeline)
├── channels/         # Action Cable channels
├── components/       # ViewComponents (if used)
├── controllers/      # Request handlers
│   ├── concerns/     # Shared controller logic
│   └── api/          # API controllers (namespaced)
├── helpers/          # View helpers
├── javascript/       # JavaScript/Stimulus controllers
├── jobs/             # Background jobs
├── mailers/          # Email senders
├── models/           # ActiveRecord models
│   └── concerns/     # Shared model logic
├── services/         # Service objects (optional)
├── views/            # Templates and partials
│   ├── layouts/      # Application layouts
│   └── shared/       # Shared partials
config/
├── routes.rb         # Routing configuration
├── database.yml      # Database configuration
├── environments/     # Environment-specific settings
└── initializers/     # Startup configuration
db/
├── migrate/          # Database migrations
├── schema.rb         # Current schema (auto-generated)
└── seeds.rb          # Seed data
lib/
├── tasks/            # Rake tasks
└── generators/       # Custom generators
spec/ or test/        # Test files (mirrors app/ structure)
```

## Naming Conventions

### Models
- **Class**: Singular, PascalCase (`User`, `OrderItem`, `BlogPost`)
- **File**: Singular, snake_case (`user.rb`, `order_item.rb`, `blog_post.rb`)
- **Table**: Plural, snake_case (`users`, `order_items`, `blog_posts`)
- **Foreign key**: Singular model name + `_id` (`user_id`, `order_item_id`)

### Controllers
- **Class**: Plural, PascalCase + Controller (`UsersController`, `OrderItemsController`)
- **File**: Plural, snake_case (`users_controller.rb`, `order_items_controller.rb`)
- **Actions**: Lowercase (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`)

### Views
- **Directory**: Plural, snake_case (`app/views/users/`)
- **Template**: Action name + format + handler (`index.html.erb`, `show.json.jbuilder`)
- **Partial**: Underscore prefix (`_form.html.erb`, `_user.html.erb`)

### Routes
- **Resource**: Plural (`resources :users`, `resources :order_items`)
- **Singular Resource**: Singular (`resource :profile`, `resource :dashboard`)

### Jobs
- **Class**: Descriptive + Job (`SendWelcomeEmailJob`, `ProcessPaymentJob`)
- **File**: snake_case (`send_welcome_email_job.rb`)

### Mailers
- **Class**: Descriptive + Mailer (`UserMailer`, `OrderMailer`)
- **Methods**: Descriptive action (`welcome_email`, `order_confirmation`)

### Migrations
- **File**: Timestamp + descriptive name (`20240101120000_create_users.rb`)
- **Class**: Descriptive in PascalCase (`CreateUsers`, `AddEmailToUsers`)

## RESTful Design

### Standard Actions

| Action | HTTP Verb | Path | Purpose |
|--------|-----------|------|---------|
| index | GET | /users | List all |
| show | GET | /users/:id | Show one |
| new | GET | /users/new | Form for new |
| create | POST | /users | Create new |
| edit | GET | /users/:id/edit | Form for edit |
| update | PATCH/PUT | /users/:id | Update existing |
| destroy | DELETE | /users/:id | Delete |

### Custom Actions

Add custom actions sparingly using member or collection routes:

```ruby
resources :users do
  member do
    post :activate     # POST /users/:id/activate
    post :deactivate   # POST /users/:id/deactivate
  end
  collection do
    get :search        # GET /users/search
  end
end
```

### Nested Resources

Limit nesting to one level:

```ruby
# Good: One level deep
resources :posts do
  resources :comments, only: [:index, :create]
end

# Avoid: Too deep
resources :users do
  resources :posts do
    resources :comments  # Don't do this
  end
end
```

## Model Conventions

### Association Naming

```ruby
class User < ApplicationRecord
  has_many :posts                    # Standard plural
  has_many :comments, through: :posts
  has_one :profile                   # Singular
  belongs_to :organization           # Singular
end

class Post < ApplicationRecord
  belongs_to :user                   # Singular
  belongs_to :author, class_name: 'User'  # Custom name
  has_many :comments, dependent: :destroy
end
```

### Validation Patterns

```ruby
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { maximum: 100 }
  validates :age, numericality: { greater_than: 0 }, allow_nil: true
end
```

### Scope Naming

Name scopes after the condition they represent:

```ruby
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_author, ->(user) { where(user: user) }
end
```

## Controller Conventions

### Standard Structure

```ruby
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.all
  end

  def show; end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, notice: 'User created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
```

## Common Patterns

### Service Objects
Place complex business logic in `app/services/`:
```ruby
# app/services/order_processor.rb
class OrderProcessor
  def initialize(order)
    @order = order
  end

  def call
    # Complex business logic
  end
end
```

### Query Objects
For complex queries, use query objects:
```ruby
# app/queries/published_posts_query.rb
class PublishedPostsQuery
  def initialize(relation = Post.all)
    @relation = relation
  end

  def call
    @relation.where(published: true).order(created_at: :desc)
  end
end
```

### Form Objects
For complex forms spanning multiple models:
```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model

  attr_accessor :email, :name, :company_name

  def save
    ActiveRecord::Base.transaction do
      user = User.create!(email: email, name: name)
      Company.create!(name: company_name, owner: user)
    end
  end
end
```

## Additional Resources

### Reference Files

For detailed conventions and patterns, consult:
- **`references/naming-cheatsheet.md`** - Complete naming reference
- **`references/antipatterns.md`** - Common mistakes to avoid

## Quick Reference

| What | Convention | Example |
|------|------------|---------|
| Model class | Singular PascalCase | `User` |
| Model file | Singular snake_case | `user.rb` |
| Table | Plural snake_case | `users` |
| Controller | Plural + Controller | `UsersController` |
| View folder | Plural snake_case | `views/users/` |
| Route | Plural resource | `resources :users` |
| Foreign key | model_id | `user_id` |
| Join table | Alphabetical | `posts_tags` |

Follow these conventions consistently to create maintainable Rails applications that are easy to understand and extend.
