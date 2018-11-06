module LocationSearcher
  class SpacebattlesSearcher < UniversalSearcher
    attr_reader :config, :search_options, :story_model

    def initialize
      @story_model = SpacebattlesStory
      @config = story_model.const
      @search_options = {}
    end

    def is_authentication?(check_authentication)
      (@authentication || "unknown") == check_authentication.to_s.verify_in!(%w[ authenticated unauthenticated unknown ])
    end

    def set_authentication(new_authentication)
      @authentication = new_authentication.to_s.verify_in!(%w[ authenticated unauthenticated unknown ])
    end

    def search!(active_after, search_options = {})
      @search_options = search_options.with_indifferent_access
      active_after = active_after.ago if active_after.is_a?(ActiveSupport::Duration)
      Rails.logger.silence(Logger::INFO) do
        login!
        update_stories!(active_after: active_after)
        update_quests!(active_after: active_after)
      end
      self
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
          set_authentication(:authenticated)
          Rails.logger.info { "Logged in as #{config.location_username}".green }
        else
          set_authentication(:unauthenticated)
          subject = "#{config.location_label} Login Failed"
          body = crawler.response.headers.reverse_merge("status" => crawler.response.status).map { |k,v| "#{k.ljust(20)} => #{v}" }.join("\n")
          DynamicMailer.email(subject: subject, body: body).deliver_now
          Rails.logger.warn { "Login failed for #{config.location_username}".yellow }
        end
      else
        Rails.logger.warn { "Skipping login".yellow }
      end
    end

    def update_chapter_likes!(chapter)
      crawler.get(chapter.read_url, {}, log_level: Logger::INFO, follow_redirects: true)
      # unable to view chapter
      if crawler.response.status == 403 && is_authentication?(:authenticated)
        chapter.update!(likes_updated_at: Time.zone.now)
        return chapter
      elsif crawler.response.status == 404
        chapter.story.destroy!
        return chapter
      end
      verify_response_status!(debug_message: "#{self.class} update_chapter_likes #{chapter.inspect}")
      page_html = crawler.html
      # no messages
      if page_html.css("li.message").size != 0
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
      end
      chapter.likes_updated_at = Time.zone.now
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
        verify_response_status!(debug_message: "#{self.class} update_stories")
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
        crawler.get("/forums/roleplaying-quests-story-debates.60/#{"page-#{page}" if page > 1}", search_params, log_level: Logger::INFO)
        verify_response_status!(debug_message: "#{self.class} update_quests")
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
      crawler.get("#{story.location_path}/threadmarks")
      verify_response_status!(debug_message: "#{self.class} update_chapters_for_story #{story.inspect}", status: [200, 404])
      update_chapters_for_story_from_html!(story, crawler.html)
    end

    def update_chapters_for_story_from_html!(story, html)
      new_chapters, position = [], 0
      parse_chapters_html(html).each do |chapter_html|
        position += 1
        chapter_attributes = parse_chapter_html(chapter_html)
        # skip invalid chapters
        next if !chapter_attributes
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
        author_name:      author,
        word_count:       word_count,
        story_active_at:  active_at,
        story_created_on: created_at,
        story_updated_at: created_at,
      }.with_indifferent_access
    end

    def parse_chapters_html(chapters_html)
      chapters_html = chapters_html.css("div.threadmarkList")
      # fetch excluded chapters - "..." placeholder in threadmark list
      threadmark_fetcher = chapters_html.at_css("li.primaryContent.ThreadmarkFetcher")
      if threadmark_fetcher
        csrf_token = crawler.response.body.lines.find { |line| line =~ /_csrfToken:/ }.split('"').second
        crawler.post(
          "/index.php?threads/threadmarks/load-range",
          {
            _xfToken: csrf_token,
            category_id: threadmark_fetcher["data-category-id"],
            thread_id: threadmark_fetcher["data-thread-id"],
            min: threadmark_fetcher["data-range-min"],
            max: threadmark_fetcher["data-range-max"],
          }
        )
        verify_response_status!(debug_message: "#{self.class} update_chapters_html threadmark fetcher")
        fetched_chapters_html = crawler.html.css("li.primaryContent")
        threadmark_fetcher.add_next_sibling(fetched_chapters_html)
        threadmark_fetcher.remove
      end
      chapters_html.css("li.primaryContent")
    end

    def parse_chapter_html(chapter_html)
      # skip ThreadmarkFetcher links
      return false if "ThreadmarkFetcher".in?(chapter_html["class"])
      # html selections
      preview_html = chapter_html.css("a.PreviewTooltip").first
      # parse attributes
      title         = preview_html.text
      location_path = "/#{preview_html[:href]}"
      likes         = chapter_html["data-likes"]
      word_count    = chapter_html["data-words"]
      updated_at    = Time.at(chapter_html["data-content-date"].to_i.nonzero?)
      # attributes
      {
        title: title,
        location_path: location_path,
        likes: likes,
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
