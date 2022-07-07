namespace :admin do
  get '/', to: 'dashboard#index', as: :dashboard

  resources :documents
  resources :id_documents,     only: [:index, :show, :update]
  resource  :currency_deposit, only: [:new, :create]
  resources :proofs
  resources :tickets, only: [:index, :show] do
    member do
      patch :close
    end
    resources :comments, only: [:create]
  end

  resources :members, only: [:index, :show] do
    member do
      post :active
      post :toggle
      get :filter
      get :export
    end
    resources :two_factors, only: [:destroy]
  end

  namespace :deposits do
    Deposit.descendants.each do |d|
      resources d.resource_name
    end
  end

  namespace :withdraws do
    Withdraw.descendants.each do |w|
      resources w.resource_name
    end
  end

  resources :admin_withdraws do
    member do
      post :make_transaction
    end
  end

  namespace :statistic do
    resource :members, :only => :show
    resource :orders, :only => :show
    resource :trades, :only => :show
    resource :deposits, :only => :show
    resource :withdraws, :only => :show
  end

  get '/referrals', to: 'referrals#index'

  resources :referral_commissions
  resources :fees
  resources :holder_discounts
  resources :bots, only: [:index, :create, :edit, :update, :destroy] do
    collection do
      get :restart
      get :kill_bot
    end
    member do
      post :toggle
    end
  end

  resources :stakings do
    member do 
      put 'update_status'
    end
    collection do
      get "durations"
      get "new_durations"
      post 'save_durations'
      get 'get_currencies_duration'
    end
  end

  resources :lendings do
    collection do
      get 'types'
      post 'save_types'
      get 'durations'
      post 'save_durations'
      post 'save_lending'
    end
  end

  get 'commissions', to: 'commissions#index'
  post 'update_filters', to: 'commissions#update_filters'
end
