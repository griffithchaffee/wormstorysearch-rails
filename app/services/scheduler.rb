class Scheduler

  extend ClassOptionsAttribute

  class_constant_builder(:tasks, %w[ task every ]) do |const|
    # often
    const.add(task: "update_stories", every: [1.hour])
    # 5AM UTC = 9PM PST / 12AM EST
    const.add(task: "clear_stale_sessions",        every: [1.day, at: "5:00 am"])
    const.add(task: "update_story_statuses",       every: [1.day, at: "5:05 am"])
    # 9AM UTC = 1AM PST / 4AM EST
    #const.add(task: "update_recent_story_ratings", every: [1.day, at: "9:00 am"])
    # 10AM UTC = 2AM PST / 5AM EST
    #const.add(task: "update_all_story_ratings",    every: [:thursday, at: "10:00 am"])
  end

  class << self
    def scheduled_task(task, task_options = {}, &block)
      raise ArgumentError, "No schedule set for task: #{task}" if const.tasks.fetch(task.to_s).blank?
      define_method(task, &block)
    end

    def run(*params, &block)
      new.run(*params, &block)
    end
  end

  attr_reader :task, :task_options

  def run(task, task_options = {})
    @task = task
    @task_options = task_options.with_indifferent_access
    rescue_block { send(task) }
  end
=begin
  scheduled_task :update_recent_story_ratings do
    duration = task_options.fetch(:duration) { 1.month }
    Story.preload_locations_with_chapters.seek(story_updated_at_gteq: duration.ago).find_each(batch_size: 50) do |story|
      story.update_rating!(update_locations: true)
    end
  end

  scheduled_task :update_all_story_ratings do
    Story.preload_locations_with_chapters.find_each(batch_size: 50) do |story|
      story.update_rating!(update_locations: true)
    end
  end
=end
  scheduled_task :clear_stale_sessions do
    IdentitySession.seek(updated_at_lteq: 1.months.ago.utc).delete_all
    SessionActionData.seek(updated_at_lteq: 1.month.ago.utc).delete_all
  end

  scheduled_task :update_story_statuses do
    Story.update_statuses!
  end

  scheduled_task :update_stories do
    duration = task_options.fetch(:duration) { 12.hours }
    LocationSearcher::SpacebattlesSearcher.search!(duration, task_options)
    LocationSearcher::SufficientvelocitySearcher.search!(duration, task_options)
    LocationSearcher::FanfictionSearcher.search!(duration, task_options)
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
