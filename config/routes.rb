Rails.application.routes.draw do
  devise_for :users

  # Onboarding flow
  authenticate :user do
    get "onboarding", to: "onboarding#index", as: :onboarding
    post "onboarding/sports", to: "onboarding#sports", as: :onboarding_sports
    get "onboarding/teams", to: "onboarding#teams", as: :onboarding_teams
    post "onboarding/teams", to: "onboarding#save_teams", as: :onboarding_save_teams
    get "onboarding/complete", to: "onboarding#complete", as: :onboarding_complete
    get "onboarding/finish", to: "onboarding#finish", as: :onboarding_finish
  end

  # Authenticated routes
  authenticate :user do
    resources :chats, only: [ :index, :show, :create, :destroy ] do
      resources :messages, only: [ :create ]
    end
    get "dashboard", to: "dashboard#index"

    # Profile
    get "profile", to: "profile#show", as: :profile
    patch "profile/sports", to: "profile#update_sports", as: :profile_update_sports
    patch "profile/teams", to: "profile#update_teams", as: :profile_update_teams
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path - redirect logged in users to chats
  authenticated :user do
    root to: "chats#index", as: :authenticated_root
  end

  root "home#index"
end
