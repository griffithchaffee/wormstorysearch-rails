Rails.application.routes.draw do

  root to: "stories#index"

  resources :stories, only: %w[ index show ]

end
