Rails.application.routes.draw do
  resource :sessao, only: [ :new, :create, :destroy ]
  resource :senha, only: [ :edit, :update ]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "relatorios/menu#index"

  namespace :operacoes do
    resources :remessas, only: [ :new, :create ]
    resource :distribuicao, only: [ :new, :create, :destroy ]
    resource :exportacao, only: [ :new, :create ]
    get "validacoes_sombra", to: "validacoes_sombra#index", as: :validacoes_sombra
  end

  namespace :relatorios do
    get "/", to: "menu#index", as: :menu
    get "titulos/eventuais", to: "titulos#eventuais"
    get "titulos/por_apresentante", to: "titulos#por_apresentante"
    get "titulos/por_devedor", to: "titulos#por_devedor"
    get "arrecadacao/resumo", to: "arrecadacao#resumo"
    get "arrecadacao/total_titulos", to: "arrecadacao#total_titulos"
    get "ranking_devedores", to: "ranking_devedores#index"
    get "apresentantes", to: "apresentantes#index"
  end

  namespace :cadastros do
    resources :cartorios, except: :show
    resources :bancos, except: :show
    resources :apresentantes, except: :show
    resources :tipo_titulos, except: :show
    resources :faixa_custas, except: :show
    resources :usuarios, except: :show do
      member do
        post :resetar_senha
        delete :excluir
      end
    end
  end
end
