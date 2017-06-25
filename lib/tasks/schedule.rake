require "#{Rails.root}/app/services/scheduler"

namespace :schedule do
  Scheduler.const.tasks.each do |task, time|
    # run task on organization
    desc "Run scheduled task #{task.task}"
    task task.task do |_, params|
      Rake::Task["app:load"].invoke
      begin
        Rails.logger.info { "running schedule:#{task.task}" }
        Rails.logger.flush
        Scheduler.run(task.task)
      rescue StandardError => error
        log_message = """
          Scheduled Task Error
          Task: #{task.task}
          Error: #{error.class}
          Message: #{error.message}
          Backtrace:#{error.backtrace.join("\n")}
        """.lalign
        Rails.logger.fatal { log_message }
        DynamicMailer.email(subject: "Scheduler Task Error [#{task.task}] - #{error.class}", body: log_message).deliver_now
      end
    end
  end

  desc "Install tasks"
  task :install do
    Rake::Task["schedule:print"].reinvoke
    puts system_execute("#{Rails.root}/bin/whenever -i Scheduler")
  end

  desc "Print tasks"
  task :print do
    Rake::Task["app:load"].invoke
    puts system_execute("#{Rails.root}/bin/whenever")
  end
end

