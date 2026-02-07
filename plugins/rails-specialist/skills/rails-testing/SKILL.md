---
name: Rails Testing
description: This skill should be used when the user asks about "Rails testing", "RSpec", "Minitest", "test coverage", "factories", "fixtures", "system tests", "request specs", "model specs", or needs help writing or debugging tests. Provides guidance on testing Rails applications with both RSpec and Minitest.
version: 0.1.0
---

# Rails Testing

Guidance for testing Rails applications using RSpec or Minitest, including model specs, request specs, system specs, factories, and fixtures.

## Framework Detection

Check project structure to determine testing framework:
- `spec/` directory with `_spec.rb` files → **RSpec**
- `test/` directory with `_test.rb` files → **Minitest**

## RSpec Setup

### Directory Structure
```
spec/
├── models/           # Model specs
├── requests/         # Request/controller specs
├── system/           # System specs (browser testing)
├── jobs/             # Background job specs
├── mailers/          # Mailer specs
├── helpers/          # Helper specs
├── support/          # Shared helpers, custom matchers
├── factories/        # FactoryBot factories
├── rails_helper.rb   # Rails-specific config
└── spec_helper.rb    # RSpec config
```

### Essential Gems
```ruby
# Gemfile
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'  # or 'playwright-driver'
  gem 'shoulda-matchers'
  gem 'webmock'
  gem 'vcr'
end
```

## Model Specs (RSpec)

```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  # Associations (with shoulda-matchers)
  describe 'associations' do
    it { should belong_to(:organization).optional }
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_one(:profile) }
  end

  # Validations
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  # Scopes
  describe 'scopes' do
    describe '.active' do
      let!(:active_user) { create(:user, active: true) }
      let!(:inactive_user) { create(:user, active: false) }

      it 'returns only active users' do
        expect(User.active).to include(active_user)
        expect(User.active).not_to include(inactive_user)
      end
    end
  end

  # Instance methods
  describe '#full_name' do
    let(:user) { build(:user, first_name: 'John', last_name: 'Doe') }

    it 'returns combined first and last name' do
      expect(user.full_name).to eq('John Doe')
    end

    context 'when last_name is nil' do
      let(:user) { build(:user, first_name: 'John', last_name: nil) }

      it 'returns only first name' do
        expect(user.full_name).to eq('John')
      end
    end
  end
end
```

## Request Specs (RSpec)

```ruby
# spec/requests/articles_spec.rb
RSpec.describe 'Articles', type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  describe 'GET /articles' do
    before { create_list(:article, 3, published: true) }

    it 'returns a list of articles' do
      get articles_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('articles')
    end
  end

  describe 'POST /articles' do
    let(:valid_params) { { article: { title: 'Test', body: 'Content' } } }

    context 'when logged in' do
      before { sign_in user }

      it 'creates a new article' do
        expect {
          post articles_path, params: valid_params
        }.to change(Article, :count).by(1)

        expect(response).to redirect_to(Article.last)
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        post articles_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /articles/:id' do
    before { sign_in user }

    it 'deletes the article' do
      article # create it

      expect {
        delete article_path(article)
      }.to change(Article, :count).by(-1)
    end
  end
end
```

## System Specs (RSpec)

```ruby
# spec/system/user_registration_spec.rb
RSpec.describe 'User Registration', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  it 'allows a user to sign up' do
    visit new_user_registration_path

    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Password confirmation', with: 'password123'
    click_button 'Sign up'

    expect(page).to have_content('Welcome')
    expect(page).to have_current_path(root_path)
  end

  it 'shows errors for invalid registration' do
    visit new_user_registration_path
    click_button 'Sign up'

    expect(page).to have_content("Email can't be blank")
  end
end
```

## FactoryBot

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { 'password123' }

    trait :admin do
      role { 'admin' }
    end

    trait :with_posts do
      after(:create) do |user|
        create_list(:post, 3, user: user)
      end
    end

    factory :admin_user, traits: [:admin]
  end
end

# spec/factories/articles.rb
FactoryBot.define do
  factory :article do
    user
    title { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    published { false }

    trait :published do
      published { true }
      published_at { Time.current }
    end
  end
end
```

### Factory Usage
```ruby
# Build (in memory)
user = build(:user)

# Create (persisted)
user = create(:user)

# Create with overrides
user = create(:user, name: 'Custom Name')

# Create with trait
admin = create(:user, :admin)

# Create list
users = create_list(:user, 5)

# Build attributes hash
attributes = attributes_for(:user)
```

## Minitest Setup

### Directory Structure
```
test/
├── models/           # Model tests
├── controllers/      # Controller tests (integration)
├── integration/      # Integration tests
├── system/           # System tests
├── jobs/             # Job tests
├── mailers/          # Mailer tests
├── helpers/          # Helper tests
├── fixtures/         # YAML fixtures
├── test_helper.rb    # Test configuration
└── application_system_test_case.rb
```

## Model Tests (Minitest)

```ruby
# test/models/user_test.rb
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'should not save user without email' do
    user = User.new(name: 'Test')
    assert_not user.save, 'Saved user without email'
  end

  test 'email should be unique' do
    user = User.new(email: users(:john).email, name: 'Another')
    assert_not user.valid?
    assert_includes user.errors[:email], 'has already been taken'
  end

  test 'full_name returns combined name' do
    user = users(:john)
    user.first_name = 'John'
    user.last_name = 'Doe'
    assert_equal 'John Doe', user.full_name
  end
end
```

## Controller Tests (Minitest)

```ruby
# test/controllers/articles_controller_test.rb
require 'test_helper'

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @article = articles(:one)
    @user = users(:john)
  end

  test 'should get index' do
    get articles_url
    assert_response :success
  end

  test 'should create article when logged in' do
    sign_in @user

    assert_difference('Article.count') do
      post articles_url, params: {
        article: { title: 'New Article', body: 'Content' }
      }
    end

    assert_redirected_to article_url(Article.last)
  end

  test 'should not create article when not logged in' do
    assert_no_difference('Article.count') do
      post articles_url, params: {
        article: { title: 'New Article', body: 'Content' }
      }
    end

    assert_redirected_to new_user_session_url
  end
end
```

## Fixtures (Minitest)

```yaml
# test/fixtures/users.yml
john:
  email: john@example.com
  name: John Doe
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password') %>

jane:
  email: jane@example.com
  name: Jane Doe
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password') %>

# test/fixtures/articles.yml
one:
  user: john
  title: First Article
  body: This is the content
  published: true

two:
  user: jane
  title: Second Article
  body: More content
  published: false
```

## Mocking External Services

### WebMock
```ruby
# Block all external requests
WebMock.disable_net_connect!(allow_localhost: true)

# Stub specific request
stub_request(:get, 'https://api.example.com/users')
  .to_return(status: 200, body: '{"users": []}', headers: { 'Content-Type' => 'application/json' })

# Stub with pattern
stub_request(:post, /api\.stripe\.com/)
  .to_return(status: 200, body: fixture('stripe_charge.json'))
```

### VCR
```ruby
VCR.use_cassette('github_user') do
  response = GithubClient.get_user('octocat')
  expect(response['login']).to eq('octocat')
end
```

## Testing Best Practices

### Arrange-Act-Assert
```ruby
it 'updates the user' do
  # Arrange
  user = create(:user, name: 'Old Name')

  # Act
  user.update(name: 'New Name')

  # Assert
  expect(user.reload.name).to eq('New Name')
end
```

### One Assertion Per Test
```ruby
# Good: Focused tests
it 'returns created status' do
  post users_path, params: valid_params
  expect(response).to have_http_status(:created)
end

it 'creates a user' do
  expect { post users_path, params: valid_params }.to change(User, :count).by(1)
end
```

### Test Behavior, Not Implementation
```ruby
# Good: Tests behavior
it 'sends welcome email after registration' do
  expect { user.register! }.to have_enqueued_mail(UserMailer, :welcome)
end

# Bad: Tests implementation
it 'calls the mailer' do
  expect(UserMailer).to receive(:welcome).with(user)
  user.register!
end
```

## Additional Resources

### Reference Files

For advanced testing patterns, consult:
- **`references/testing-patterns.md`** - Advanced testing techniques
- **`references/factory-patterns.md`** - FactoryBot best practices

## Quick Reference

| Test Type | RSpec Location | Minitest Location |
|-----------|---------------|------------------|
| Model | spec/models/ | test/models/ |
| Controller/Request | spec/requests/ | test/controllers/ |
| System | spec/system/ | test/system/ |
| Job | spec/jobs/ | test/jobs/ |
| Mailer | spec/mailers/ | test/mailers/ |

| Need | RSpec | Minitest |
|------|-------|----------|
| Create test data | `create(:user)` | `users(:john)` |
| Assert equal | `expect(x).to eq(y)` | `assert_equal y, x` |
| Assert true | `expect(x).to be true` | `assert x` |
| Assert raises | `expect { }.to raise_error` | `assert_raises { }` |
| Assert changes | `expect { }.to change { }` | `assert_difference` |

Follow these patterns to write effective, maintainable Rails tests.
