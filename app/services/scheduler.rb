class Scheduler

  SCHEDULE = {
    clear_stale_sessions: [1.day],
    update_stories: [1.hour],
  }.with_indifferent_access

  class << self
    def scheduled_task(task, task_options = {}, &block)
      raise ArgumentError, "No schedule set for Schedule.#{task}" if SCHEDULE[task].blank?
      define_method(task, &block)
    end

    def run(*params, &block)
      new.run(*params, &block)
    end
  end

  attr_reader :task, :task_options

  def initialize
  end

  def run(task, task_options = {})
    @task = task
    @task_options = task_options.with_indifferent_access
    rescue_block { send(task) }
  end

  scheduled_task :clear_stale_sessions do
    IdentitySession.seek(updated_at_lteq: 1.months.ago.utc).delete_all
    SessionActionData.seek(updated_at_lteq: 1.month.ago.utc).delete_all
  end

  scheduled_task :update_stories do
    duration = task_options.fetch(:duration) { 3.hours }
    StorySearcher::SpacebattlesSearcher.search!(duration, task_options)
    StorySearcher::SufficientvelocitySearcher.search!(duration, task_options)
  end

private

  def rescue_block(resource = nil)
    begin
      yield
    rescue StandardError => error
      raise error if task_options[:test_debug] == true || (Rails.env.test? && task_options[:test_debug] != false)
      subject = "Schedule #{task.to_s.titleize} Error [#{error.class}]: #{error.message}"
      body = "
        Time: #{Time.zone.now}
        Task: #{task}
        Resource: #{resource.inspect}

        Error: #{error.class}
        Message: #{error.message}
        Backtrace:
        #{error.backtrace.join("\n")}
      ".strip.lalign
      DynamicMailer.email(subject: subject, body: body).deliver_now
      return :rescued
    end
  end
end
