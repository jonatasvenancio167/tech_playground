Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboards#index"

  resources :dashboards, only: [:index] do
    collection do
      get :company
      get :departments
      get :trends
    end
    member do
      get :employee
    end
  end

  namespace :api do
    namespace :v1 do
      resources :employees, only: [:index, :show] do
        resources :responses, only: [:index]
      end
      resources :responses, only: [:index]
      resources :imports, only: [:index, :show, :create]

      # Analytics endpoints
      namespace :analytics do
        get "dashboard", to: "dashboard#index"
        get "dashboard/executive", to: "dashboard#executive"
        get "dashboard/departments", to: "dashboard#departments"
        get "dashboard/trends", to: "dashboard#trends"
        get "dashboard/alerts", to: "dashboard#alerts"

        get "favorability", to: "favorability#index"
        get "favorability/by_department", to: "favorability#by_department"
        get "favorability/by_location", to: "favorability#by_location"

        get "nps", to: "nps#index"
        get "nps/distribution", to: "nps#distribution"
        get "nps/trend", to: "nps#trend"
        get "nps/by_department", to: "nps#by_department"
        get "nps/by_location", to: "nps#by_location"
        get "nps/at_risk", to: "nps#at_risk"
      end
    end
  end
end
