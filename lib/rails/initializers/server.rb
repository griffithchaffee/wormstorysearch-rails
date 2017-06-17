if Rails.env.development?
  Rails.configuration.server = ActiveSupport::OrderedOptions.new
  Rails.configuration.server.request_count = 0
  UniversalController.before_action { Rails.configuration.server.request_count += 1 }
  require "byebug"
end

# skip logging of unpermitted parameter notifications due to verbosity
ActiveSupport::Notifications.unsubscribe("unpermitted_parameters.action_controller")
