=begin
module StorySearcher
  class FanfictionSearcher < UniversalSearcher
    attr_reader :configuration, :crawler, :updated_after, :location, :search_options

    def initialize
      @location = "fanfiction"
      @configuration = Rails.application.settings.searchers[@location]
      @crawler = SiteCrawler.new(Story.const.locations.fetch(@location).host)
      crawler.logger = Rails.logger
    end

    def search!(time, search_options = {})
      @search_options = search_options.with_indifferent_access
      time = time.ago if time.is_a?(ActiveSupport::Duration)
      Rails.logger.silence(Logger::INFO) do
        update_stories_newer_than!(time)
      end
    end

    def update_stories_newer_than!(time)
      %w[ /book/Worm/ /Worm-Crossovers/10867/0/ ].each do |stories_path|
        continue, page = true, 0
        while continue do
          page += 1
          # prevent infinite loop
          raise ArgumentError, "crawled too many pages on" if page > configuration.max_pages
          # crawl latest stories
          #   [srt=1] Sort: Updated At [srt=1]
          #   [r=10]  Rating: All [r=10]
          crawler.get(stories_path, { srt: 1, r: 10, p: page }, { log_level: Logger::INFO })
          stories_html = crawler.html.find_all("div.z-list")
          # stop on last page
          continue = false if stories_html.size == 0
          # parse stories
          stories_html.each do |story_html|
            story = update_story_from_html!(story_html)
            Rails.logger.info("Read: #{story.title.green}")
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

    def update_story_from_html!(story_html)
      # html selections
      title_html = story_html.css("a.stitle").first
      main_html = story_html.css("div")
      details_html = main_html > "div"
      # story attributes
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
      # update story
      story_finder = { location: location, location_story_id: location_story_id }
      story = Story.find_by(story_finder) || Story.new(story_finder)
      story.assign_attributes(
        title: title,
        location_path: location_path,
        location_story_id: location_story_id,
        author: author,
        description: description,
        crossover: crossover,
        word_count: word_count,
        story_active_at: active_at,
        story_created_on: created_at,
        story_updated_at: updated_at,
      )
      story.save! if story.has_changes_to_save?
      story
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
          chapter_created_at: created_at,
          chapter_updated_at: updated_at,
        )
        chapter.save! if chapter.has_changes_to_save?
        new_chapters << chapter
      end
      story.chapters = new_chapters
    end
  end
end
=end
