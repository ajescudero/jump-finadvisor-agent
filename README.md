# Jump Finadvisor Agent

An AI-powered assistant for financial advisors built with Ruby on Rails 7.2.  
It integrates semantic search (pgvector), pluggable embedding providers (OpenAI or a local dummy provider for dev), and exposes minimal APIs and a simple UI to create vectors and query nearest neighbors.  
Roadmap includes OAuth integrations with Google (Gmail/Calendar) and HubSpot for RAG over user data and proactive agent actions.

---

## Stack

- Ruby 3.3.9, Rails 7.2.2.2  
- PostgreSQL (Supabase), pgvector extension  
- Hotwire (Turbo + Stimulus) with Importmap and TailwindCSS  
- Sidekiq for background jobs (Redis)  
- Faraday for external HTTP APIs  

---

## Features (MVP)

- Embedding provider abstraction with:
  - Dummy provider (deterministic, no external calls) for development
  - OpenAI provider for production
- REST API
  - `POST /embeddings` — create/update an embedding (accepts vector or raw text)
  - `POST /embeddings/nearest` — nearest-neighbor search by vector or text
- Tasks and Instructions endpoints scaffolded for agent memory/actions
- Minimal UI (Hotwire) at `/` to create embeddings and run searches

---

## Getting Started

### 1) Clone and prerequisites
- Ruby 3.3.9  
- PostgreSQL 14+  
- Redis  

```bash
bundle install
bin/rails db:prepare
```

---

### 2) Environment variables

Copy `.env.example` to `.env` and edit values.

Important variables:

- `DATABASE_URL`: Use your Supabase connection string.  
  - For pooler (port 6543) use the project-specific user `postgres.<project-ref>` and set `PREPARED_STATEMENTS=false`.  
  - For direct DB (port 5432), you may set `PREPARED_STATEMENTS=true`.  
- `PREPARED_STATEMENTS`: Defaults to false (good for Supabase pooler). Override as needed.  
- `REDIS_URL`: e.g., `redis://localhost:6379/0`  
- `EMBEDDING_PROVIDER`: `dummy` (default) or `openai`  
- `OPENAI_API_KEY`, `OPENAI_EMBEDDING_MODEL`: required if provider is `openai`  
- `DEMO_USER_EMAIL`: email used by seeds (default `dev@local.test`)  

#### Helper: load `.env`

We provide `bin/envup` to safely load `.env` into your shell:

```bash
# Load environment variables into current shell
source bin/envup

# Verify
echo $DATABASE_URL
```

- Ignores comments and blank lines  
- Strips Windows CRLF endings if present  
- Exports variables so they are available to Rails, Foreman, Sidekiq, etc.  

---

### 3) Database and seeds

Ensure your database has pgvector extension enabled. If using Supabase, pgvector is available by default.

Run migrations and seeds:

```bash
bin/rails db:migrate
bin/rails db:seed
```

---

### 4) Run the app (Procfile.dev)

Use Foreman or Overmind to run web + tailwind + sidekiq:

```bash
foreman start -f Procfile.dev
```

Services:

- Web: http://localhost:3000  
- Sidekiq: uses `REDIS_URL`  

---

### 5) Use the UI and APIs

**UI:** Open http://localhost:3000 and create embeddings or query nearest neighbors.

**API examples (curl):**

Create by text (auto-embed):
```bash
curl -X POST http://localhost:3000/embeddings   -H 'Content-Type: application/json'   -d '{"embedding": {"user_id": 1, "kind": "note", "ref_id": "x1", "chunk": "hello world", "content": "hello world"}}'
```

Nearest by text:
```bash
curl -X POST http://localhost:3000/embeddings/nearest   -H 'Content-Type: application/json'   -d '{"query_text": "who mentioned baseball?", "limit": 5}'
```

---

## Background jobs

Sidekiq is included for future ingestion/vectorization jobs. Configure Redis via `REDIS_URL`.

---

## Development Notes

- Importmap is used for JavaScript (`javascript_importmap_tags`). No Node/npm required.  
- Sprockets asset pipeline is enabled; Tailwind is provided via `tailwindcss-rails`.  
- Prepared statements are disabled by default to work with Supabase pgBouncer. You can enable them when connecting directly to Postgres.  

---

## Deployment

- Provision PostgreSQL with pgvector (Supabase recommended) and Redis.  
- Set `DATABASE_URL` and `PREPARED_STATEMENTS` appropriately (see `.env.example`).  
- Ensure `RAILS_SERVE_STATIC_FILES=1` and proper secrets set in production.  

Run:
```bash
bundle exec rails db:migrate
bundle exec puma -C config/puma.rb
```

---

## Roadmap

- Google OAuth login and Gmail/Calendar ingestion (RAG)  
- HubSpot OAuth and data ingestion (contacts, notes)  
- Proactive agent with instructions + tool calling via background jobs  
- Tests (RSpec) and production deploy templates (Render/Fly)  

---

## Troubleshooting: Supabase connections

If you see errors like `ActiveRecord::ConnectionNotEstablished` or `PG::ConnectionBad` with messages such as **"Tenant or user not found"** when running `bin/rails pgvector:check` or starting the app:

Checklist:

- Using Supabase pooler? Host looks like `aws-1-*.pooler.supabase.com` and port is `6543`.  
  - Username must be project-specific: `postgres.<your-project-ref>`  
  - Set `PREPARED_STATEMENTS=false`  
- Connecting directly (no pooler)? Host is `aws-1-*.supabase.com` and port is `5432`.  
  - Use username `postgres`  
  - Set `PREPARED_STATEMENTS=true`  
- Ensure `sslmode=require` in the `DATABASE_URL` query parameters when connecting to cloud Postgres.  

Examples:

**Pooler (recommended for app servers):**
```env
DATABASE_URL=postgresql://postgres.rhyrgouiockrmmaxzjht:YOUR_PW@aws-1-sa-east-1.pooler.supabase.com:6543/postgres?sslmode=require
PREPARED_STATEMENTS=false
```

**Direct (useful for scripts/migrations):**
```env
DATABASE_URL=postgresql://postgres:YOUR_PW@aws-1-sa-east-1.supabase.com:5432/postgres?sslmode=require
PREPARED_STATEMENTS=true
```

You can also run:
```bash
bin/rails pgvector:check
```
It will print environment diagnostics (host/port/db/user masked) and warn about common misconfigurations.

---

## Tests

RSpec is included with smoke tests for critical endpoints.

Run all tests:
```bash
bundle exec rspec
```

Smoke tests cover:

- `/healthz` endpoint (if defined in routes)  
- `POST /embeddings/nearest` endpoint (if defined in routes)  

They skip gracefully if the route does not exist, avoiding false negatives.


## Google OAuth (Dev)

- Redirect URI: `/oauth2callback` (absolute: `http://localhost:3000/oauth2callback` and optionally `http://127.0.0.1:3000/oauth2callback`).
- Scopes: Gmail read-only, Calendar read-only.
- Test users: add your account (Audience → Testing) in Google Cloud Console.
- ENV: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` (and optionally `GOOGLE_REDIRECT_URI` if you need to override host/port).

Runbook:

```bash
source bin/envup
foreman start -f Procfile.dev
open http://localhost:3000/auth/google   # redirects to Google; upon success shows "Google connected"

# Ingest from terminal (after connecting):
uid=$(bin/rails runner 'print User.first.id')
bin/rails ingest:gmail[$uid]
bin/rails ingest:calendar[$uid]
```

---

## Operational

- Healthcheck: `GET /healthz` returns JSON with DB, pgvector, and Redis status:
  `{ "status": "ok", "checks": { "db": "ok", "vector": "ok|missing", "redis": "ok|fail" } }`
- API token: Set `API_TOKEN` to protect `POST /embeddings` and `POST /embeddings/nearest` from unauthorized writes.
- Cron ingestion: Set `ENABLE_CRON=true` (or run in production) to schedule periodic Gmail (every 15m) and Calendar (every 30m) ingestions via sidekiq-cron.

---

## Background jobs

Sidekiq is included for ingestion/vectorization jobs. Configure Redis via `REDIS_URL`.

- Development dashboard: http://localhost:3000/sidekiq (dev only)
- Cron: Enabled when `ENABLE_CRON=true` or in production; see `config/initializers/sidekiq_cron.rb`.
- Retry/backoff: Gmail/Calendar ingestors retry on 429/5xx up to 3 times with exponential backoff.

---

## Troubleshooting

- Supabase pooler “Tenant or user not found”: Use the project-specific username `postgres.<project-ref>` on port 6543 and set `PREPARED_STATEMENTS=false`. For direct connections on 5432, set `PREPARED_STATEMENTS=true`.
- Check pgvector and index:

```bash
bin/rails pgvector:check
```

- OAuth redirect mismatch: ensure the exact redirect URI is registered in Google Cloud Console and matches the app (`/oauth2callback`). You can set `GOOGLE_REDIRECT_URI` if you use a different host/port or an ngrok URL.

## Data ingestion and filters

- GmailIngestJob now also stores structured Gmail messages in the Messages table (subject, sender, sent_at, body_text) in addition to embeddings (kind: "email").
- CalendarIngestJob stores structured Calendar events in the Notes table (source: "google_calendar", ext_id, body_text, created_at_ext) and embeds them (kind: "event").
- The Nearest search form lets you filter by kind (All, Events, Emails) and will scope results to the selected user.
- When API_TOKEN is set, the UI form passes it as a hidden param so you can use the in-browser search without custom headers (only in dev; for production prefer headers).
