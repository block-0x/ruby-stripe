Rails.application.routes.draw do
  root to: "posts#index"

  devise_for :users, :controllers => {
    :registrations => 'users/registrations',
    :sessions => 'users/sessions'
  }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  devise_scope :user do
    get "signup", :to => "users/registrations#new"
    get "login", :to => "users/sessions#new"
    get "logout", :to => "users/sessions#destroy"
  end
  resources :posts do
    resources :cards
  end
  resources :pay_infos, only: [:create]
  resources :users, only: [:show, :index]

end
