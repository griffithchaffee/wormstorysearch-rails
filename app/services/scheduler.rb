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
    # Any login attempt around 2AM PST (9AM UTC) will fail on QuestionableQuesting
    if Time.zone.now.hour != 2
      attempt_block(namespace: :questionablequesting) do
        LocationSearcher::QuestionablequestingSearcher.search!(duration, task_options)
      end
    end
  end

  scheduled_task :update_location_stories_daily do
    duration = task_options.fetch(:duration) { 2.days }
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
    attempt_block(namespace: :questionablequesting) do
      LocationSearcher::QuestionablequestingSearcher.search!(duration, task_options)
    end
  end

  scheduled_task :update_location_ratings_hourly do
    spacebattles_searcher         = LocationSearcher::SpacebattlesSearcher.new
    sufficientvelocity_searcher   = LocationSearcher::SufficientvelocitySearcher.new
    fanfiction_searcher           = LocationSearcher::FanfictionSearcher.new
    archiveofourown_searcher      = LocationSearcher::ArchiveofourownSearcher.new
    questionablequesting_searcher = LocationSearcher::QuestionablequestingSearcher.new
    # setup searchers
    attempt_block(namespace: :spacebattles) { spacebattles_searcher.login! }
    attempt_block(namespace: :sufficientvelocity) { sufficientvelocity_searcher.login! }
    attempt_block(namespace: :questionablequesting) { questionablequesting_searcher.login! }
    spacebattles_chapters = SpacebattlesStoryChapter.seek(chapter_created_on_lteq: 1.day.ago)
      .order_likes_updated_at(:asc, :first).order_chapter_updated_at(:desc)
    sufficientvelocity_chapters = SufficientvelocityStoryChapter.seek(chapter_created_on_lteq: 1.day.ago)
      .order_likes_updated_at(:asc, :first).order_chapter_updated_at(:desc)
    fanfiction_chapters = FanfictionStory.seek(story_created_on_lteq: 1.day.ago)
      .order_favorites_updated_at(:asc, :first).order_story_updated_at(:desc)
    archiveofourown_chapters = ArchiveofourownStory.seek(story_created_on_lteq: 1.day.ago)
      .order_kudos_updated_at(:asc, :first).order_story_updated_at(:desc)
    questionablequesting_chapters = QuestionablequestingStoryChapter.seek(chapter_created_on_lteq: 1.day.ago)
      .order_likes_updated_at(:asc, :first).order_chapter_updated_at(:desc)
    # update ratings for chapters
    30.times do |i|
      # spacebattles
      spacebattles_chapter = spacebattles_chapters.first
      attempt_block(namespace: :spacebattles, context: spacebattles_chapter) do
        spacebattles_chapter.update_rating!(searcher: spacebattles_searcher)
      end
      # sufficientvelocity
      sufficientvelocity_chapter = sufficientvelocity_chapters.first
      attempt_block(namespace: :sufficientvelocity, context: sufficientvelocity_chapter) do
        sufficientvelocity_chapter.update_rating!(searcher: sufficientvelocity_searcher)
      end
      # fanfiction
      fanfiction_chapter = fanfiction_chapters.first
      attempt_block(namespace: :fanfiction, context: fanfiction_chapter) do
        fanfiction_chapter.update_rating!(searcher: fanfiction_searcher)
      end
      # archiveofourown
      archiveofourown_chapter = archiveofourown_chapters.first
      attempt_block(namespace: :archiveofourown, context: archiveofourown_chapter) do
        archiveofourown_chapter.update_rating!(searcher: archiveofourown_searcher)
      end
      # questionablequesting
      questionablequesting_chapter = questionablequesting_chapters.first
      attempt_block(namespace: :questionablequesting, context: questionablequesting_chapter) do
        questionablequesting_chapter.update_rating!(searcher: questionablequesting_searcher)
      end
      # throttle
      sleep 3
    end
    # update ratings for recent chapters since they will change more often
    30.times do |i|
      # spacebattles
      spacebattles_chapter = spacebattles_chapters.seek(chapter_created_on_gteq: 3.months.ago).first
      attempt_block(namespace: :spacebattles, context: spacebattles_chapter) do
        spacebattles_chapter.update_rating!(searcher: spacebattles_searcher)
      end
      # sufficientvelocity
      sufficientvelocity_chapter = sufficientvelocity_chapters.seek(chapter_created_on_gteq: 3.months.ago).first
      attempt_block(namespace: :sufficientvelocity, context: sufficientvelocity_chapter) do
        sufficientvelocity_chapter.update_rating!(searcher: sufficientvelocity_searcher)
      end
      # fanfiction
      fanfiction_chapter = fanfiction_chapters.seek(story_created_on_gteq: 3.months.ago).first
      attempt_block(namespace: :fanfiction, context: fanfiction_chapter) do
        fanfiction_chapter.update_rating!(searcher: fanfiction_searcher)
      end
      # archiveofourown
      archiveofourown_chapter = archiveofourown_chapters.seek(story_created_on_gteq: 3.months.ago).first
      attempt_block(namespace: :archiveofourown, context: archiveofourown_chapter) do
        archiveofourown_chapter.update_rating!(searcher: archiveofourown_searcher)
      end
      # questionablequesting
      questionablequesting_chapter = questionablequesting_chapters.seek(chapter_created_on_gteq: 3.months.ago).first
      attempt_block(namespace: :questionablequesting, context: questionablequesting_chapter) do
        questionablequesting_chapter.update_rating!(searcher: questionablequesting_searcher)
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

  # attempt a block but cancel if namespace has had multiple errors
  def attempt_block(namespace:, context: nil, &block)
    @attempts ||= {}.with_indifferent_access
    namespace = namespace.to_s
    @attempts[namespace] ||= 0
    # cancel if namespace has had to many errors
    return false if @attempts[namespace] > 3
    if rescue_block(context || namespace, &block) == :rescued
      @attempts[namespace] += 1
      false
    else
      true
    end
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
