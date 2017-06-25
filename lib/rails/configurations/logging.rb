# add formatter
Rails.logger.formatter = Logger::ApplicationFormatter.new
Rails.logger = ActiveSupport::TaggedLogging.new(Rails.logger)

# logger level for production and rake tasks
if Rails.env.production? || defined?(Rake::Task)
  Rails.logger.level = Logger::INFO
else
  Rails.logger.level = Logger::DEBUG
end

# console logger
console do
  Rails.logger.formatter = Logger::ApplicationFormatter.new
  Rails.logger = ActiveSupport::TaggedLogging.new(Rails.logger)
  if Rails.env.production?
    Rails.logger.level = Logger::INFO
  else
    Rails.logger.level = Logger::DEBUG
  end
end

# easy stdout logging
if ENV["BROADCAST_TO_STDOUT"] == "true"
  stdout_logger = ActiveSupport::Logger.new($stdout)
  stdout_logger.formatter = Rails.logger.formatter
  stdout_logger.level = Rails.logger.level
  Rails.logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))
end

# request tags
Rails.application.configure do
  # optional: request_id
  config.log_tags = %i[ remote_ip ]
end
