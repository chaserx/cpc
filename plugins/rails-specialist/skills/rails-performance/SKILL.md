---
name: Rails Performance
description: This skill should be used when the user asks about "Rails performance", "N+1 queries", "caching", "database optimization", "slow queries", "Redis", "Memcached", "background jobs", "profiling", or needs help optimizing Rails application performance. Provides guidance on performance optimization techniques.
version: 0.1.0
---

# Rails Performance Optimization

Guidance for optimizing Rails application performance including database queries, caching, background processing, and profiling.

## N+1 Query Detection and Prevention

### Identifying N+1 Queries

N+1 queries occur when loading associations in a loop:

```ruby
# BAD: N+1 queries
users = User.all
users.each do |user|
  puts user.posts.count  # Each iteration queries the database!
end
# Result: 1 query for users + N queries for posts
```

### Prevention with Eager Loading

```ruby
# includes: Separate query per association (most common)
users = User.includes(:posts)
users.each { |u| u.posts.size }  # No additional queries

# preload: Always separate queries
users = User.preload(:posts, :comments)

# eager_load: Single LEFT JOIN (needed for filtering)
users = User.eager_load(:posts).where(posts: { published: true })

# joins: For filtering only (doesn't load association)
users = User.joins(:posts).where(posts: { published: true }).distinct
```

### Bullet Gem for Detection

```ruby
# Gemfile
gem 'bullet', group: :development

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
end
```

## Database Optimization

### Indexing Strategy

```ruby
# Add indexes for:
# 1. Foreign keys
add_index :posts, :user_id

# 2. Columns used in WHERE clauses
add_index :users, :email, unique: true
add_index :posts, :published

# 3. Columns used in ORDER BY
add_index :posts, :created_at

# 4. Composite indexes for multiple columns
add_index :posts, [:user_id, :published]
add_index :orders, [:status, :created_at]
```

### Query Optimization

```ruby
# Select only needed columns
User.select(:id, :name, :email)

# Use pluck for array of values
User.where(active: true).pluck(:email)

# Use exists? instead of count > 0
User.where(email: email).exists?  # vs .count > 0

# Use find_each for large datasets
User.find_each(batch_size: 1000) do |user|
  user.process!
end

# Use bulk operations
User.where(active: false).update_all(deleted_at: Time.current)
User.insert_all([{ name: 'A' }, { name: 'B' }])
```

### Explain Queries

```ruby
User.where(active: true).explain
# EXPLAIN for SELECT * FROM users WHERE active = true

# With PostgreSQL analyze
User.connection.execute("EXPLAIN ANALYZE SELECT * FROM users WHERE active = true")
```

## Caching Strategies

### Fragment Caching

```erb
<%# Basic fragment cache %>
<% cache @article do %>
  <%= render @article %>
<% end %>

<%# With explicit key %>
<% cache ['v1', @article] do %>
  <%= render @article %>
<% end %>

<%# Collection caching %>
<%= render partial: 'article', collection: @articles, cached: true %>
```

### Russian Doll Caching

```erb
<% cache @article do %>
  <article>
    <h1><%= @article.title %></h1>

    <% cache @article.author do %>
      <div class="author">
        <%= render @article.author %>
      </div>
    <% end %>

    <% @article.comments.each do |comment| %>
      <% cache comment do %>
        <%= render comment %>
      <% end %>
    <% end %>
  </article>
<% end %>
```

Update `touch` for cache invalidation:
```ruby
class Comment < ApplicationRecord
  belongs_to :article, touch: true
end
```

### Low-Level Caching

```ruby
# Read/write cache
Rails.cache.fetch('all_posts', expires_in: 1.hour) do
  Post.published.to_a
end

# With race condition TTL
Rails.cache.fetch('popular_posts', expires_in: 1.hour, race_condition_ttl: 10.seconds) do
  Post.popular.limit(10).to_a
end

# Manual operations
Rails.cache.write('key', value, expires_in: 1.hour)
Rails.cache.read('key')
Rails.cache.delete('key')
Rails.cache.exist?('key')
```

### HTTP Caching

```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])

    # Conditional GET with ETag
    if stale?(@article)
      respond_to do |format|
        format.html
        format.json { render json: @article }
      end
    end
  end

  def index
    @articles = Article.published

    # Cache for all users
    expires_in 1.hour, public: true
  end
end
```

### Cache Store Configuration

```ruby
# config/environments/production.rb

# Redis
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  expires_in: 1.day,
  namespace: 'myapp_cache'
}

# Memcached
config.cache_store = :mem_cache_store, ENV['MEMCACHED_URL']

# Solid Cache (Rails 7+)
config.cache_store = :solid_cache_store
```

## Background Jobs

Move slow operations to background:

```ruby
# Instead of synchronous processing
class OrdersController < ApplicationController
  def create
    @order = Order.create!(order_params)

    # Move to background job
    ProcessOrderJob.perform_later(@order.id)
    SendConfirmationEmailJob.perform_later(@order.id)

    redirect_to @order, notice: 'Order placed!'
  end
end

# Background job
class ProcessOrderJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find(order_id)
    PaymentProcessor.charge(order)
    InventoryService.reserve(order)
  end
end
```

## Counter Caches

Avoid counting queries:

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

## Pagination

Always paginate large collections:

```ruby
# With Kaminari
@users = User.page(params[:page]).per(25)

# With Pagy (faster)
@pagy, @users = pagy(User.all, items: 25)
```

## Asset Optimization

### JavaScript and CSS

```ruby
# config/environments/production.rb
config.assets.compile = false
config.assets.digest = true
config.assets.css_compressor = :sass
config.assets.js_compressor = :terser
```

### Images

```erb
<%# Lazy loading %>
<%= image_tag 'photo.jpg', loading: 'lazy' %>

<%# With Active Storage variants %>
<%= image_tag user.avatar.variant(resize_to_limit: [100, 100]) %>
```

## Profiling Tools

### rack-mini-profiler

```ruby
# Gemfile
gem 'rack-mini-profiler'

# Shows timing badge on each page
# Press Alt+P to show/hide
```

### Benchmark

```ruby
require 'benchmark'

Benchmark.measure { User.all.to_a }

Benchmark.bm do |x|
  x.report('includes') { User.includes(:posts).to_a }
  x.report('preload') { User.preload(:posts).to_a }
end
```

### Memory Profiler

```ruby
require 'memory_profiler'

report = MemoryProfiler.report do
  User.all.to_a
end
report.pretty_print
```

## Performance Checklist

### Database
- [ ] Indexes on foreign keys
- [ ] Indexes on frequently queried columns
- [ ] No N+1 queries (use includes/preload)
- [ ] Avoid SELECT * when possible
- [ ] Use find_each for large datasets
- [ ] Pagination on all listings

### Caching
- [ ] Fragment caching for complex views
- [ ] Collection caching with `cached: true`
- [ ] HTTP caching headers
- [ ] Redis/Memcached in production

### Background Processing
- [ ] Heavy operations in background jobs
- [ ] Email sending async
- [ ] External API calls async

### Assets
- [ ] Minified CSS/JS in production
- [ ] Image optimization
- [ ] CDN for static assets

## Additional Resources

### Reference Files

For advanced optimization techniques, consult:
- **`references/query-optimization.md`** - Advanced query patterns
- **`references/caching-strategies.md`** - Detailed caching approaches

## Quick Reference

| Problem | Solution |
|---------|----------|
| N+1 queries | `includes(:association)` |
| Slow counting | Counter cache |
| Large datasets | `find_each` + pagination |
| Slow views | Fragment caching |
| Slow operations | Background jobs |
| Missing indexes | `add_index` migration |
| Heavy queries | Select only needed columns |

Apply these optimizations to build fast, scalable Rails applications.
