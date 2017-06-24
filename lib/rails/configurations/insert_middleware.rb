Rails.application.configure do
  # Rack::Lock prevents threaded requests which break database connections
  #config.app_middleware.insert_after(ActionDispatch::Static, Rack::Lock)
  # add custom middleware
  config.app_middleware.insert_before(Rails::Rack::Logger, Rails.application.class::Middleware::LoggerSilencer)
  config.app_middleware.insert_before(Rails::Rack::Logger, Rack::Lock)
  config.app_middleware.insert_before(Rails::Rack::Logger, Rails.application.class::Middleware::ApplicationDisconnect)
  config.app_middleware.insert_before(Rails::Rack::Logger, Rails.application.class::Middleware::ApplicationConnect)
end
