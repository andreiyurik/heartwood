Rails.application.routes.draw do
  resource :locale, only: :update

  resource :session
  resource :account, only: %i[show destroy]

  scope controller: :legal do
    get :privacy
    get :consent
    get :terms
  end
  resource :registration, only: %i[new create]
  resource :export, only: :create
  resources :archives, only: %i[create show]
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
  resource  :share_link, only: %i[create destroy]

  # View-only links for people without an account. See [[privacy-access]] "Share links".
  scope "shared/:token", module: :shared, as: :shared do
    get "/", to: "trees#show", as: :tree
    resources :people, only: :show
  end

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

  resources :edits, only: :index do
    scope module: :edits do
      resource :reversion, only: :create
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

  # Guests (no live session) get the landing page; signed-in people get their tree.
  constraints(->(request) { !Session.exists?(id: request.cookie_jar.signed[:session_id]) }) do
    get "/", to: "landing#show", as: :landing
  end
  root "people#index"
end
