require "sidekiq/web"

Rails.application.routes.draw do
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

  get "/healthz", to: "health#show"
  root to: "ui/embeddings#index"
end