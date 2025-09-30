# config/routes.rb
require "sidekiq/web"

Rails.application.routes.draw do
  # --- Auth (Google OAuth) ---
  # Start OAuth and receive the callback
  get "/auth/google",          to: "oauth#google_start"
  get "/auth/google/callback", to: "oauth#google_callback"
  get "/oauth2callback", to: "oauth#google_callback"

  resources :embeddings, only: [:create] do
    collection { post :nearest }
  end
  resources :instructions, only: [:create, :update]
  resources :tasks, only: [:create, :update, :show, :index]

  namespace :ui do
    get "/", to: "embeddings#index"
    resources :embeddings, only: [:index]
  end

  if Rails.env.development?
    mount Sidekiq::Web => "/sidekiq"
  end

  # Dev-only helpers to trigger ingest jobs from the UI
  if Rails.env.development?
    post "/dev/ingest/gmail",    to: ->(env) { GmailIngestJob.perform_now(User.first.id); [302, {"Location"=>"/"}, []] }
    post "/dev/ingest/calendar", to: ->(env) { CalendarIngestJob.perform_now(User.first.id); [302, {"Location"=>"/"}, []] }
  end

  get "/healthz", to: "health#show"
  root to: "ui/embeddings#index"
end
