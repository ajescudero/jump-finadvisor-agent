# Jump Finadvisor Agent

An AI-powered assistant for financial advisors built with Ruby on Rails 7.2. It integrates semantic search (pgvector), pluggable embedding providers (OpenAI or a local dummy provider for dev), and exposes minimal APIs and a simple UI to create vectors and query nearest neighbors. Roadmap includes OAuth integrations with Google (Gmail/Calendar) and HubSpot for RAG over user data and proactive agent actions.

## Stack
- Ruby 3.3.9, Rails 7.2.2.2
- PostgreSQL (Supabase), pgvector extension
- Hotwire (Turbo + Stimulus) with Importmap and TailwindCSS
- Sidekiq for background jobs (Redis)
- Faraday for external HTTP APIs

## Features (MVP)
- Embedding provider abstraction with:
  - Dummy provider (deterministic, no external calls) for development
  - OpenAI provider for production
- REST API
  - POST /embeddings — create/update an embedding (accepts vector or raw text)
  - POST /embeddings/nearest — nearest-neighbor search by vector or text
  - Tasks and Instructions endpoints scaffolded for agent memory/actions
- Minimal UI (Hotwire) at / to create embeddings and run searches

## Getting Started

### 1) Clone and prerequisites
- Ruby 3.3.9, PostgreSQL 14+, Redis
- Bundler installed

```
bundle install
bin/rails db:prepare
```

### 2) Environment variables
Copy .env.example to .env and edit values.

Important variables:
- DATABASE_URL: Use your Supabase connection string. For pooler (port 6543) use the project-specific user `postgres.<project-ref>` and set `PREPARED_STATEMENTS=false`. For direct DB (port 5432), you may set `PREPARED_STATEMENTS=true`.
- PREPARED_STATEMENTS: Defaults to false (good for Supabase pooler). Override as needed.
- REDIS_URL: e.g., redis://localhost:6379/0
- EMBEDDING_PROVIDER: `dummy` (default) or `openai`
- OPENAI_API_KEY, OPENAI_EMBEDDING_MODEL: required if provider is `openai`
- DEMO_USER_EMAIL: email used by seeds (default dev@local.test)

### 3) Database and seeds
Ensure your database has pgvector extension enabled. If using Supabase, pgvector is available by default.

Run migrations and seeds:
```
bin/rails db:migrate
bin/rails db:seed
```

### 4) Run the app (Procfile.dev)
Use Foreman or Overmind to run web + tailwind + sidekiq:
```
foreman start -f Procfile.dev
```
Services:
- Web: http://localhost:3000
- Sidekiq: uses REDIS_URL

### 5) Use the UI and APIs
- UI: Open http://localhost:3000 and create embeddings or query nearest neighbors.
- API examples (curl):

Create by text (auto-embed):
```
curl -X POST http://localhost:3000/embeddings \
  -H 'Content-Type: application/json' \
  -d '{"embedding": {"user_id": 1, "kind": "note", "ref_id": "x1", "chunk": "hello world", "content": "hello world"}}'
```

Nearest by text:
```
curl -X POST http://localhost:3000/embeddings/nearest \
  -H 'Content-Type: application/json' \
  -d '{"query_text": "who mentioned baseball?", "limit": 5}'
```

### Background jobs
Sidekiq is included for future ingestion/vectorization jobs. Configure Redis via REDIS_URL.

## Development Notes
- Importmap is used for JavaScript (`javascript_importmap_tags`). No Node/npm required.
- Sprockets asset pipeline is enabled; Tailwind is provided via tailwindcss-rails.
- Prepared statements are disabled by default to work with Supabase pgBouncer. You can enable them when connecting directly to Postgres.

## Deployment
- Provision PostgreSQL with pgvector (Supabase recommended) and Redis.
- Set DATABASE_URL and PREPARED_STATEMENTS appropriately (see .env.example).
- Ensure RAILS_SERVE_STATIC_FILES=1 and proper secrets set in production.
- Run:
```
bundle exec rails db:migrate
bundle exec puma -C config/puma.rb
```

## Roadmap
- Google OAuth login and Gmail/Calendar ingestion (RAG)
- HubSpot OAuth and data ingestion (contacts, notes)
- Proactive agent with instructions + tool calling via background jobs
- Tests (RSpec) and production deploy templates (Render/Fly)
