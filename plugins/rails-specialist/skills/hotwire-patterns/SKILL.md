---
name: Hotwire Patterns
description: |
  Comprehensive Hotwire patterns for Rails including Turbo Drive, Turbo Frames, Turbo Streams, Stimulus controllers, and ActionCable broadcasting. Use when implementing real-time updates, partial page navigation, or interactive UI without custom JavaScript.
version: 0.1.0
---

# Hotwire Patterns for Rails

Hotwire (HTML Over The Wire) provides a modern approach to building interactive Rails applications with minimal JavaScript. It consists of Turbo (Drive, Frames, Streams) and Stimulus.

## Stimulus Controllers

### Basic Structure

```javascript
// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String, debounce: { type: Number, default: 300 } }
  static classes = ["active", "loading"]

  connect() {
    // Called when controller connects to DOM
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.performSearch()
    }, this.debounceValue)
  }

  performSearch() {
    const query = this.inputTarget.value
    // Perform search...
  }

  disconnect() {
    // Cleanup when controller disconnects
    clearTimeout(this.timeout)
  }
}
```

### Stimulus Conventions

- **Naming**: `data-controller="search"` maps to `search_controller.js`
- **Targets**: `data-search-target="input"` accesses `this.inputTarget`
- **Actions**: `data-action="input->search#search"` calls `search()` method
- **Values**: `data-search-url-value="/api/search"` accesses `this.urlValue`
- **Classes**: `data-search-active-class="highlighted"` accesses `this.activeClass`

### Common Stimulus Patterns

**Toggle:**

```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static classes = ["hidden"]

  toggle() {
    this.contentTarget.classList.toggle(this.hiddenClass)
  }
}
```

```erb
<div data-controller="toggle" data-toggle-hidden-class="hidden">
  <button data-action="click->toggle#toggle">Toggle</button>
  <div data-toggle-target="content">Content here</div>
</div>
```

**Form Submission Feedback:**

```javascript
// app/javascript/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]

  submitting() {
    this.submitTarget.disabled = true
    this.submitTarget.value = "Saving..."
  }
}
```

## Turbo Drive

Turbo Drive intercepts link clicks and form submissions, replacing the `<body>` without full page reloads. It is enabled by default.

### Opting Out

```erb
<%# Disable Turbo for a specific link %>
<%= link_to "External", "https://example.com", data: { turbo: false } %>

<%# Disable Turbo for a form %>
<%= form_with model: @user, data: { turbo: false } do |form| %>
  ...
<% end %>
```

### Progress Bar

```css
/* Customize Turbo progress bar */
.turbo-progress-bar {
  height: 3px;
  background-color: #3b82f6;
}
```

## Turbo Frames

Turbo Frames decompose pages into independently updatable sections.

### Basic Frame

```erb
<%= turbo_frame_tag dom_id(@post) do %>
  <div class="post-card">
    <h2><%= @post.title %></h2>
    <%= link_to "Edit", edit_post_path(@post) %>
  </div>
<% end %>
```

### Lazy Loading

```erb
<%# Loads content asynchronously after page render %>
<%= turbo_frame_tag "comments",
    src: post_comments_path(@post),
    loading: :lazy do %>
  <p>Loading comments...</p>
<% end %>
```

### Breaking Out of Frames

```erb
<%# Navigate outside the frame %>
<%= link_to "View Full Post", post_path(@post), data: { turbo_frame: "_top" } %>
```

### Frame in Edit View

```erb
<%# app/views/posts/edit.html.erb %>
<%= turbo_frame_tag dom_id(@post) do %>
  <%= form_with model: @post do |form| %>
    <%= form.text_field :title %>
    <%= form.submit "Save" %>
    <%= link_to "Cancel", post_path(@post) %>
  <% end %>
<% end %>
```

## Turbo Streams

Turbo Streams deliver page changes as a set of CRUD-like actions targeting DOM elements.

### Stream Actions

| Action | Description |
|--------|-------------|
| `append` | Add to end of container |
| `prepend` | Add to beginning of container |
| `replace` | Replace entire element |
| `update` | Update content of element |
| `remove` | Remove element |
| `before` | Insert before element |
| `after` | Insert after element |
| `morph` | Morph element (Rails 7.1+) |
| `refresh` | Reload page via morph (Rails 7.1+) |

### Controller Response

```ruby
# app/controllers/comments_controller.rb
def create
  @comment = @post.comments.build(comment_params)

  respond_to do |format|
    if @comment.save
      format.turbo_stream
      format.html { redirect_to @post }
    else
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "new_comment",
          partial: "comments/form",
          locals: { comment: @comment }
        )
      }
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

### Stream Template

```erb
<%# app/views/comments/create.turbo_stream.erb %>
<%= turbo_stream.append "comments" do %>
  <%= render @comment %>
<% end %>

<%= turbo_stream.update "comment_count", @post.comments.count %>

<%= turbo_stream.replace "new_comment" do %>
  <%= render "comments/form", comment: Comment.new %>
<% end %>
```

### Inline Streams (from controller)

```ruby
def destroy
  @comment.destroy

  respond_to do |format|
    format.turbo_stream {
      render turbo_stream: [
        turbo_stream.remove(@comment),
        turbo_stream.update("comment_count", @post.comments.count)
      ]
    }
    format.html { redirect_to @post }
  end
end
```

## ActionCable Broadcasting

For real-time updates pushed from the server without a request cycle.

### Model Broadcasting

```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post

  after_create_commit -> {
    broadcast_append_to post,
      target: "comments",
      partial: "comments/comment"
  }

  after_update_commit -> {
    broadcast_replace_to post,
      partial: "comments/comment"
  }

  after_destroy_commit -> {
    broadcast_remove_to post
  }
end
```

### Subscribing in Views

```erb
<%# Subscribe to broadcasts %>
<%= turbo_stream_from @post %>

<div id="comments">
  <%= render @post.comments %>
</div>
```

### Custom Broadcasting

```ruby
# From anywhere in the application
Turbo::StreamsChannel.broadcast_append_to(
  "notifications_#{user.id}",
  target: "notifications",
  partial: "notifications/notification",
  locals: { notification: notification }
)
```

## Turbo Morphing (Rails 7.1+)

Page refreshes that preserve DOM state using morphing instead of replacement:

```erb
<%# Enable page morphing in layout %>
<%= turbo_refreshes_morpho_with :morph %>
<%= turbo_refreshes_scroll_with :preserve %>
```

```ruby
# Trigger a page refresh via morph
respond_to do |format|
  format.turbo_stream { render turbo_stream: turbo_stream.action(:refresh, "") }
end
```

## Review Checklists

### Stimulus

- [ ] Controllers follow naming conventions (`name_controller.js`)
- [ ] Targets, values, and classes are declared as static properties
- [ ] Actions use proper event syntax (`event->controller#method`)
- [ ] No direct DOM queries — use targets instead
- [ ] `disconnect()` cleans up event listeners and timers

### Turbo Frames

- [ ] Frame IDs are unique and meaningful (use `dom_id` helper)
- [ ] Loading states provide user feedback
- [ ] Frame boundaries are logical (don't wrap too much or too little)
- [ ] Non-Turbo fallback works for progressive enhancement

### Turbo Streams

- [ ] Stream actions match the intended DOM update
- [ ] Target elements exist in the DOM before streaming
- [ ] Partials render correctly in isolation
- [ ] Broadcasting scope is appropriate (don't over-broadcast)

### Performance

- [ ] No unnecessary full-page reloads (Turbo Drive not disabled broadly)
- [ ] DOM updates are targeted (prefer replace over full refresh)
- [ ] Caching still works with frames and streams
- [ ] JavaScript bundle size is reasonable

## Quick Reference

| Need | Solution |
|------|----------|
| Navigate without reload | Turbo Drive (default) |
| Update part of a page | Turbo Frames |
| Multiple DOM updates | Turbo Streams |
| Real-time server push | ActionCable + Turbo Streams |
| Client-side behavior | Stimulus controller |
| Form with live updates | Turbo Frame wrapping form |
| Toast notifications | Turbo Stream append |
| Infinite scroll | Turbo Frame with lazy loading |
