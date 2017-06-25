# Learn more: http://github.com/javan/whenever
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

require_relative "application"
require "#{Rails.root}/app/services/scheduler"

set(:path, Rails.root.to_s)
set(:environment, Rails.env)
set(:environment_variable, "RAILS_ENV")

if Rails.env.production?
  set(:output, "/var/log/scheduler.log")
else
  set(:output, "#{Rails.root}/log/scheduler.log")
end

Scheduler.const.tasks.each do |task|
  every(*task.every) { rake("schedule:#{task.task}") }
end
