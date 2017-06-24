require "#{Rails.root}/app/services/scheduler"

namespace :schedule do

  Scheduler::SCHEDULE.each do |task, time|
    # run task on organization
    desc "Run scheduled #{task}"
    task task, :subdomain do |_, params|
      Rake::Task["environment"].invoke
      Rails.application.eager_load!
      begin
        Rails.logger.info { "running schedule:#{task}" }
        Rails.logger.flush
        Scheduler.run(task)
      rescue StandardError => error
        log_message = """
          Scheduled Task Error
          Task: #{task}
          Error: #{error.class}
          Message: #{error.message}
          Backtrace:#{error.backtrace.join("\n")}
        """.lalign
        Rails.logger.fatal { log_message }
        DynamicMailer.email(subject: "Scheduler Task Error [#{task}] - #{error.class}", body: log_message).deliver_now
      end
    end
  end

  desc "Install tasks"
  task :install do
    Rake::Task["schedule:print"].reinvoke
    puts execute("#{Rails.root}/bin/whenever -i Scheduler")
  end

  desc "Print tasks"
  task :print do
    puts execute("#{Rails.root}/bin/whenever")
  end

end

