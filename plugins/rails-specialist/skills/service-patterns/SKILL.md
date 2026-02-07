---
name: Rails Service Patterns
description: |
  Service object patterns for Rails applications including Result objects, transaction services, external API wrappers, query objects, and form objects. Use when extracting business logic from controllers or models, implementing multi-step operations, or integrating with external services.
version: 0.1.0
---

# Rails Service Patterns

Service objects encapsulate business logic that doesn't naturally belong in a model or controller. They promote single responsibility, testability, and reusability.

## When to Use Service Objects

**Use a service when:**
- Business logic spans multiple models
- An operation involves external API calls
- Multi-step operations need transaction safety
- Logic doesn't belong in a model (violates SRP)
- Controller actions become complex
- The same logic is needed in multiple places (controller, job, rake task)

**Don't use a service when:**
- The logic is simple and fits naturally in a model
- You're wrapping a single ActiveRecord operation
- A model callback is more appropriate

## Result Object Pattern

A consistent return type for services that communicates success or failure:

```ruby
# app/services/result.rb
class Result
  attr_reader :data, :errors

  def initialize(success:, data: {}, errors: [])
    @success = success
    @data = data
    @errors = Array(errors)
  end

  def success? = @success
  def failure? = !@success

  def self.success(**data)
    new(success: true, data: data)
  end

  def self.failure(errors:)
    new(success: false, errors: Array(errors))
  end

  # Access data attributes as methods
  def method_missing(method, ...)
    @data.key?(method) ? @data[method] : super
  end

  def respond_to_missing?(method, include_private = false)
    @data.key?(method) || super
  end
end
```

### Usage in Controllers

```ruby
class PostsController < ApplicationController
  def create
    result = CreatePost.call(post_params, current_user)

    if result.success?
      redirect_to result.post, notice: 'Post created.'
    else
      @errors = result.errors
      render :new, status: :unprocessable_entity
    end
  end
end
```

## Basic Service Object

```ruby
# app/services/create_post.rb
class CreatePost
  def initialize(params, user)
    @params = params
    @user = user
  end

  def self.call(...)
    new(...).call
  end

  def call
    post = @user.posts.build(@params)

    if post.save
      notify_followers(post)
      Result.success(post: post)
    else
      Result.failure(errors: post.errors.full_messages)
    end
  end

  private

  def notify_followers(post)
    NotifyFollowersJob.perform_later(post.id)
  end
end
```

## Transaction Service

For operations that must succeed or fail atomically:

```ruby
# app/services/transfer_funds.rb
class TransferFunds
  def initialize(from:, to:, amount:)
    @from = from
    @to = to
    @amount = amount
  end

  def self.call(...)
    new(...).call
  end

  def call
    ActiveRecord::Base.transaction do
      @from.withdraw!(@amount)
      @to.deposit!(@amount)
      record = create_transfer_record
      Result.success(transfer: record)
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(errors: e.record.errors.full_messages)
  rescue InsufficientFundsError => e
    Result.failure(errors: [e.message])
  end

  private

  def create_transfer_record
    Transfer.create!(
      from_account: @from,
      to_account: @to,
      amount: @amount,
      completed_at: Time.current
    )
  end
end
```

## External API Service

For integrating with third-party APIs:

```ruby
# app/services/github/create_issue.rb
module GitHub
  class CreateIssue
    def initialize(repo:, title:, body:)
      @repo = repo
      @title = title
      @body = body
    end

    def self.call(...)
      new(...).call
    end

    def call
      issue = client.create_issue(@repo, @title, @body)
      Result.success(issue: issue, url: issue.html_url)
    rescue Octokit::Error => e
      Result.failure(errors: ["GitHub API error: #{e.message}"])
    rescue Faraday::Error => e
      Result.failure(errors: ["Network error: #{e.message}"])
    end

    private

    def client
      @client ||= Octokit::Client.new(
        access_token: Rails.application.credentials.github_token
      )
    end
  end
end
```

## Query Object

For encapsulating complex, reusable queries:

```ruby
# app/queries/active_users_query.rb
class ActiveUsersQuery
  def initialize(relation = User.all)
    @relation = relation
  end

  def call(since: 30.days.ago)
    @relation
      .where('last_sign_in_at > ?', since)
      .where(active: true)
      .order(last_sign_in_at: :desc)
  end
end

# Usage
ActiveUsersQuery.new.call(since: 7.days.ago)
ActiveUsersQuery.new(Organization.find(1).users).call
```

## Form Object

For handling complex form submissions that span multiple models:

```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string
  attribute :company_name, :string
  attribute :plan, :string

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }
  validates :company_name, presence: true
  validates :plan, inclusion: { in: %w[basic pro enterprise] }

  def save
    return Result.failure(errors: errors.full_messages) unless valid?

    ActiveRecord::Base.transaction do
      company = Company.create!(name: company_name, plan: plan)
      user = User.create!(email: email, password: password, company: company)
      Result.success(user: user, company: company)
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(errors: e.record.errors.full_messages)
  end
end
```

## File Organization

```
app/
├── services/
│   ├── result.rb
│   ├── create_post.rb
│   ├── transfer_funds.rb
│   └── github/
│       └── create_issue.rb
├── queries/
│   └── active_users_query.rb
└── forms/
    └── registration_form.rb
```

## Testing Services

```ruby
# spec/services/create_post_spec.rb
RSpec.describe CreatePost do
  let(:user) { create(:user) }
  let(:valid_params) { { title: 'Test', body: 'Content' } }

  describe '.call' do
    context 'with valid params' do
      it 'returns success' do
        result = described_class.call(valid_params, user)
        expect(result).to be_success
      end

      it 'creates a post' do
        expect {
          described_class.call(valid_params, user)
        }.to change(Post, :count).by(1)
      end

      it 'returns the post' do
        result = described_class.call(valid_params, user)
        expect(result.post).to be_a(Post)
        expect(result.post.title).to eq('Test')
      end
    end

    context 'with invalid params' do
      it 'returns failure' do
        result = described_class.call({}, user)
        expect(result).to be_failure
      end

      it 'includes error messages' do
        result = described_class.call({}, user)
        expect(result.errors).to include("Title can't be blank")
      end
    end
  end
end
```

## Design Principles

1. **Single responsibility** — One service does one thing
2. **Clear interface** — `.call` class method with explicit parameters
3. **Consistent return type** — Always return a Result object
4. **Proper error handling** — Catch specific exceptions, never swallow errors
5. **Testability** — Easy to test in isolation, injectable dependencies
6. **Immutability** — Don't modify input arguments

## Quick Reference

| Pattern | Use When |
|---------|----------|
| Service Object | Multi-model business logic |
| Transaction Service | Atomic multi-step operations |
| External API Service | Third-party integrations |
| Query Object | Complex, reusable queries |
| Form Object | Multi-model form submissions |
| Result Object | Consistent service return type |
