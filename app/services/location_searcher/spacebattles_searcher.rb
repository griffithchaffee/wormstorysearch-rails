module LocationSearcher
  class SpacebattlesSearcher < UniversalSearcher
    attr_reader :config, :search_options, :story_model

    def initialize
      @story_model = SpacebattlesStory
      @config = story_model.const
    end

    def search!(active_after, search_options = {})
      @search_options = search_options.with_indifferent_access
      active_after = active_after.ago if active_after.is_a?(ActiveSupport::Duration)
      Rails.logger.silence(Logger::INFO) do
        login!
        update_stories!(active_after: active_after)
        update_quests!(active_after: active_after)
      end
    end

    def login!
      if config.location_username && config.location_password
        # authenticate
        crawler.post(
          "/login/login",
          { login: config.location_username, password: config.location_password, redirect: "#{config.location_host}/authenticated" },
          { follow_redirects: false, log_level: Logger::INFO }
        )
        if crawler.response.status == 303
          Rails.logger.info { "Logged in as #{config.location_username}".green }
        else
          Rails.logger.warn { "Login failed for #{config.location_username}".yellow }
        end
      else
        Rails.logger.warn { "Skipping login".yellow }
      end
    end

    def update_chapter_likes!(chapter)
      crawler.get(chapter.read_url, {}, log_level: Logger::INFO, follow_redirects: true)
      page_html = crawler.html
      # no messages
      return if page_html.css("li.message").size == 0
      # find chapter id (by url or first post)
      # "threads/expand-your-world-worm-the-world-ends-with-you.450360/page-10#post-35820316" => post-35820316
      location_id = chapter.location_path.split("#").last if chapter.location_path.include?("#post-")
      location_id ||= page_html.css("li.message").first[:id]
      # parse likes
      likes_html       = page_html.css("#likes-#{location_id}")
      individual_likes = likes_html.css("a.username").size
      combined_likes   = likes_html.css("a.OverlayTrigger").text.to_s.remove(/\D/).to_i
      # set likes
      chapter.likes = individual_likes + combined_likes
      chapter.save! if chapter.has_changes_to_save?
      chapter
    end

    def update_stories!(options = {})
      options = options.with_indifferent_access
      page = options.delete(:page) || 0
      # crawl "Creative Writing" subforum "Worm"
      loop do
        page += 1
        # prevent infinite loop
        raise ArgumentError, "crawled too many pages on" if page > config.location_max_story_pages
        # crawl latest threads
        search_params = { order: "last_post_date", direction: "desc" }
        crawler.get("/forums/worm.115/#{"page-#{page}" if page > 1}", search_params, log_level: Logger::INFO)
        results = update_stories_from_html!(crawler.html, options.merge(is_worm_story: true))
        # stop on last page
        break if results[:more] != true
      end
    end

    def update_quests!(options = {})
      options = options.with_indifferent_access
      page = options.delete(:page) || 0
      # crawl "Roleplaying & Quests" forum
      loop do
        page += 1
        # prevent infinite loop
        raise ArgumentError, "crawled too many pages on" if page > config.location_max_quest_pages
        # crawl latest threads
        search_params = { order: "last_post_date", direction: "desc" }
        crawler.get("/forums/roleplaying-quests.60/#{"page-#{page}" if page > 1}", search_params, log_level: Logger::INFO)
        results = update_stories_from_html!(crawler.html, options.merge(attributes: { category: "quest" }))
        # stop on last page
        break if results[:more] != true
      end
    end

    def update_stories_from_html!(html, options = {})
      options = options.with_indifferent_access.assert_valid_keys(*%w[ active_after is_worm_story attributes chapters ])
      stories_html = parse_stories_html(html)
      stories = []
      results = -> (more) { { stories: stories, more: more } }
      # stop on last page
      return results.call(false) if stories_html.size == 0
      # parse threads
      stories_html.each do |story_html|
        story_attributes = parse_story_html(story_html)
        next if story_attributes == false
        story_attributes.merge!(options[:attributes].to_h)
        story = build_story(story_attributes, on_create_only: %w[ story_created_on story_updated_at ])
        # stop if story too old
        return results.call(false) if options[:active_after] && story.story_active_at < options[:active_after]
        # skip if not worm story
        if !options.fetch(:is_worm_story) { is_worm_story?(story) }
          Rails.logger.info { "Skip: #{story.title.yellow}" }
          next
        end
        story = save_story(story)
        update_chapters_for_story!(story) if options[:chapters] != false
        stories << story
      end
      results.call(true)
    end

    def update_chapters_for_story!(story)
      crawler.get("#{story.location_path}/threadmarks", {}, { log_level: Logger::WARN })
      update_chapters_for_story_from_html!(story, crawler.html)
    end

    def update_chapters_for_story_from_html!(story, html)
      new_chapters, position = [], 0
      parse_chapters_html(html).each do |chapter_html|
        position += 1
        chapter_attributes = parse_chapter_html(chapter_html)
        # update chapter
        chapter = story.chapters.get(position: position) || story.chapters.build(position: position)
        chapter.assign_attributes(chapter_attributes)
        chapter.save! if chapter.has_changes_to_save?
        new_chapters << chapter
      end
      story.chapters = new_chapters
    end

  private

    def parse_stories_html(stories_html)
      stories_html.css("ol.discussionListItems li.discussionListItem:not(.sticky)")
    end

    def parse_story_html(story_html)
      # skip unavailable stories
      return false if story_html.css(".lastPostInfo").text.strip == "N/A"
      # html selections
      main_html       = story_html.css(".main")
      title_html      = main_html.css("h3.title a.PreviewTooltip").first
      author_html     = main_html.css(".username")
      word_count_html = main_html.css(".OverlayTrigger")
      created_html    = main_html.css(".DateTime").first
      active_html     = story_html.css(".lastPostInfo .DateTime").first
      # parse attributes
      title         = title_html.text
      location_path = "/#{title_html[:href].remove(/\/(unread)?\z/)}"
      location_id   = story_html[:id]
      author        = author_html.text
      word_count    = word_count_html.text.remove("Word Count: ")
      created_at    = abbr_html_to_time(created_html)
      active_at     = abbr_html_to_time(active_html)
      # attributes
      {
        title:            title,
        location_id:      location_id,
        location_path:    location_path,
        author:           author,
        word_count:       word_count,
        story_active_at:  active_at,
        story_created_on: created_at,
        story_updated_at: created_at,
      }.with_indifferent_access
    end

    def parse_chapters_html(chapters_html)
      chapters_html.css("div.threadmarkList li.primaryContent")
    end

    def parse_chapter_html(chapter_html)
      # html selections
      updated_html = chapter_html.css(".DateTime").first
      preview_html = chapter_html.css("a.PreviewTooltip").first
      # parse attributes
      title         = preview_html.text
      location_path = "/#{preview_html[:href]}"
      word_count    = chapter_html.text[/\([0-9.km]+\)/].to_s.remove("(").remove(")")
      updated_at    = abbr_html_to_time(updated_html)
      # attributes
      {
        title: title,
        location_path: location_path,
        word_count: word_count,
        chapter_created_on: updated_at,
        chapter_updated_at: updated_at,
      }.with_indifferent_access
    end

    def abbr_html_to_time(abbr_html)
      abbr_html["data-time"]  ? Time.at(abbr_html["data-time"].to_i) : Date.parse(abbr_html.text)
    end
  end
end
