---
name: Active Record Patterns
description: This skill should be used when the user asks about "Active Record", "model associations", "ActiveRecord queries", "database relationships", "model validations", "Rails scopes", "N+1 queries", or needs help designing or optimizing Rails models. Provides comprehensive guidance on ActiveRecord patterns and best practices.
version: 0.1.0
---

# Active Record Patterns

Guidance for designing and implementing ActiveRecord models with proper associations, validations, queries, and performance optimizations in Rails 7+.

## Association Types

### belongs_to
The child side of a one-to-many or one-to-one relationship:

```ruby
class Post < ApplicationRecord
  belongs_to :user                    # Required by default in Rails 5+
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :category, optional: true  # Allow nil
end
```

### has_many
The parent side of a one-to-many relationship:

```ruby
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :active_posts, -> { where(published: true) }, class_name: 'Post'
end
```

### has_one
A one-to-one relationship:

```ruby
class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_one :most_recent_post, -> { order(created_at: :desc) }, class_name: 'Post'
end
```

### has_many :through
Many-to-many with a join model:

```ruby
class User < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :teams, through: :memberships
end

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :team
  # Can have additional attributes: role, joined_at, etc.
end

class Team < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
end
```

### has_and_belongs_to_many
Simple many-to-many without join model attributes:

```ruby
class Post < ApplicationRecord
  has_and_belongs_to_many :tags
end

class Tag < ApplicationRecord
  has_and_belongs_to_many :posts
end
# Requires posts_tags join table (alphabetical order)
```

### Polymorphic Associations

```ruby
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
end

class Post < ApplicationRecord
  has_many :comments, as: :commentable
end

class Photo < ApplicationRecord
  has_many :comments, as: :commentable
end
```

## Dependent Options

Always specify `:dependent` for `has_many` and `has_one`:

| Option | Behavior |
|--------|----------|
| `:destroy` | Calls destroy on each associated record (triggers callbacks) |
| `:delete_all` | Deletes directly from database (no callbacks) |
| `:nullify` | Sets foreign key to NULL |
| `:restrict_with_error` | Prevents deletion if associated records exist |
| `:restrict_with_exception` | Raises exception if associated records exist |

## Validations

### Presence and Uniqueness
```ruby
class User < ApplicationRecord
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
end
```

### Numericality
```ruby
class Product < ApplicationRecord
  validates :price, numericality: { greater_than: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
```

### Conditional Validations
```ruby
class Order < ApplicationRecord
  validates :shipping_address, presence: true, if: :requires_shipping?
  validates :credit_card, presence: true, unless: -> { payment_method == 'invoice' }
end
```

### Custom Validations
```ruby
class User < ApplicationRecord
  validate :password_complexity

  private

  def password_complexity
    return if password.blank?
    unless password.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      errors.add(:password, 'must include lowercase, uppercase, and digit')
    end
  end
end
```

## Scopes

### Basic Scopes
```ruby
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :draft, -> { where(published: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(views_count: :desc) }
end
```

### Parameterized Scopes
```ruby
class Post < ApplicationRecord
  scope :by_author, ->(user) { where(user: user) }
  scope :created_after, ->(date) { where('created_at > ?', date) }
  scope :with_tag, ->(tag) { joins(:tags).where(tags: { name: tag }) }
end
```

### Chainable Scopes
```ruby
# Usage: Post.published.recent.by_author(user).limit(10)
Post.published.recent.by_author(current_user).limit(10)
```

## Query Optimization

### Preventing N+1 Queries

**Problem:**
```ruby
# Triggers N+1 queries
users = User.all
users.each { |u| puts u.posts.count }  # SELECT for each user!
```

**Solutions:**

```ruby
# includes: Loads associations in separate query
users = User.includes(:posts)
users.each { |u| puts u.posts.size }  # No additional queries

# preload: Always separate queries (best for large associations)
users = User.preload(:posts, :comments)

# eager_load: Uses LEFT JOIN (needed for filtering on association)
users = User.eager_load(:posts).where(posts: { published: true })

# joins: For filtering only (doesn't load association)
users = User.joins(:posts).where(posts: { published: true }).distinct
```

### Selecting Specific Columns
```ruby
# Load only what's needed
users = User.select(:id, :name, :email)

# With pluck for arrays
emails = User.where(active: true).pluck(:email)

# With pick for single values
latest_id = User.order(created_at: :desc).pick(:id)
```

### Batch Processing
```ruby
# For large datasets, process in batches
User.find_each(batch_size: 1000) do |user|
  user.send_newsletter
end

# With in_batches for batch operations
User.in_batches(of: 1000) do |users|
  users.update_all(newsletter_sent: true)
end
```

### Bulk Operations
```ruby
# insert_all: Skip validations and callbacks
User.insert_all([
  { email: 'a@example.com', name: 'A' },
  { email: 'b@example.com', name: 'B' }
])

# upsert_all: Insert or update
User.upsert_all(
  [{ email: 'a@example.com', name: 'Updated A' }],
  unique_by: :email
)
```

## Callbacks

Use callbacks sparingly, only for model-centric operations:

```ruby
class User < ApplicationRecord
  before_validation :normalize_email
  before_save :encrypt_password, if: :password_changed?
  after_create :send_welcome_email
  after_destroy :cleanup_associated_files

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
```

### Callback Order
1. `before_validation`
2. `after_validation`
3. `before_save`
4. `before_create` / `before_update`
5. `after_create` / `after_update`
6. `after_save`
7. `after_commit` / `after_rollback`

### When NOT to Use Callbacks
- External API calls (use jobs instead)
- Complex business logic (use services)
- Sending emails (use jobs)
- Creating audit logs (consider after_commit)

## Counter Caches

For frequently counted associations:

```ruby
# Migration
add_column :users, :posts_count, :integer, default: 0
User.find_each { |u| User.reset_counters(u.id, :posts) }

# Model
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
end

# Usage
user.posts_count  # No query!
```

## Model Organization

Organize model code consistently:

```ruby
class User < ApplicationRecord
  # 1. Includes and extends
  include Searchable

  # 2. Constants
  ROLES = %w[admin member guest].freeze

  # 3. Associations
  has_many :posts, dependent: :destroy
  has_one :profile, dependent: :destroy

  # 4. Validations
  validates :email, presence: true, uniqueness: true

  # 5. Scopes
  scope :active, -> { where(active: true) }

  # 6. Callbacks
  before_save :normalize_email

  # 7. Class methods
  def self.find_by_credentials(email, password)
    find_by(email: email)&.authenticate(password)
  end

  # 8. Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end

  # 9. Private methods
  private

  def normalize_email
    self.email = email.downcase.strip
  end
end
```

## Additional Resources

### Reference Files

For advanced patterns and detailed examples, consult:
- **`references/query-patterns.md`** - Advanced query patterns
- **`references/performance-tips.md`** - Performance optimization techniques

## Quick Reference

| Need | Solution |
|------|----------|
| Load association data | `includes(:association)` |
| Filter by association | `joins(:association).where(...)` |
| Count without query | Counter cache |
| Process large dataset | `find_each` or `in_batches` |
| Bulk insert | `insert_all` |
| Custom validation | `validate :method_name` |
| Reusable query | `scope :name, -> { ... }` |

Apply these patterns to build efficient, maintainable ActiveRecord models.
