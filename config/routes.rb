# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'auth/register', to: 'auth#register'
      post 'auth/login', to: 'auth#login'
      get 'auth/me', to: 'auth#me'
      post 'auth/logout', to: 'auth#logout'

      get 'business-discovery/search', to: 'business_discovery#search'
      get 'locations/autocomplete', to: 'locations#autocomplete'
      get 'locations/details', to: 'locations#details'

      resources :prospects
    end
  end

  get 'up' => 'rails/health#show', as: :rails_health_check

  root to: proc { [200, { 'Content-Type' => 'text/html' }, [File.read(Rails.root.join('public', 'index.html'))]] }
end