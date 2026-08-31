# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'business-discovery/search', to: 'business_discovery#search'
      get 'locations/autocomplete', to: 'locations#autocomplete'
      get 'locations/details', to: 'locations#details'
    end
  end

  get 'up' => 'rails/health#show', as: :rails_health_check

  root to: proc { [200, { 'Content-Type' => 'text/html' }, [File.read(Rails.root.join('public', 'index.html'))]] }
end