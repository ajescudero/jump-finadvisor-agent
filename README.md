# Jump Finadvisor Agent

> **Status: Deployment Pending**  
> Per Jump’s instructions — *“The app must be fully deployed (to Render or Fly.io or similar) and then submit the url to the app as well as a link to your repo so we can see the code.”*  
> **This deployment step has not been completed yet.** Below you’ll find the exact deployment plan (Render/Fly.io), required env vars, and time estimates to complete it.

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

## Getting Started (Local Dev)

### 1) Prerequisites
- Ruby 3.3.9  
- PostgreSQL 14+  
- Redis  

```bash
bundle install
bin/rails db:prepare
```

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
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`: for OAuth (Dev: Testing mode)  
- `API_TOKEN`: optional, guards write endpoints in API

Helper to load `.env`:
```bash
source bin/envup
echo $DATABASE_URL
```

### 3) Database and seeds
```bash
bin/rails db:migrate
bin/rails db:seed
```

### 4) Run the app (Procfile.dev)
```bash
foreman start -f Procfile.dev
```
- Web: http://localhost:3000  
- Sidekiq: uses `REDIS_URL`

### 5) UI and APIs

UI: http://localhost:3000

API examples:
```bash
# Create by text (auto-embed)
curl -X POST http://localhost:3000/embeddings   -H 'Content-Type: application/json'   -H 'X-API-TOKEN: '"$API_TOKEN"   -d '{"embedding": {"user_id": 1, "kind": "note", "ref_id": "x1", "chunk": "hello world", "content": "hello world"}}'

# Nearest by text
curl -X POST http://localhost:3000/embeddings/nearest   -H 'Content-Type: application/json'   -H 'X-API-TOKEN: '"$API_TOKEN"   -d '{"query_text": "who mentioned baseball?", "limit": 5}'
```

---

## Google OAuth (Dev)

- **Redirect URI:** `/oauth2callback` (absolute: `http://localhost:3000/oauth2callback` and optionally `http://127.0.0.1:3000/oauth2callback`).  
- **Scopes:** Gmail read-only, Calendar read-only.  
- **Test users:** add your account (Audience → Testing) in Google Cloud Console.  
- **ENV:** `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`.

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

- **Healthcheck:** `GET /healthz` → `{ "status": "ok", "checks": { "db": "ok", "vector": "ok|missing", "redis": "ok|fail" } }`
- **API token:** set `API_TOKEN` to protect `POST /embeddings*`.
- **Cron ingestion:** set `ENABLE_CRON=true` (or in production) to schedule periodic Gmail (every 15m) and Calendar (every 30m) ingestions via sidekiq-cron.

---

## Troubleshooting: Supabase connections

If you see errors like `ActiveRecord::ConnectionNotEstablished` or `PG::ConnectionBad` with **"Tenant or user not found"**:

- Pooler? host like `aws-1-*.pooler.supabase.com`, port `6543` → user `postgres.<project-ref>`, `PREPARED_STATEMENTS=false`.  
- Direct? host like `aws-1-*.supabase.com`, port `5432` → user `postgres`, `PREPARED_STATEMENTS=true`.  
- Add `sslmode=require` to `DATABASE_URL` query.

Run:
```bash
bin/rails pgvector:check
```

---

# Deployment (REQUIRED by JUMP) — **Pending**

> **Requirement (from Jump):** *“The app must be fully deployed (to Render or Fly.io or similar) and then submit the url to the app as well as a link to your repo so we can see the code.”*

Below are two supported paths. **We have not deployed yet**; this section documents exactly how to finish it.

## Option A — Deploy to Render (recommended for simplicity)

### Prereqs
- GitHub repo (Render has access).  
- Supabase ready (`DATABASE_URL` using pooler: port **6543**, `PREPARED_STATEMENTS=false`).  
- Managed Redis on Render.  
- Secrets ready:  
  `RAILS_MASTER_KEY`, `DATABASE_URL`, `REDIS_URL`, `EMBEDDING_PROVIDER`, `OPENAI_API_KEY`, `OPENAI_EMBEDDING_MODEL`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `API_TOKEN`.

### Procfile
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
```

### Render Blueprint
Create `render.yaml` in repo root:

```yaml
services:
  - type: web
    name: jump-finadvisor-web
    env: ruby
    buildCommand: bundle install && bundle exec rake assets:precompile
    startCommand: bundle exec puma -C config/puma.rb
    plan: standard
    autoDeploy: true
    envVars:
      - key: RAILS_ENV
        value: production
      - key: RAILS_LOG_TO_STDOUT
        value: "1"
      - key: RAILS_SERVE_STATIC_FILES
        value: "1"
      - key: RAILS_MASTER_KEY
        sync: false
      - key: DATABASE_URL
        sync: false
      - key: PREPARED_STATEMENTS
        value: "false"   # Supabase pooler
      - key: REDIS_URL
        sync: false
      - key: EMBEDDING_PROVIDER
        value: dummy
      - key: OPENAI_API_KEY
        sync: false
      - key: OPENAI_EMBEDDING_MODEL
        value: text-embedding-3-small
      - key: GOOGLE_CLIENT_ID
        sync: false
      - key: GOOGLE_CLIENT_SECRET
        sync: false
      - key: API_TOKEN
        sync: false
    healthCheckPath: /healthz

  - type: worker
    name: jump-finadvisor-worker
    env: ruby
    buildCommand: bundle install && bundle exec rake assets:precompile
    startCommand: bundle exec sidekiq -C config/sidekiq.yml
    plan: standard
    autoDeploy: true
    envVars:
      - key: RAILS_ENV
        value: production
      - key: RAILS_LOG_TO_STDOUT
        value: "1"
      - key: RAILS_MASTER_KEY
        sync: false
      - key: DATABASE_URL
        sync: false
      - key: PREPARED_STATEMENTS
        value: "false"
      - key: REDIS_URL
        sync: false
      - key: EMBEDDING_PROVIDER
        value: dummy
      - key: OPENAI_API_KEY
        sync: false
      - key: OPENAI_EMBEDDING_MODEL
        value: text-embedding-3-small
      - key: GOOGLE_CLIENT_ID
        sync: false
      - key: GOOGLE_CLIENT_SECRET
        sync: false
      - key: ENABLE_CRON
        value: "true"   # enable sidekiq-cron in prod
```

### Migrations on Render
Configure **Post-deploy command** on the web service:
```
bundle exec rails db:migrate
```

### Steps on Render
- New → **Blueprint** → select your repo (Render will detect `render.yaml`).
- Create Render Redis → copy `REDIS_URL` to both services.
- Add all environment variables.
- Deploy.

## Option B — Deploy to Fly.io

### Prereqs
- `flyctl` installed and logged in.
- Supabase `DATABASE_URL` (pooler) and a Redis provider (Upstash or Fly Redis).

### Dockerfile (repo root)
```dockerfile
# syntax=docker/dockerfile:1
FROM ruby:3.3 AS base
RUN apt-get update -y && apt-get install -y build-essential libpq-dev git
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set without "development test"  && bundle install --jobs 4 --retry 3

COPY . .

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=1
ENV RAILS_LOG_TO_STDOUT=1
RUN bundle exec rake assets:precompile

EXPOSE 8080
ENV PORT=8080
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

> Ensure `config/puma.rb` uses `ENV['PORT']`, e.g. `port ENV.fetch("PORT") { 3000 }`.

### fly.toml
```toml
app = "jump-finadvisor"
primary_region = "iad"

[build]
  dockerfile = "Dockerfile"

[env]
  RAILS_ENV = "production"
  RAILS_LOG_TO_STDOUT = "1"
  RAILS_SERVE_STATIC_FILES = "1"
  PREPARED_STATEMENTS = "false"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

# Optionally define separate worker app or process group for Sidekiq
```

### Secrets & Deploy
```bash
fly launch --no-deploy
fly secrets set   RAILS_MASTER_KEY=...   DATABASE_URL=...   REDIS_URL=...   EMBEDDING_PROVIDER=dummy   OPENAI_API_KEY=...   OPENAI_EMBEDDING_MODEL=text-embedding-3-small   GOOGLE_CLIENT_ID=...   GOOGLE_CLIENT_SECRET=...   API_TOKEN=...

fly deploy
# First migration:
fly ssh console -C "bundle exec rails db:migrate"
```

## OAuth in Production

- Add the production URL to **Authorized redirect URIs** in your Google OAuth client:  
  `https://<your-app-domain>/oauth2callback`
- Keep Testing mode and add reviewers’ emails as **Test users**, or proceed to App Verification if needed.

## What to submit (Hiring Team)

- **Public app URL** (Render or Fly.io).  
- **Repository link** (private is fine; share read access to reviewers’ GitHub usernames or make it public temporarily).  
- Note: OAuth is in **Testing** mode; share test user emails if end-to-end OAuth is required.

---

## Current Status (What’s done)

- ✅ pgvector wired with nearest-neighbor queries (cosine/L2/IP)  
- ✅ Embedding providers: `dummy` (dev) and `openai` (prod)  
- ✅ Minimal UI at `/` with Turbo Streams for in-page results  
- ✅ Seeds + sample data; helper `bin/envup`  
- ✅ Google OAuth (Testing mode) with `/oauth2callback` and **DB token store**  
- ✅ Gmail & Calendar **ingestors (jobs)** pulling real data → upserting embeddings (`kind: "email" | "event"`)  
- ✅ Healthcheck (`/healthz`) for DB/pgvector/Redis  
- ✅ Unique index on `(user_id, kind, ref_id)` to dedupe + use `upsert`  
- ✅ Optional API token guard for write endpoints  
- ✅ Dev buttons to trigger ingest on demand (optional)  

## Remaining Work (JUMP scope)

1. **Deploy to Render/Fly.io** (**Required by Jump**) — *Pending*.  
2. **UI polish & filters (S)**; **Retry & rate-limit hardening (S)**; **Cron scheduling (S)**; **OpenAI prod (S)**; **Security pass (S)**; **Docs (XS)**.  
3. **Optional:** HubSpot OAuth (M–L); Proactive agent loop (M–L); Tests (M).

## Time Estimates

- **Deployment (Render or Fly.io):** ~0.5–1 day (including env setup, secrets, and first successful healthcheck).  
- **MVP hardening (remaining S/XS tasks):** ~2–3 days.  
- **Optional features:** HubSpot (3–7 days), Proactive agent (3–5 days), Tests (2–3 days).
