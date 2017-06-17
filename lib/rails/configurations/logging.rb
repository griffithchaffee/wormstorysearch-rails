Rails.logger.formatter = PrettyFormatter.new
Rails.logger = ActiveSupport::TaggedLogging.new(Rails.logger)

# reset logger level
if Rails.env.production? || defined?(Rake::Task)
  Rails.logger.level = Logger::INFO
else
  Rails.logger.level = Logger::DEBUG
end

# console logging
console do
  Rails.logger.formatter = PrettyFormatter.new
  Rails.logger = ActiveSupport::TaggedLogging.new(Rails.logger)
  if Rails.env.production?
    Rails.logger.level = Logger::INFO
  else
    Rails.logger.level = Logger::DEBUG
  end
end
