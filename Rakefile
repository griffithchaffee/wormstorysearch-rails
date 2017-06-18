# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "lib/tasks/task_helper"
include TaskHelper
require_relative "config/application"

if !Rails.logger
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  Rails.logger.formatter = Logger::ApplicationFormatter.new
  Rails.logger = ActiveSupport::TaggedLogging.new Rails.logger
  Rails.logger.level = Logger::INFO
end

Rails.application.load_tasks

Rake::Task.clear_namespace("db")
Rake::Task.clear_namespace("test")
Rake::Task.clear_namespace("doc")
