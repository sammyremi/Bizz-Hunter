# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'auth/register', to: 'auth#register'
      post 'auth/login', to: 'auth#login'
      get 'auth/me', to: 'auth#me'
      post 'auth/logout', to: 'auth#logout'
      post 'auth/verify_email', to: 'auth#verify_email'
      post 'auth/resend_verification', to: 'auth#resend_verification'
      post 'auth/forgot_password', to: 'auth#forgot_password'
      post 'auth/reset_password', to: 'auth#reset_password'
      post 'auth/change_password', to: 'auth#change_password'

      # Google OAuth 2.0
      get 'auth/google', to: 'google_oauth#redirect_to_google'
      get 'auth/google/callback', to: 'google_oauth#callback'
      get 'auth/google_oauth2/callback', to: 'google_oauth#callback'

      get 'business-discovery/search', to: 'business_discovery#search'
      get 'business-discovery/quota', to: 'business_discovery#quota'
      get 'business-discovery/analysis', to: 'business_discovery#analysis'
      get 'locations/autocomplete', to: 'locations#autocomplete'
      get 'locations/details', to: 'locations#details'

      get 'analytics', to: 'analytics#show'
      get 'searches', to: 'searches#index'
      get 'searches/:id/analysis', to: 'searches#analysis'

      post 'outreach_messages', to: 'outreach_messages#create'
      post 'prospect_briefs', to: 'prospect_briefs#create'
      get 'settings', to: 'settings#show'
      patch 'settings', to: 'settings#update'

      resources :prospects
      resources :prospecting_profiles do
        collection do
          post :generate
        end
      end
    end
  end

  # Root-level Google OAuth 2.0 callback route matching Google OAuth client config
  get 'auth/google_oauth2/callback', to: 'api/v1/google_oauth#callback'

  get 'up' => 'rails/health#show', as: :rails_health_check

  root to: proc { [200, { 'Content-Type' => 'text/html' }, [File.read(Rails.root.join('public', 'index.html'))]] }
end