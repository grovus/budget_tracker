BudgetTracker::Application.routes.draw do
  resources :payment_types
  resources :items
  resources :sources
  resources :categories
  resources :transactions
  resources :portfolios
  resources :users
  resources :sessions, only: [:new, :create, :destroy]
  root 'static_pages#home'
  match '/signup', to: 'users#new', via: 'get'
  match '/signin', to: 'sessions#new', via: 'get'
  match '/signout', to: 'sessions#destroy', via: 'delete'
  match '/help', to: 'static_pages#help', via: 'get'
  match '/about', to: 'static_pages#about', via: 'get'
  match '/contact', to: 'static_pages#contact', via: 'get'
  match '/manage', to: 'portfolios#manage', via: 'get'
  match '/edit_selected', to: 'categories#edit_selected', via: 'post'
  match '/edit_selected_source', to: 'sources#edit_selected', via: 'post'
  match '/portfolios/:id/transactions/:year/:month', to: 'portfolios#transactions_monthly', via: 'get'
  match '/portfolios/:id/transactions/payment_type/:payment_type_id', to: 'portfolios#transactions_by_payment_type', via: 'get'
  match '/setup', to: 'portfolios#setup', via: 'get'
  match '/setup_items', to: 'portfolios#setup_items', via: 'get'
  match '/create_categories', to: 'portfolios#create_categories', via: 'patch'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
