Rails.application.routes.draw do

  root to: "stories#index"

  resources :stories, only: %w[ index show edit update ]

  # errors
  %w[
    catch_all not_found bad_request internal_server_error unprocessable_entity
    catch_all_test internal_server_error_test unprocessable_entity_test
  ].each do |action_name|
    get "/errors/#{action_name}", to: "errors##{action_name}"
  end
  post "/errors/internal_server_error_test", to: "errors#internal_server_error_test"


end
