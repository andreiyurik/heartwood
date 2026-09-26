Rails.application.routes.draw do
  resource :locale, only: :update

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

  namespace :places do
    resource :search,  only: :show
    resource :geocode, only: :show
  end

  resource :tree, only: :show, controller: "clan_trees", as: :clan_tree

  resource :map, only: :show do
    scope module: :maps do
      resources :events, only: :index
    end
  end

  resources :hints, only: :index do
    scope module: :hints do
      resource :dismissal, only: :create
    end
  end
  namespace :hints do
    resource :scan, only: :create
  end

  namespace :autocompletable do
    resources :people, only: :index
  end

  resources :people do
    resource :tree, only: :show
    resource :relationship, only: :show
    resources :relatives, only: %i[new create]
    resources :events, only: %i[new create edit update destroy] do
      resources :citations, only: %i[new create destroy]
    end
    scope module: :people do
      resource :panel, only: :show
      resource :map,   only: :show
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
