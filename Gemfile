source "https://rubygems.org"

ruby "3.3.9"

# Core framework
gem "rails", "~> 7.1"

# Database
gem "pg"          # PostgreSQL driver
gem "neighbor"

# Background jobs
gem "sidekiq"     # Background worker with Redis

# HTTP / APIs
gem "faraday"     # HTTP client for external APIs

# Authentication (Google/HubSpot)
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-google-oauth2"

# Frontend
gem "hotwire-rails"       # Turbo + Stimulus for realtime chat-like UI
gem "tailwindcss-rails"   # TailwindCSS integration for styling
gem "sprockets-rails"     # Asset pipeline for app/assets (required for config.assets.*)

# Utilities
gem "bcrypt", "~> 3.1.7"  # Optional, for local user authentication if needed

# Development & test
group :development, :test do
  gem "dotenv-rails"    # Environment variables from .env
  gem "pry"             # Better debugging console
  gem "rspec-rails"     # Testing framework
end

group :development do
  gem "web-console"     # Interactive console in browser
  gem "listen"          # Auto-reloading of files
  gem "spring"          # Speed up development (optional)
end

group :test do
  gem "capybara"        # Integration testing
  gem "selenium-webdriver"
end

# Production
group :production do
  gem "rails_12factor", "~> 0.0.3" # Logs & assets in Render/Heroku-like envs
end

gem "bootsnap", "~> 1.18"
