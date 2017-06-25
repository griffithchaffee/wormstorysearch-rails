# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

ENV["BROADCAST_TO_STDOUT"] = "true"
require_relative "lib/tasks/application_task_concern"
include ApplicationTaskConcern
require_relative "config/application"

Rails.application.load_tasks

%w[ db test doc ].each do |namespace|
  Rake::Task.clear_namespace(namespace)
end
