module LocationSearcher
  class SufficientvelocitySearcher < UniversalSearcher
    attr_reader :config, :crawler, :search_options, :story_model

    def initialize
      @story_model = SufficientvelocityStory
      @config = story_model.const
      @crawler = SiteCrawler.new(config.location_host)
    end

    def search!(time, search_options = {})
      @search_options = search_options.with_indifferent_access
      time = time.ago if time.is_a?(ActiveSupport::Duration)
      Rails.logger.silence(Logger::INFO) do
        login!
        update_stories_newer_than!(time)
        update_quests_newer_than!(time)
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

    def update_stories_newer_than!(time)
      continue, page = true, 0
      # crawl "User Fiction" forum
      while continue do
        page += 1
        # prevent infinite loop
        raise ArgumentError, "crawled too many pages on" if page > config.location_max_story_pages
        # crawl latest threads
        crawler.get("forums/user-fiction.2/#{"page-#{page}" if page > 1}", { order: "last_post_date", direction: "desc" }, { log_level: Logger::INFO })
        stories_html = crawler.html.find_all("ol.discussionListItems li.discussionListItem:not(.sticky)")
        # stop on last page
        continue = false if stories_html.size == 0
        # parse threads
        stories_html.each do |story_html|
          story_attributes = parse_story_html(story_html)
          story = build_story(story_attributes, on_create_only: %w[ story_created_on story_updated_at ])
          # skip non-worm threads
          if !is_worm_story?(story)
            Rails.logger.info { "Skip: #{story.title.yellow}" }
            next
          end
          story = save_story(story)
          update_chapters_for_story!(story)
          # stop if older than time
          if story.story_active_at < time
            continue = false
            break
          end
        end
      end
    end

    def update_quests_newer_than!(time)
      continue, page = true, 0
      # crawl "Quests" forum
      while continue do
        page += 1
        # prevent infinite loop
        raise ArgumentError, "crawled too many pages on" if page > config.location_max_quest_pages
        # crawl latest threads
        crawler.get("/forums/quests.29/#{"page-#{page}" if page > 1}", { order: "last_post_date", direction: "desc" }, { log_level: Logger::INFO })
        stories_html = crawler.html.find_all("ol.discussionListItems li.discussionListItem:not(.sticky)")
        # stop on last page
        continue = false if stories_html.size == 0
        # parse threads
        stories_html.each do |story_html|
          story_attributes = parse_story_html(story_html)
          next if !story_attributes
          story_attributes[:category] = "quest"
          story = build_story(story_attributes, on_create_only: %w[ story_created_on story_updated_at ])
          # skip non-worm threads
          if !is_worm_story?(story)
            Rails.logger.info { "Skip: #{story.title.yellow}" }
            next
          end
          story = save_story(story)
          update_chapters_for_story!(story)
          # stop if older than time
          if story.story_active_at < time
            continue = false
            break
          end
        end
      end
    end

    def parse_story_html(story_html)
      # html selections
      main_html       = story_html.css(".main")
      title_html      = main_html.css("h3.title a.PreviewTooltip").first
      author_html     = main_html.css(".username")
      word_count_html = main_html.css(".OverlayTrigger")
      created_html    = main_html.css(".DateTime").first
      active_html     = story_html.css(".lastPostInfo .DateTime").first
      # parse attributes
      # skip N/A threads - Intro to Questing
      # https://forums.sufficientvelocity.com/forums/quests.29/page-132?direction=desc&order=last_post_date
      return false if title_html.blank?
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
      }
    end

    def update_chapters_for_story!(story)
      # get threadmarks
      crawler.get("#{story.location_path}/threadmarks", {}, { log_level: Logger::WARN })
      # parse threadmarks
      position = 0
      new_chapters = []
      crawler.html.find_all("div.threadmarkList li.primaryContent").each do |html_li|
        position += 1
        # html selections
        updated_html = html_li.css(".DateTime").first
        preview_html = html_li.css("a.PreviewTooltip").first
        # chapter attributes
        title         = preview_html.text
        location_path = preview_html[:href]
        word_count    = html_li.text[/\([0-9.km]+\)/].to_s.remove("(").remove(")")
        updated_at    = abbr_html_to_time(updated_html)
        # update chapter
        chapter = story.chapters.get(position: position) || story.chapters.build(position: position)
        chapter.assign_attributes(
          title: title,
          location_path: location_path,
          word_count: word_count,
          chapter_created_on: updated_at,
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
