Rails.application.routes.draw do
  root "static_pages#home"
  get "/help", to: 'static_pages#help'
  get "/about", to: 'static_pages#about'
  get "/contact", to: 'static_pages#contact'
  get "/signup", to: "users#new"
  get '/login', to: 'session#new'
  post '/login', to: 'session#create'
  delete '/logout', to: 'session#delete'

  resources :users
end
