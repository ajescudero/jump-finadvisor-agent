source "https://rubygems.org"

ruby "3.3.9"

# Core framework
gem "rails", "~> 7.1"
gem "puma", "~> 6.4"       # Default Rails server

# Database
gem "pg"                   # PostgreSQL driver
gem "neighbor"             # Vector similarity (pgvector integration)

# Background jobs
gem "sidekiq"              # Background worker with Redis
gem "sidekiq-cron"         # Cron-like scheduled jobs for Sidekiq

# HTTP / APIs
gem "faraday"              # HTTP client for external APIs

# Authentication (Google/HubSpot)
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-google-oauth2"

# Frontend
gem "hotwire-rails"        # Turbo + Stimulus
 gem "tailwindcss-rails"    # TailwindCSS integration
 gem "sprockets-rails"      # Asset pipeline for app/assets
 gem "importmap-rails"      # Importmap for JS (javascript_importmap_tags)

# Utilities
gem "bcrypt", "~> 3.1.7"   # Local user authentication (optional)
gem "bootsnap", "~> 1.18"  # Speed up boot

# === Google APIs (runtime) ===
# These are used by the app and jobs in all environments (dev/test/prod).
gem "google-apis-gmail_v1"
gem "google-apis-calendar_v3"
gem "googleauth"

# Development & test
group :development, :test do
  gem "dotenv-rails"       # Load ENV from .env
  gem "pry"                # Better console
  gem "rspec-rails"        # Testing framework

  # Only needed if you use Google::Auth::Stores::FileTokenStore during local dev.
  # In production we will persist tokens in the DB (Credential), so this is not required there.

  # Sidekiq Web UI (optional, dev only)
end

group :development do
  gem "web-console"        # Browser console
  gem "listen"             # File watcher
  gem "spring"             # Faster boot in dev
  gem "sinatra", require: false
end

group :test do
  gem "capybara"           # Integration testing
  gem "selenium-webdriver" # Browser automation
end

# Production
group :production do
  gem "rails_12factor", "~> 0.0.3" # Logs & assets for Heroku-like envs
end
