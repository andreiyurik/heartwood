Rails.application.routes.draw do
  resource :locale, only: :update

  resource :session
  resource :account, only: %i[show update destroy]

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
  namespace :settings do
    resource :crest_image, only: :destroy
  end
  resources :passwords, param: :token

  # Collaboration: joining a tree via invite link, switching which tree is
  # active, and the owner's member-management page. See [[collaboration]].
  get  "join/:join_code/card", to: "joins/cards#show", as: :join_card
  get  "join/:join_code", to: "joins#new",  as: :join
  post "join/:join_code", to: "joins#create"
  resource  :active_tree, only: :update
  resources :tree_memberships, only: %i[index update destroy]
  resource  :tree_join_code, only: :create
  resource  :share_link, only: %i[create destroy]

  # View-only links for people without an account. See [[privacy-access]] "Share links".
  scope "shared/:token", module: :shared, as: :shared do
    get "/", to: "trees#show", as: :tree
    get "card", to: "cards#show", as: :card
    resources :people, only: :show
  end

  # A question's own link: one question and an answer form, for relatives without an account. See [[questions]].
  get  "q/:token/card", to: "guest_answers/cards#show", as: :question_link_card
  get  "q/:token", to: "guest_answers#new", as: :question_link
  post "q/:token", to: "guest_answers#create"

  resources :questions, only: %i[index show destroy] do
    scope module: :questions do
      resources :answers, only: %i[create destroy]
      resources :acceptances, only: %i[new create]
      resource :closure, only: :create
    end
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
    resources :photos, only: %i[create edit update destroy]
    resources :events, only: %i[new create edit update destroy] do
      resources :citations, only: %i[new create destroy]
    end
    scope module: :people do
      resource :panel, only: :show
      resource :map,   only: :show
      resources :questions, only: %i[new create]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Guests (no live session) get the landing page; signed-in people get their tree.
  constraints(->(request) { !Session.exists?(id: request.cookie_jar.signed[:session_id]) }) do
    get "/", to: "landing#show", as: :landing
  end
  root "people#index"
end
