module LocationSearcher
  class FanfictionSearcher < UniversalSearcher
    attr_reader :config, :crawler, :search_options, :story_model

    def initialize
      @story_model = FanfictionStory
      @config = story_model.const
      @crawler = SiteCrawler.new(config.location_host)
    end

    def search!(time, search_options = {})
      @search_options = search_options.with_indifferent_access
      time = time.ago if time.is_a?(ActiveSupport::Duration)
      Rails.logger.silence(Logger::INFO) do
        update_stories_newer_than!(time)
      end
    end

    def update_stories_newer_than!(time)
      continue, page = true, 0
      # crawl "Creative Writing" subforum "Worm"
      while continue do
        page += 1
        # prevent infinite loop
        raise ArgumentError, "crawled too many pages on" if page > config.location_max_story_pages
        # crawl latest threads
        crawler.get("/forums/worm.115/#{"page-#{page}" if page > 1}", { order: "last_post_date", direction: "desc" }, { log_level: Logger::INFO })
        threads_html = crawler.html.find_all("ol.discussionListItems li.discussionListItem:not(.sticky)")
        # stop on last page
        continue = false if threads_html.size == 0
        # parse threads
        threads_html.each do |thread_html|
          story_attributes = parse_thread(thread_html)
          story = build_story(story_attributes)
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

    def update_stories_newer_than!(time)
      %w[ /book/Worm/ /Worm-Crossovers/10867/0/ ].each do |stories_path|
        continue, page = true, 0
        while continue do
          page += 1
          # prevent infinite loop
          raise ArgumentError, "crawled too many pages on" if page > config.location_max_story_pages
          # crawl latest stories
          #   [srt=1] Sort: Updated At [srt=1]
          #   [r=10]  Rating: All [r=10]
          crawler.get(stories_path, { srt: 1, r: 10, p: page }, { log_level: Logger::INFO })
          stories_html = crawler.html.find_all("div.z-list")
          # stop on last page
          continue = false if stories_html.size == 0
          # parse stories
          stories_html.each do |story_html|
            story_attributes = parse_story_html(story_html)
            story = build_story(story_attributes)
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
    end

    def parse_story_html(story_html)
      # html selections
      title_html = story_html.css("a.stitle").first
      main_html = story_html.css("div")
      details_html = main_html > "div"
      # parse attributes
      title             = title_html.text
      location_path     = title_html[:href]
      location_story_id = location_path.match(/\d+/)[0]
      author            = story_html.css("a[href^='/u/']").text
      description       = main_html.text.remove(details_html.text)
      word_count        = details_html.text.match(/Words: ([0-9,]+)/)[1].remove(/\D/)
      updated_at        = Time.at(details_html.css("span").first["data-xutime"].to_i.nonzero?)
      created_at        = Time.at(details_html.css("span").last["data-xutime"].to_i.nonzero?)
      active_at         = updated_at
      if "Crossover - ".in?(details_html.text)
        crossover = details_html.text.match(/Crossover - (.*?) - /)[1]
      end
      # attributes
      {
        title: title,
        location_id: location_story_id,
        location_path: location_path,
        author: author,
        description: description,
        crossover: crossover,
        word_count: word_count,
        story_active_at: active_at,
        story_created_on: created_at,
        story_updated_at: updated_at,
      }
    end

    def update_chapters_for_story!(story)
      # get threadmarks
      crawler.get("#{story.location_path}", {}, { log_level: Logger::WARN })
      # parse threadmarks
      position = 0
      new_chapters = []
      crawler.html.find_all("#chap_select option").each do |html_option|
        position += 1
        # chapter attributes
        title                  = html_option.text.remove(/\A\d+\. /)
        # convert location "/s/12547526/1/Lisa-s-Love-Limbo" => "/s/12547526/2/Lisa-s-Love-Limbo"
        location_path_parts    = story.location_path.split("/")
        location_path_parts[3] = html_option[:value]
        location_path          = location_path_parts.join("/")
        created_at             = story.story_created_on
        updated_at             = story.story_created_on
        # update chapter
        chapter = story.chapters.get(position: position) || story.chapters.build(position: position)
        chapter.assign_attributes(
          title: title,
          location_path: location_path,
          chapter_created_on: created_at,
          chapter_updated_at: updated_at,
        )
        chapter.save! if chapter.has_changes_to_save?
        new_chapters << chapter
      end
      story.chapters = new_chapters
    end
  end
end

