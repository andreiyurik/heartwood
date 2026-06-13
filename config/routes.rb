Rails.application.routes.draw do
  get "/locale/:locale" => "locales#update", as: :set_locale,
      constraints: { locale: /en|ru/ }

  resource :session
  resource :export, only: :create
  resources :passwords, param: :token

  resources :people do
    resource  :tree,     only: :show
    resources :relatives, only: %i[new create] do
      get :search, on: :collection
    end
    resources :events,    only: %i[new create edit update destroy] do
      resources :citations, only: %i[new create destroy]
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "people#index"
end
