---
name: Rails Security
description: This skill should be used when the user asks about "Rails security", "authentication", "authorization", "Devise", "Pundit", "CanCanCan", "CSRF", "XSS", "SQL injection", "secrets management", "secure coding", or needs help implementing secure Rails applications. Provides guidance on Rails security best practices.
version: 0.1.0
---

# Rails Security

Guidance for implementing secure Rails applications, including authentication, authorization, and protection against common vulnerabilities.

## OWASP Top 10 in Rails

### 1. SQL Injection Prevention

Rails ActiveRecord prevents SQL injection by default, but raw SQL is dangerous:

```ruby
# SAFE: Parameterized queries
User.where(email: params[:email])
User.where('email = ?', params[:email])
User.where('email = :email', email: params[:email])

# DANGEROUS: String interpolation
User.where("email = '#{params[:email]}'")  # SQL injection!
User.where("email = " + params[:email])     # SQL injection!
```

### 2. Cross-Site Scripting (XSS) Prevention

Rails escapes output by default in ERB:

```erb
<%# SAFE: Auto-escaped %>
<%= @user.name %>
<%= @user.bio %>

<%# DANGEROUS: Bypasses escaping %>
<%= raw @user.bio %>
<%= @user.bio.html_safe %>
<%== @user.bio %>
```

When raw HTML is necessary, sanitize it:
```ruby
<%= sanitize @user.bio, tags: %w[p br strong em], attributes: %w[class] %>
```

### 3. Cross-Site Request Forgery (CSRF)

CSRF protection is enabled by default:

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# In forms (automatic with form_with)
<%= form_with model: @user do |f| %>
  <%# CSRF token automatically included %>
<% end %>
```

For API controllers, disable CSRF but use token authentication:
```ruby
class Api::BaseController < ActionController::API
  # No CSRF for API, but authenticate with tokens
  before_action :authenticate_api_token!
end
```

### 4. Broken Authentication

Use Devise with secure defaults:

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.stretches = Rails.env.test? ? 1 : 12
  config.pepper = Rails.application.credentials.devise_pepper
  config.password_length = 12..128
  config.timeout_in = 30.minutes
  config.lock_strategy = :failed_attempts
  config.maximum_attempts = 5
  config.unlock_strategy = :time
  config.unlock_in = 1.hour
end
```

### 5. Broken Access Control (Authorization)

Implement proper authorization:

```ruby
# With Pundit
class ArticlePolicy < ApplicationPolicy
  def update?
    record.user == user || user.admin?
  end

  def destroy?
    record.user == user || user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end

# In controller
class ArticlesController < ApplicationController
  def update
    @article = Article.find(params[:id])
    authorize @article

    if @article.update(article_params)
      redirect_to @article
    else
      render :edit
    end
  end
end
```

## Strong Parameters

Always whitelist parameters:

```ruby
def user_params
  params.require(:user).permit(:name, :email, :avatar)
end

# Never do this:
User.create(params[:user])  # Mass assignment vulnerability!
```

Nested attributes:
```ruby
def order_params
  params.require(:order).permit(
    :customer_name,
    :total,
    line_items_attributes: [:id, :product_id, :quantity, :_destroy]
  )
end
```

## Secrets Management

### Rails Credentials (Rails 5.2+)

```bash
# Edit credentials
EDITOR="code --wait" rails credentials:edit

# Access in code
Rails.application.credentials.secret_api_key
Rails.application.credentials.dig(:aws, :access_key_id)
```

Environment-specific credentials:
```bash
rails credentials:edit --environment production
```

### Environment Variables

```ruby
# config/database.yml
production:
  url: <%= ENV['DATABASE_URL'] %>

# In code
api_key = ENV.fetch('API_KEY') { raise 'API_KEY required' }
```

Never commit secrets:
```gitignore
# .gitignore
.env
.env.local
config/master.key
config/credentials/*.key
```

## Authentication Best Practices

### Password Security
```ruby
class User < ApplicationRecord
  has_secure_password

  validates :password, length: { minimum: 12 },
                       format: {
                         with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
                         message: 'must include uppercase, lowercase, and number'
                       },
                       if: :password_required?

  private

  def password_required?
    new_record? || password.present?
  end
end
```

### Session Security
```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: '_myapp_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax,
  expire_after: 24.hours
```

### Password Reset
```ruby
class PasswordResetsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    # Always show same response to prevent email enumeration
    if user
      user.send_reset_password_instructions
    end
    redirect_to login_path, notice: 'If email exists, reset instructions sent.'
  end
end
```

## HTTP Security Headers

```ruby
# config/initializers/secure_headers.rb
# Using secure_headers gem
SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.content_security_policy = {
    default_src: %w['self'],
    script_src: %w['self'],
    style_src: %w['self' 'unsafe-inline'],
    img_src: %w['self' data:],
    font_src: %w['self'],
    connect_src: %w['self'],
    frame_ancestors: %w['none']
  }
end

# Or manually in ApplicationController
class ApplicationController < ActionController::Base
  before_action :set_security_headers

  private

  def set_security_headers
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
  end
end
```

## File Upload Security

```ruby
class Document < ApplicationRecord
  has_one_attached :file

  validate :acceptable_file

  private

  def acceptable_file
    return unless file.attached?

    # Check file type
    unless file.content_type.in?(%w[application/pdf image/png image/jpeg])
      errors.add(:file, 'must be PDF, PNG, or JPEG')
    end

    # Check file size
    if file.byte_size > 10.megabytes
      errors.add(:file, 'must be less than 10MB')
    end
  end
end
```

## Rate Limiting

```ruby
# Using Rack::Attack
class Rack::Attack
  # Limit login attempts
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == '/login' && req.post?
  end

  # Limit API requests
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api')
  end

  # Block suspicious requests
  blocklist('block bad IPs') do |req|
    Blocklist.blocked?(req.ip)
  end
end
```

## Logging Security

Never log sensitive data:

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password, :password_confirmation,
  :secret, :token, :api_key,
  :credit_card, :cvv, :ssn
]

# Custom filtering
class ApplicationController < ActionController::Base
  before_action :filter_sensitive_params

  private

  def filter_sensitive_params
    request.filtered_parameters # Uses filter_parameters config
  end
end
```

## Security Checklist

### Before Deployment
- [ ] All secrets in credentials or environment variables
- [ ] master.key not in version control
- [ ] HTTPS enforced in production
- [ ] Secure session configuration
- [ ] Strong parameters for all forms
- [ ] Authorization on all actions
- [ ] Rate limiting configured
- [ ] Security headers set
- [ ] File upload validation
- [ ] Dependency vulnerabilities checked (bundle audit)

### Ongoing
- [ ] Regular dependency updates
- [ ] Security monitoring (Brakeman, bundler-audit)
- [ ] Log review for suspicious activity
- [ ] Penetration testing

## Additional Resources

### Reference Files

For detailed security patterns, consult:
- **`references/authentication-patterns.md`** - Authentication implementation
- **`references/authorization-patterns.md`** - Pundit and CanCanCan patterns

## Quick Reference

| Vulnerability | Prevention |
|---------------|------------|
| SQL Injection | Use parameterized queries |
| XSS | Don't use `raw` or `html_safe` on user input |
| CSRF | Keep `protect_from_forgery` enabled |
| Mass Assignment | Use strong parameters |
| Session Hijacking | Secure, httponly, same_site cookies |
| Broken Auth | Use Devise with secure settings |
| Broken Access | Implement Pundit or CanCanCan |

Follow these security practices to build robust, secure Rails applications.
