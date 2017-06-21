# firefly server stdout logging
if ENV["LOG_TO_STDOUT"] == "true"
  stdout_logger = ActiveSupport::Logger.new(STDOUT)
  stdout_logger.formatter = Rails.logger.formatter
  stdout_logger.level = Rails.logger.level
  Rails.logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))
end

Rails.logger.formatter = Logger::ApplicationFormatter.new
Rails.logger = ActiveSupport::TaggedLogging.new(Rails.logger)

# Rake::Task logger level
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

#=begin
        #unless ActiveSupport::Logger.logger_outputs_to?(Rails.logger, STDOUT)
        #  Rails.logger.extend(ActiveSupport::Logger.broadcast(stdout_logger))
        #end
#=end
=begin
Rails.application.configure do
  config.after_initialize do |app|
   app.assets.logger = Logger.new('/dev/null')
  end
end
=end
