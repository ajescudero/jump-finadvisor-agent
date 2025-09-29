Rails.application.routes.draw do
  resources :embeddings, only: [:create] do
    collection { post :nearest }
  end
  resources :instructions, only: [:create, :update]
  resources :tasks, only: [:create, :update, :show, :index]
end