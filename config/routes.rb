Rails.application.routes.draw do
  get "/locale/:locale" => "locales#update", as: :set_locale,
      constraints: { locale: /en|ru/ }

  resource :session
  resource :registration, only: %i[new create]
  resource :export, only: :create
  resource :import, only: %i[new create show]
  resource :settings, only: %i[show update]
  resources :passwords, param: :token

  # Collaboration: joining a tree via invite link, switching which tree is
  # active, and the owner's member-management page. See [[collaboration]].
  get  "join/:join_code", to: "joins#new",  as: :join
  post "join/:join_code", to: "joins#create"
  resource  :active_tree, only: :update
  resources :tree_memberships, only: %i[index update destroy]
  resource  :tree_join_code, only: :create

  get "places/search",  to: "places#search",  as: :search_places
  get "places/geocode", to: "places#geocode", as: :geocode_places

  get "tree",       to: "clan_trees#show", as: :clan_tree

  get "map",        to: "maps#show",   as: :tree_map
  get "map/events", to: "maps#events", as: :tree_map_events

  resources :hints, only: :index do
    collection { post :scan }
    member     { patch :dismiss }
  end

  resources :people do
    resource  :tree,     only: :show
    resource  :relationship, only: :show do
      get :search, on: :member
    end
    resources :relatives, only: %i[new create] do
      get :search, on: :collection
    end
    resources :events,    only: %i[new create edit update destroy] do
      resources :citations, only: %i[new create destroy]
    end
    member do
      get :map, to: "maps#person"
      get :panel
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
