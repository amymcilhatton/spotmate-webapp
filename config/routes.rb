require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users
  root "dashboard#index"

  resource :profile, only: %i[show edit update]
  resources :availability_slots, only: %i[index new create edit update destroy]
  resources :matches, only: %i[index create update] do
    collection do
      post :skip
    end
    member do
      post :rematch
      get :chat
      post :kudos
    end
  end
  resources :bookings, only: %i[index new create show destroy]
  resources :workout_logs, only: %i[index new create]
  resources :prs, only: %i[index new create destroy]
  resources :groups, only: %i[index show new create]
  resources :buddies, only: %i[index show]

  resources :workout_logs, only: [] do
    resources :workout_comments, only: %i[create]
    resources :workout_kudos, only: %i[create destroy]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  mount Sidekiq::Web => "/sidekiq"
end
