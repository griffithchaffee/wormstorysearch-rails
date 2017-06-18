if Rails.env.development?
  Rails.configuration.firefly = ActiveSupport::OrderedOptions.new
  Rails.configuration.firefly.request_count = 0
  ApplicationController.before_action { Rails.configuration.firefly.request_count += 1 }
end

# skip logging of unpermitted parameter notifications due to verbosity
ActiveSupport::Notifications.unsubscribe("unpermitted_parameters.action_controller")
