module LocationSearcher
  class SufficientvelocitySearcher < UniversalSearcher
    attr_reader :config, :search_options, :story_model

    def initialize
      @story_model = SufficientvelocityStory
      @config = story_model.const
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
      ##### SV account banned so cancel authentication attempts
      set_authentication(:authenticated)
      return
      #####
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
      # find chapter id (by url or first post)
      # "threads/expand-your-world-worm-the-world-ends-with-you.450360/page-10#post-35820316" => post-35820316
      location_id = chapter.location_path.split("#")[1]
      # article
      chapter_html = location_id ? page_html.at_css("#js-#{location_id}") : page_html.at_css("article")
      # no messages
      if chapter_html
        # sum of all like types
        likes = chapter_html.css(".sv-rating__count").map { |span| span.text.remove(/\D/).to_i }.sum
        # set likes
        chapter.likes = likes
      else
        Rails.logger.warn { "No chapter_html for #{chapter.class}-#{chapter.id} at #{chapter.location_path}" }
      end
      chapter.likes_updated_at = Time.zone.now
      chapter.save! if chapter.has_changes_to_save?
      chapter
    end

    def update_stories!(options = {})
      options = options.with_indifferent_access
      page = options.delete(:page) || 0
      # crawl "User Fiction" subforum "Worm"
      loop do
        page += 1
        # prevent infinite loop
        raise ArgumentError, "crawled too many pages on" if page > config.location_max_story_pages
        # crawl latest threads
        search_params = { order: "last_post_date", direction: "desc" }
        crawler.get("/forums/worm.94/#{"page-#{page}" if page > 1}", search_params, log_level: Logger::INFO)
        verify_response_status!(debug_message: "#{self.class} update_stories")
        results = update_stories_from_html!(crawler.html, options.merge(is_worm_story: true))
        # stop on last page
        break if results[:more] != true
      end
    end

    def update_quests!(options = {})
      options = options.with_indifferent_access
      page = options.delete(:page) || 0
      # crawl "Quests" forum
      loop do
        page += 1
        # prevent infinite loop
        raise ArgumentError, "crawled too many pages on" if page > config.location_max_quest_pages
        # crawl latest threads
        search_params = { order: "last_post_date", direction: "desc" }
        crawler.get("/forums/quests.29/#{"page-#{page}" if page > 1}", search_params, log_level: Logger::INFO)
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
      crawler.get("#{story.location_path}/threadmarks", category_id: 1)
      verify_response_status!(debug_message: "#{self.class} update_chapters_for_story #{story.inspect}", status: [200, 404])
      threadmarks_html = crawler.html
      threadmarks_container = threadmarks_html.css(".block-body--threadmarkBody .structItemContainer")
      threadmarks_size = threadmarks_container.css(".structItem").size
      if threadmarks_size == 50
        2.times do |i|
          last_threadmark = threadmarks_container.children.last
          crawler.get("#{story.location_path}/threadmarks-load-range", threadmark_category_id: 1, min: threadmarks_container.css(".structItem").size, max: 1000)
          loaded_threadmarks_size = crawler.html.css(".structItemContainer .structItem").size
          loaded_threadmarks_html = crawler.html.css(".structItemContainer").children
          last_threadmark.after(loaded_threadmarks_html)
          break if loaded_threadmarks_size != 200
        end
      end
      update_chapters_for_story_from_html!(story, threadmarks_html)
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
      stories_html.css("div.js-threadList div.js-inlineModContainer")
    end

    def parse_story_html(story_html)
      # skip unavailable stories
      return false if story_html.css(".lastPostInfo").text.strip == "N/A"
      # html selections
      main_html       = story_html.css(".structItem-cell--main")
      title_html      = main_html.css(".structItem-title a").last
      details_html    = main_html.css(".structItem-minor").first
      activity_html   = story_html.css(".structItem-cell--latest").first
      word_count_html = details_html.css("li").to_a.third
      # parse attributes
      title         = title_html.text
      location_path = "#{title_html[:href].remove(/\/(unread)?\z/)}"
      location_id   = location_path.split(".").last
      author        = details_html.css("a.username").text
      word_count    = word_count_html ? word_count_html.text.strip.remove("Words: ") : 0
      created_at    = abbr_html_to_time(details_html.css("time").first)
      # it is possible to have N/A for activity html
      active_at_html = activity_html.css("time").first
      active_at      = active_at_html.present? ? abbr_html_to_time(active_at_html) : Time.zone.now
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

    def parse_chapters_html(original_chapters_html)
      chapters_html = original_chapters_html.css(".block-body--threadmarkBody")
      # fetch excluded chapters - "..." placeholder in threadmark list
      csrf_token = crawler.html.css("[name=_xfToken]").first[:value]
      5.times do |i|
        i += 1
        # should never have to fetch threads more than 1 or 2 times
        raise(ArgumentError, "parse_chapters_html threadmark_fetcher looped #{i} times") if i == 5
        threadmark_fetcher = chapters_html.at_css(".structItem--threadmark-filler")
        break if !threadmark_fetcher
        fetch_url = threadmark_fetcher.css(".structItem-cell--main").first["data-fetchurl"]
        #_xfRequestUri=/threads/amelia-worm-au.13577/threadmarks&_xfWithData=1&_xfToken=1563072243,8b000fdbae57099276185327a149e058&_xfResponseType=json
        crawler.post(
          fetch_url,
          {
            _xfResponseType: "json",
            _xfToken: csrf_token,
            _xfWithData: 1,
          }
        )
        verify_response_status!(debug_message: "#{self.class} update_chapters_html threadmark fetcher")
        fetched_chapters_html = JSON.parse(crawler.response.body).dig("html", "content")
        threadmark_fetcher.add_next_sibling(fetched_chapters_html)
        threadmark_fetcher.remove
      end
      chapters_html.css(".structItem--threadmark")
    end

    def parse_chapter_html(chapter_html)
      # skip ThreadmarkFetcher links
      return false if "structItem--threadmark-filler".in?(chapter_html["class"])
      # html selections
      preview_html = chapter_html.css(".structItem-title a").first
      # parse attributes
      title         = preview_html.text
      location_path = preview_html[:href]
      word_count    = chapter_html.css(".structItem-cell--meta").text.remove(/Words|Word Count/)
      updated_at    = abbr_html_to_time(chapter_html.css(".structItem-cell--latest time").first)
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
