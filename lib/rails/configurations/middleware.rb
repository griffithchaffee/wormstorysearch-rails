Rails.application.configure do
  # remove default middleware
  config.app_middleware.delete(ActiveRecord::QueryCache)
  # add custom middleware
  config.app_middleware.insert_before(Rails::Rack::Logger, Wormfictionsearch::Middleware::ApplicationDisconnect)
  config.app_middleware.insert_before(Rails::Rack::Logger, Wormfictionsearch::Middleware::LoggerSilencer)
  config.app_middleware.insert_before(Rails::Rack::Logger, Wormfictionsearch::Middleware::ApplicationConnect)
  config.app_middleware.insert_after(ActionDispatch::DebugExceptions, Finalforms::OrganizationNotFound)
end
