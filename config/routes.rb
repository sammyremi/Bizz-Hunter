# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'business-discovery/search', to: 'business_discovery#search'
    end
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end