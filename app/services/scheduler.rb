class Scheduler

  extend ClassOptionsAttribute

  class_constant_builder(:tasks, %w[ task every ]) do |const|
    # often
    const.add(task: "update_location_stories_hourly", every: [:hour])
    const.add(task: "update_location_ratings_hourly", every: [:hour, at: 30])
    # 5AM UTC = 10PM PST / 1AM EST
    const.add(task: "clear_stale_sessions",  every: [1.day, at: "5:05 am"])
    const.add(task: "update_story_statuses", every: [1.day, at: "5:10 am"])
    const.add(task: "update_stories",        every: [1.day, at: "5:20 am"])
    # 8AM UTC = 1AM PST / 4AM EST
    const.add(task: "update_location_stories_daily",  every: [1.day, at: "8:45 am"])
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

  scheduled_task :update_location_stories_hourly do
    duration = task_options.fetch(:duration) { 3.hours }
    attempt_block(namespace: :spacebattles) do
      LocationSearcher::SpacebattlesSearcher.search!(duration, task_options)
    end
    attempt_block(namespace: :sufficientvelocity) do
      LocationSearcher::SufficientvelocitySearcher.search!(duration, task_options)
    end
    attempt_block(namespace: :fanfiction) do
      LocationSearcher::FanfictionSearcher.search!(duration, task_options)
    end
    attempt_block(namespace: :archiveofourown) do
      LocationSearcher::ArchiveofourownSearcher.search!(duration, task_options)
    end
  end

  scheduled_task :update_location_stories_daily do
    duration = task_options.fetch(:duration) { 1.day }
    attempt_block(namespace: :spacebattles) do
      LocationSearcher::SpacebattlesSearcher.search!(duration, task_options)
    end
    attempt_block(namespace: :sufficientvelocity) do
      LocationSearcher::SufficientvelocitySearcher.search!(duration, task_options)
    end
    attempt_block(namespace: :fanfiction) do
      LocationSearcher::FanfictionSearcher.search!(duration, task_options)
    end
    attempt_block(namespace: :archiveofourown) do
      LocationSearcher::ArchiveofourownSearcher.search!(duration, task_options)
    end
  end

  scheduled_task :update_location_ratings_hourly do
    spacebattles_searcher       = LocationSearcher::SpacebattlesSearcher.new
    sufficientvelocity_searcher = LocationSearcher::SufficientvelocitySearcher.new
    fanfiction_searcher         = LocationSearcher::FanfictionSearcher.new
    archiveofourown_searcher    = LocationSearcher::ArchiveofourownSearcher.new
    # setup searchers
    attempt_block(namespace: :spacebattles) { spacebattles_searcher.login! }
    attempt_block(namespace: :sufficientvelocity) { sufficientvelocity_searcher.login! }
    # update ratings
    50.times do |i|
      # spacebattles
      spacebattles_chapter = SpacebattlesStoryChapter.seek(chapter_created_on_lteq: 3.days.ago)
        .order_likes_updated_at(:asc, :first).order_chapter_updated_at(:desc).first
      attempt_block(namespace: :spacebattles, context: spacebattles_chapter) do
        spacebattles_chapter.update_rating!(searcher: spacebattles_searcher)
      end
      # sufficientvelocity
      sufficientvelocity_chapter = SufficientvelocityStoryChapter.seek(chapter_created_on_lteq: 3.days.ago)
        .order_likes_updated_at(:asc, :first).order_chapter_updated_at(:desc).first
      attempt_block(namespace: :sufficientvelocity, context: sufficientvelocity_chapter) do
        sufficientvelocity_chapter.update_rating!(searcher: sufficientvelocity_searcher)
      end
      # fanfiction
      fanfiction_chapter = FanfictionStory.seek(story_created_on_lteq: 3.days.ago)
        .order_favorites_updated_at(:asc, :first).order_story_updated_at(:desc).first
      attempt_block(namespace: :fanfiction, context: fanfiction_chapter) do
        fanfiction_chapter.update_rating!(searcher: fanfiction_searcher)
      end
      # archiveofourown
      archiveofourown_chapter = ArchiveofourownStory.seek(story_created_on_lteq: 3.days.ago)
        .order_kudos_updated_at(:asc, :first).order_story_updated_at(:desc).first
      attempt_block(namespace: :archiveofourown, context: archiveofourown_chapter) do
        archiveofourown_chapter.update_rating!(searcher: archiveofourown_searcher)
      end
      # throttle
      sleep 3
    end
  end

  scheduled_task :clear_stale_sessions do
    IdentitySession.seek(updated_at_lteq: 1.months.ago.utc).delete_all
    SessionActionData.seek(updated_at_lteq: 1.month.ago.utc).delete_all
  end

  scheduled_task :update_story_statuses do
    Story.update_statuses!
  end

  scheduled_task :update_stories do
    # destroy archived stories without locations
    Story.where(is_archived: true).each do |archived_story|
      if archived_story.locations.blank?
        archived_story.destroy!
      end
    end
    # update authors
    Story.preload(:author).each do |story|
      if !story.author
        active_location = story.active_location
        if active_location && active_location.author!
          story.update!(author: active_location.author!)
        end
      end
    end
    # merge duplicate stories
    Story.where_has_duplicates.sort.each do |story|
      next if Story.where(id: story.id).none?
      duplicate_story = story.duplicate_stories.first
      if duplicate_story
        story.merge_with_story!(duplicate_story)
      end
    end
  end

private

  def attempt_block(namespace:, context: nil, &block)
    @attempt_results ||= {}.with_indifferent_access
    # cancel if namespace has had errors
    return @attempt_results[namespace] if @attempt_results[namespace] == :rescued
    @attempt_results[namespace] = rescue_block(context || namespace, &block)
  end

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
