module StorySearcher
  class SpacebattlesSearcher < UniversalSearcher
    attr_reader :configuration, :crawler, :updated_after, :location, :search_options

    def initialize
      @location = "spacebattles"
      @configuration = File::Configuration.load_rails_config_file("#{location}.yml").with_indifferent_access
      @crawler = SiteCrawler.new(configuration.fetch(:site_url))
      crawler.logger = Rails.logger
    end

    def search!(time, search_options = {})
      @search_options = search_options.with_indifferent_access
      time = time.ago if time.is_a?(ActiveSupport::Duration)
      Rails.logger.silence(Logger::INFO) do
        #login!
        update_stories_newer_than!(time)
      end
    end

    def login!
      # authenticate
      crawler.post(
        "/login/login",
        { login: configuration.fetch(:username), password: configuration.fetch(:password) },
        { follow_redirects: false, log_level: Logger::WARN }
      )
    end

    def update_stories_newer_than!(time)
      # crawl worm subform
      page = 0
      while page do
        page += 1
        # prevent infinite loop
        raise ArgumentError, "crawled too many pages on: #{configuration[:site_url]}" if page > configuration.fetch(:max_pages)
        # crawl latest threads
        crawler.get("/forums/worm.115/#{"page-#{page}" if page > 1}", { order: "last_post_date", direction: "desc" }, { log_level: Logger::INFO })
        threads_html = crawler.html.find_all("ol.discussionListItems li.discussionListItem:not(.sticky)")
        # stop on last page
        return if threads_html.size == 0
        # parse threads
        threads_html.each do |thread_html|
          story, = update_story_for_thread!(thread_html)
          Rails.logger.info("Reading Story: #{story.title}")
          update_chapters_for_story!(story)
          # stop if older than time
          return if story.story_active_at < time
        end
      end
    end

    def update_story_for_thread!(thread_html)
      # sections
      main_html = thread_html.css(".main")
      # parts
      title_html = main_html.css("h3.title a.PreviewTooltip").first
      author_html = main_html.css(".username")
      word_count_html = main_html.css(".OverlayTrigger")
      created_html = main_html.css(".DateTime").first
      active_html = thread_html.css(".lastPostInfo .DateTime").first
      # build story
      location_story_id = thread_html[:id]
      created_at  = abbr_html_to_time(created_html)
      active_at   = abbr_html_to_time(active_html)
      story_finder = { location: location, location_story_id: location_story_id }
      story = Story.find_by(story_finder) || Story.new(story_finder)
      story.assign_attributes(
        location_path: "/#{title_html[:href].remove(/\/(unread)?\z/)}",
        title: title_html.text,
        author: author_html.text,
        word_count: word_count_html.text.remove("Word Count: "),
        story_active_at: active_at,
      )
      if story.unsaved? || search_options[:reset]
        story.assign_attributes(
          story_created_on: created_at,
          story_updated_at: created_at,
        )
      end
      story.save! if story.has_changes_to_save?
      story
    end

    def update_chapters_for_story!(story)
      # get threadmarks
      crawler.get("#{story.location_path}/threadmarks", {}, { log_level: Logger::WARN })
      # parse threadmarks
      position = 0
      new_chapters = []
      crawler.html.find_all("li.primaryContent").each do |html_li|
        position += 1
        # parts
        updated_html = html_li.css(".DateTime").first
        preview_html = html_li.css("a.PreviewTooltip").first
        # build chapter
        location_path = preview_html[:href]
        updated_at = abbr_html_to_time(updated_html)
        chapter = story.chapters.get(position: position) || story.chapters.build(position: position)
        chapter.assign_attributes(
          location_path: location_path,
          title: preview_html.text,
          word_count: html_li.text[/\([0-9.km]+\)/].to_s.remove("(").remove(")"),
          chapter_created_at: updated_at,
          chapter_updated_at: updated_at,
        )
        chapter.save! if chapter.has_changes_to_save?
        new_chapters << chapter
      end
      story.chapters = new_chapters
    end

    def abbr_html_to_time(abbr_html)
      abbr_html["data-time"]  ? Time.at(abbr_html["data-time"].to_i) : Date.parse(abbr_html.text)
    end
  end
end
