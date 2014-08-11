Rails.application.routes.draw do
  resources :documents do
    get 'tags', on: :collection
  end

  root to: 'documents#index'
end
