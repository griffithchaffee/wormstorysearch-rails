# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "lib/tasks/task_helper"
include TaskHelper
require_relative "config/application"

Rails.application.load_tasks
=begin
require File.expand_path("../config/application", __FILE__)
require File.expand_path("#{Rails.root}/app/services/schedule")

if !Rails.logger
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  Rails.logger.formatter = PrettyFormatter.new
  Rails.logger = ActiveSupport::TaggedLogging.new Rails.logger
  Rails.logger.level = Logger::INFO
end

require_relative "lib/tasks/task_helper"
include TaskHelper
=end
#Finalforms::Application.load_tasks

Rake::Task.clear_namespace "db"
Rake::Task.clear_namespace "test"
Rake::Task.clear_namespace "doc"
