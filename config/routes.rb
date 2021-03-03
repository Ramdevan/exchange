Rails.application.eager_load! if Rails.env.development?

class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end
end

Exchange::Application.routes.draw do
  use_doorkeeper

  root 'sessions#new'

  get '/terms' => 'welcome#terms'

  post '/webhooks/btc' => 'webhooks#btc'
  post '/webhooks/bchabc' => 'webhooks#bchabc'
  post '/webhooks/ltc' => 'webhooks#ltc'
  post '/webhooks/eth' => 'webhooks#eth'
  post '/webhooks/dash'  => 'webhooks#dash'
  post '/webhooks/zec' => 'webhooks#zec'
  post '/webhooks/usdt' => 'webhooks#usdt'
  post '/webhooks/xmr'  => 'webhooks#xmr'
  post '/webhooks/xrp'  => 'webhooks#xrp'
  post '/webhooks/neo'  => 'webhooks#neo'

  if Rails.env.development?
    mount MailsViewer::Engine => '/mails'
  end

  get '/signin' => 'sessions#new', :as => :signin
  get '/signup' => 'identities#new', :as => :signup
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure', :as => :failure
  match '/auth/:provider/callback' => 'sessions#create', via: [:get, :post]
  get '/contactus' => 'sessions#show'
  post '/sendmail' => 'sessions#sendmail'
  resource :member, :only => [:edit, :update]
  resource :identity, :only => [:edit, :update]
  resources :loginhistory do 
    collection do 
      get :show_history
      get :verify_token
    end 
  end 
  namespace :verify do
    resource :sms_auth,    only: [:show, :update]
    resource :google_auth, only: [:show, :update, :edit, :destroy]
  end

  namespace :authentications do
    resources :emails, only: [:new, :create]
    resources :identities, only: [:new, :create]
  end

  scope :constraints => { id: /[a-zA-Z0-9]{32}/ } do
    resources :reset_passwords
    resources :activations, only: [:new, :edit, :update]
  end

  get '/documents/api_v2'
  get '/documents/websocket_api'
  get '/documents/oauth'
  resources :documents, only: [:show]
  resources :two_factors, only: [:show, :index, :update]

  scope module: :private do
    resource  :id_document, only: [:edit, :update]

    resources :settings, only: [:index]
    resources :api_tokens do
      member do
        delete :unbind
      end
    end

    resources :fund_sources, only: [:create, :update, :destroy]

    resources :funds, only: [:index] do
      collection do
        post :gen_address
      end
    end

    namespace :deposits do
      Deposit.descendants.each do |d|
        resources d.resource_name do
          collection do
            post :gen_address
          end
        end
      end
    end

    namespace :withdraws do
      Withdraw.descendants.each do |w|
        resources w.resource_name
      end
    end

    resources :account_versions, :only => :index

    resources :exchange_assets, :controller => 'assets' do
      member do
        get :partial_tree
      end
    end

    get '/history/orders' => 'history#orders', as: :order_history
    get '/history/trades' => 'history#trades', as: :trade_history
    get '/history/account' => 'history#account', as: :account_history
    get '/referrals' => 'referrals#index'
    get '/history/subscription' => 'history#subscription', as: :subscription
    get '/history/redeem' => 'history#redeem', as: :redeem

    resources :markets, :only => :show, :constraints => MarketConstraint do
      resources :orders, :only => [:index, :destroy] do
        collection do
          post :clear
        end
      end
      resources :order_bids, :only => [:create] do
        collection do
          post :clear
        end
      end
      resources :order_asks, :only => [:create] do
        collection do
          post :clear
        end
      end
    end

    post '/pusher/auth', to: 'pusher#auth'

    resources :tickets, only: [:index, :new, :create, :show] do
      member do
        patch :close
      end
      resources :comments, only: [:create]
    end
  end

  scope :lendings do
    get '/' => 'lendings#index', as: :lendings
    get '/flexible_transfer/:id' => 'lendings#flexible_transfer', as: :flexible_transfer
    post '/flexible_saving' => 'lendings#create_flexible_subscription', as: :flexible_saving
    get '/locked_transfer/:id' => 'lendings#locked_transfer', as: :locked_transfer
    post '/locked_saving' => 'lendings#create_locked_subscription', as: :locked_saving
    get '/activity_transfer/:id' => 'lendings#activity_transfer', as: :activity_transfer
    post '/activity_saving' => 'lendings#create_activity_subscription', as: :activity_saving
    get '/auto_transfer/:id' => 'lendings#auto_transfer', as: :auto_transfer
    post 'auto_transfer' => 'lendings#create_auto_tansfer', as: :flexible_auto_transfer
    get '/fast_redeem/:id' => 'lendings#fast_redeem', as: :fast_redeem
    get '/standard_redeem/:id' => 'lendings#standard_redeem', as: :standard_redeem

  end

  scope :stakings do
    get '/' => 'stakings#index', as: :stakings
    post '/staking_duration_info' => "stakings#staking_duration_info",as: :staking_duratin_info
    post '/get_staking' => "stakings#get_staking",as: :get_staking
    post '/confirm_staking_locked' => "stakings#confirm_staking_locked",as: :confirm_staking_locked
    post 'locked_type_option' => "stakings#locked_type_option", as: :locked_type_option
    post 'early_redeem' => "stakings#early_redeem", as: :early_redeem
    post 'redeem_now' => "stakings#redeem_now", as: :redeem_now
  end

  draw :admin

  mount APIv2::Mount => APIv2::Mount::PREFIX

end
