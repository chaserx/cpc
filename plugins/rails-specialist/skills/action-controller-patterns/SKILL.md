---
name: Action Controller Patterns
description: This skill should be used when the user asks about "Rails controllers", "routing", "before_action", "strong parameters", "params", "respond_to", "filters", or needs help implementing controller actions, routes, or request handling. Provides guidance on Rails controller patterns and best practices.
version: 0.1.0
---

# Action Controller Patterns

Guidance for implementing Rails controllers, routing, request handling, and response patterns for Rails 7+.

## Controller Structure

### Basic Controller

```ruby
class ArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  before_action :authorize_article, only: [:edit, :update, :destroy]

  # GET /articles
  def index
    @articles = Article.published.recent.page(params[:page])
  end

  # GET /articles/:id
  def show; end

  # GET /articles/new
  def new
    @article = current_user.articles.build
  end

  # POST /articles
  def create
    @article = current_user.articles.build(article_params)

    if @article.save
      redirect_to @article, notice: 'Article created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /articles/:id/edit
  def edit; end

  # PATCH/PUT /articles/:id
  def update
    if @article.update(article_params)
      redirect_to @article, notice: 'Article updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /articles/:id
  def destroy
    @article.destroy
    redirect_to articles_url, notice: 'Article deleted.'
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def authorize_article
    redirect_to articles_url, alert: 'Not authorized.' unless @article.user == current_user
  end

  def article_params
    params.require(:article).permit(:title, :body, :published)
  end
end
```

## Strong Parameters

### Basic Usage
```ruby
def user_params
  params.require(:user).permit(:name, :email, :password, :password_confirmation)
end
```

### Nested Attributes
```ruby
def order_params
  params.require(:order).permit(
    :customer_name,
    :shipping_address,
    line_items_attributes: [:id, :product_id, :quantity, :_destroy]
  )
end
```

### Rails 7.2+ expect Syntax
```ruby
def user_params
  params.expect(user: [:name, :email, :password])
end

def order_params
  params.expect(order: [:customer_name, line_items: [[:product_id, :quantity]]])
end
```

### Dynamic Permit
```ruby
def article_params
  permitted = [:title, :body]
  permitted << :featured if current_user.admin?
  params.require(:article).permit(permitted)
end
```

## Before Actions (Filters)

### Common Patterns
```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_locale
  before_action :set_time_zone

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def set_time_zone
    Time.zone = current_user&.time_zone || 'UTC'
  end
end
```

### Conditional Filters
```ruby
class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  before_action :require_admin, if: :admin_action?

  private

  def admin_action?
    action_name.in?(%w[feature unfeature])
  end
end
```

### Skip Filters
```ruby
class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token  # For API controllers
end

class PublicPagesController < ApplicationController
  skip_before_action :authenticate_user!
end
```

## Response Handling

### Respond To (Multiple Formats)
```ruby
def show
  @article = Article.find(params[:id])

  respond_to do |format|
    format.html
    format.json { render json: @article }
    format.xml { render xml: @article }
    format.pdf { send_article_pdf(@article) }
  end
end
```

### Turbo Stream Responses (Rails 7+)
```ruby
def create
  @comment = @article.comments.build(comment_params)

  respond_to do |format|
    if @comment.save
      format.turbo_stream
      format.html { redirect_to @article, notice: 'Comment added.' }
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

### JSON Responses
```ruby
def index
  @users = User.all
  render json: @users
end

def create
  @user = User.new(user_params)
  if @user.save
    render json: @user, status: :created, location: @user
  else
    render json: @user.errors, status: :unprocessable_entity
  end
end
```

### Streaming Responses
```ruby
def export
  headers['Content-Type'] = 'text/csv'
  headers['Content-Disposition'] = 'attachment; filename="users.csv"'

  response.status = 200

  self.response_body = Enumerator.new do |yielder|
    yielder << "name,email\n"
    User.find_each do |user|
      yielder << "#{user.name},#{user.email}\n"
    end
  end
end
```

## Routing

### Basic Resources
```ruby
Rails.application.routes.draw do
  resources :articles
  resources :users, only: [:index, :show]
  resources :sessions, only: [:new, :create, :destroy]
end
```

### Nested Resources
```ruby
resources :articles do
  resources :comments, only: [:create, :destroy]
  resources :likes, only: [:create, :destroy], shallow: true
end
```

### Member and Collection Routes
```ruby
resources :articles do
  member do
    post :publish
    post :unpublish
    get :preview
  end
  collection do
    get :search
    get :drafts
  end
end
```

### Namespaced Routes
```ruby
namespace :admin do
  resources :users
  resources :articles
end

namespace :api do
  namespace :v1 do
    resources :users, only: [:index, :show]
  end
end
```

### Constraints
```ruby
# Subdomain constraint
constraints subdomain: 'api' do
  resources :users
end

# Format constraint
resources :articles, constraints: { format: 'json' }

# Custom constraint
constraints ->(req) { req.env['HTTP_USER_AGENT'] =~ /iPhone/ } do
  resources :mobile_pages
end
```

### Concerns
```ruby
concern :commentable do
  resources :comments, only: [:create, :destroy]
end

concern :likeable do
  resources :likes, only: [:create, :destroy]
end

resources :articles, concerns: [:commentable, :likeable]
resources :photos, concerns: [:commentable, :likeable]
```

## Error Handling

### Rescue From
```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  private

  def not_found
    respond_to do |format|
      format.html { render 'errors/not_found', status: :not_found }
      format.json { render json: { error: 'Not found' }, status: :not_found }
    end
  end

  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  def forbidden
    redirect_to root_path, alert: 'Access denied.'
  end
end
```

## Flash Messages

```ruby
def create
  @user = User.new(user_params)
  if @user.save
    redirect_to @user, notice: 'User created successfully.'
  else
    flash.now[:alert] = 'Please fix the errors below.'
    render :new, status: :unprocessable_entity
  end
end

# Types: :notice, :alert, or custom like :success, :error
redirect_to users_path, flash: { success: 'Welcome!' }
```

## Controller Concerns

Extract shared behavior:

```ruby
# app/controllers/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  def search
    @results = model_class.search(params[:q]).page(params[:page])
    render 'shared/search_results'
  end

  private

  def model_class
    raise NotImplementedError
  end
end

# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  include Searchable

  private

  def model_class
    Article
  end
end
```

## Keep Controllers Thin

Move complex logic to:
- **Service Objects**: Complex business operations
- **Query Objects**: Complex database queries
- **Form Objects**: Multi-model forms
- **Presenters/Decorators**: View logic

```ruby
# Instead of complex controller logic
def create
  result = CreateOrderService.new(current_user, order_params).call

  if result.success?
    redirect_to result.order, notice: 'Order placed!'
  else
    @order = result.order
    flash.now[:alert] = result.error
    render :new, status: :unprocessable_entity
  end
end
```

## Additional Resources

### Reference Files

For advanced patterns and examples, consult:
- **`references/routing-patterns.md`** - Advanced routing techniques
- **`references/api-controllers.md`** - API controller patterns

## Quick Reference

| Need | Solution |
|------|----------|
| Load resource | `before_action :set_resource` |
| Require login | `before_action :authenticate_user!` |
| Whitelist params | `params.require(:model).permit(...)` |
| Multiple formats | `respond_to` block |
| Handle 404 | `rescue_from ActiveRecord::RecordNotFound` |
| Custom route action | `member` or `collection` route |
| Shared controller logic | Controller concern |

Apply these patterns to create clean, maintainable Rails controllers.
