#!/bin/bash
set -euo pipefail

# Rails Convention Validator
# Validates that file writes follow Rails naming conventions
# Exit 0: Allow (valid or not a Rails file)
# Exit 2: Block (convention violation)

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# If no file path, allow
if [ -z "$file_path" ]; then
  exit 0
fi

# Only validate if this looks like a Rails project
# Check for common Rails indicators
if [ ! -f "Gemfile" ] || ! grep -q "rails" Gemfile 2>/dev/null; then
  exit 0
fi

# Extract filename and directory
filename=$(basename "$file_path")
dirname=$(dirname "$file_path")

# Helper function to check snake_case
is_snake_case() {
  local name="$1"
  # Remove extension for checking
  local base="${name%.*}"
  # Check if it matches snake_case pattern (lowercase, underscores, numbers)
  [[ "$base" =~ ^[a-z][a-z0-9_]*$ ]]
}

# Helper function to output error
deny_with_reason() {
  local reason="$1"
  echo "{\"hookSpecificOutput\": {\"permissionDecision\": \"deny\"}, \"systemMessage\": \"Rails Convention Violation: $reason\"}" >&2
  exit 2
}

# Validate app/models/ files
if [[ "$file_path" == *"app/models/"* ]] && [[ "$filename" == *.rb ]]; then
  model_name="${filename%.rb}"

  # Models should be singular and snake_case
  if ! is_snake_case "$model_name"; then
    deny_with_reason "Model file '$filename' should be snake_case (e.g., user.rb, order_item.rb)"
  fi

  # Check for accidental pluralization
  if [[ "$model_name" == *s ]] && [[ ! "$model_name" == *ss ]] && [[ ! "$model_name" == *us ]] && [[ ! "$model_name" == *is ]]; then
    # Could be plural - warn but allow (some models like 'news' are valid)
    # For strict mode, we block obvious plurals
    if [[ "$model_name" =~ (users|posts|comments|articles|orders|products|items|categories|tags)$ ]]; then
      deny_with_reason "Model file '$filename' appears to be plural. Rails models should be singular (e.g., user.rb not users.rb)"
    fi
  fi
fi

# Validate app/controllers/ files
if [[ "$file_path" == *"app/controllers/"* ]] && [[ "$filename" == *.rb ]]; then
  controller_name="${filename%.rb}"

  # Controllers should be snake_case and end with _controller
  if ! is_snake_case "$controller_name"; then
    deny_with_reason "Controller file '$filename' should be snake_case (e.g., users_controller.rb)"
  fi

  if [[ ! "$controller_name" == *_controller ]]; then
    # Allow application.rb and concerns
    if [[ "$controller_name" != "application" ]] && [[ "$dirname" != *"/concerns"* ]]; then
      deny_with_reason "Controller file '$filename' should end with _controller.rb (e.g., users_controller.rb)"
    fi
  fi
fi

# Validate app/helpers/ files
if [[ "$file_path" == *"app/helpers/"* ]] && [[ "$filename" == *.rb ]]; then
  helper_name="${filename%.rb}"

  if ! is_snake_case "$helper_name"; then
    deny_with_reason "Helper file '$filename' should be snake_case"
  fi

  if [[ ! "$helper_name" == *_helper ]] && [[ "$helper_name" != "application" ]]; then
    deny_with_reason "Helper file '$filename' should end with _helper.rb (e.g., users_helper.rb)"
  fi
fi

# Validate app/jobs/ files
if [[ "$file_path" == *"app/jobs/"* ]] && [[ "$filename" == *.rb ]]; then
  job_name="${filename%.rb}"

  if ! is_snake_case "$job_name"; then
    deny_with_reason "Job file '$filename' should be snake_case"
  fi

  if [[ ! "$job_name" == *_job ]] && [[ "$job_name" != "application" ]]; then
    deny_with_reason "Job file '$filename' should end with _job.rb (e.g., send_email_job.rb)"
  fi
fi

# Validate app/mailers/ files
if [[ "$file_path" == *"app/mailers/"* ]] && [[ "$filename" == *.rb ]]; then
  mailer_name="${filename%.rb}"

  if ! is_snake_case "$mailer_name"; then
    deny_with_reason "Mailer file '$filename' should be snake_case"
  fi

  if [[ ! "$mailer_name" == *_mailer ]] && [[ "$mailer_name" != "application" ]]; then
    deny_with_reason "Mailer file '$filename' should end with _mailer.rb (e.g., user_mailer.rb)"
  fi
fi

# Validate db/migrate/ files
if [[ "$file_path" == *"db/migrate/"* ]] && [[ "$filename" == *.rb ]]; then
  # Migration files should start with timestamp and be snake_case
  if [[ ! "$filename" =~ ^[0-9]{14}_ ]]; then
    deny_with_reason "Migration file '$filename' should start with 14-digit timestamp (e.g., 20240101120000_create_users.rb)"
  fi
fi

# Validate spec/ files (RSpec)
if [[ "$file_path" == *"spec/"* ]] && [[ "$filename" == *.rb ]]; then
  spec_name="${filename%.rb}"

  if ! is_snake_case "$spec_name"; then
    deny_with_reason "Spec file '$filename' should be snake_case"
  fi

  # Spec files should end with _spec
  if [[ ! "$spec_name" == *_spec ]]; then
    # Allow spec_helper, rails_helper, and support files
    if [[ "$spec_name" != "spec_helper" ]] && [[ "$spec_name" != "rails_helper" ]] && [[ "$dirname" != *"/support"* ]] && [[ "$dirname" != *"/factories"* ]]; then
      deny_with_reason "Spec file '$filename' should end with _spec.rb (e.g., user_spec.rb)"
    fi
  fi
fi

# Validate test/ files (Minitest)
if [[ "$file_path" == *"test/"* ]] && [[ "$filename" == *.rb ]]; then
  test_name="${filename%.rb}"

  if ! is_snake_case "$test_name"; then
    deny_with_reason "Test file '$filename' should be snake_case"
  fi

  # Test files should end with _test
  if [[ ! "$test_name" == *_test ]]; then
    # Allow test_helper and support files
    if [[ "$test_name" != "test_helper" ]] && [[ "$test_name" != "application_system_test_case" ]] && [[ "$dirname" != *"/fixtures"* ]]; then
      deny_with_reason "Test file '$filename' should end with _test.rb (e.g., user_test.rb)"
    fi
  fi
fi

# Validate view files
if [[ "$file_path" == *"app/views/"* ]]; then
  # Views should be snake_case (partials start with underscore)
  view_name="${filename%.*}"  # Remove all extensions like .html.erb
  view_name="${view_name%.*}"  # Remove second extension if present

  # Allow partials (start with _)
  if [[ "$view_name" == _* ]]; then
    partial_name="${view_name#_}"
    if ! is_snake_case "$partial_name" && [[ "$partial_name" != "" ]]; then
      deny_with_reason "Partial file '$filename' should be snake_case after underscore (e.g., _user_info.html.erb)"
    fi
  else
    # Non-partial views should be snake_case
    if [[ "$view_name" != "" ]] && ! is_snake_case "$view_name"; then
      deny_with_reason "View file '$filename' should be snake_case (e.g., index.html.erb, show.html.erb)"
    fi
  fi
fi

# If we get here, the file passes all checks
exit 0
