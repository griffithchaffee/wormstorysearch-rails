Rails.application.configure do
  # remove default middleware
  config.app_middleware.delete(ActiveRecord::QueryCache)
  # add custom middleware
  config.app_middleware.insert_before(Rails::Rack::Logger, Rails.application.class::MiddlewareApplicationDisconnect)
  config.app_middleware.insert_before(Rails::Rack::Logger, Rails.application.class::MiddlewareLoggerSilencer)
  config.app_middleware.insert_before(Rails::Rack::Logger, Rails.application.class::MiddlewareApplicationConnect)
end
