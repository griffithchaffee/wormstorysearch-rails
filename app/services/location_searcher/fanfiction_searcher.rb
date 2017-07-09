module LocationSearcher
  class FanfictionSearcher < UniversalSearcher
    attr_reader :config, :crawler, :search_options, :story_model

    def initialize
      @story_model = FanfictionStory
      @config = story_model.const
      @crawler = SiteCrawler.new(config.location_host)
    end

    def search!(active_after, search_options = {})
      @search_options = search_options.with_indifferent_access
      active_after = active_after.ago if active_after.is_a?(ActiveSupport::Duration)
      Rails.logger.silence(Logger::INFO) do
        update_stories!(active_after: active_after)
      end
    end

    def update_stories!(initial_options = {})
      # crawl "User Fiction" forum
      %w[ /book/Worm/ /Worm-Crossovers/10867/0/ ].each do |stories_path|
        options = initial_options.with_indifferent_access
        page = options.delete(:page) || 0
        loop do
          page += 1
          # prevent infinite loop
          raise ArgumentError, "crawled too many pages on" if page > config.location_max_story_pages
          # crawl latest threads
          # crawl latest stories
          #   [srt=1] Sort: Updated At [srt=1]
          #   [r=10]  Rating: All [r=10]
          search_params = { srt: 1, r: 10, p: page }
          crawler.get(stories_path, search_params, log_level: Logger::INFO)
          results = update_stories_from_html!(crawler.html, options)
          # stop on last page
          break if results[:more] != true
        end
      end
    end

    def update_stories_from_html!(html, options = {})
      options = options.with_indifferent_access.assert_valid_keys(*%w[ active_after chapters ])
      stories_html = parse_stories_html(html)
      stories = []
      results = -> (more) { { stories: stories, more: more } }
      # stop on last page
      return results.call(false) if stories_html.size == 0
      # parse threads
      stories_html.each do |story_html|
        story_attributes = parse_story_html(story_html).merge(options[:attributes].to_h)
        story = build_story(story_attributes, on_create_only: %w[ story_created_on story_updated_at ])
        # stop if story too old
        return results.call(false) if options[:active_after] && story.story_active_at < options[:active_after]
        story = save_story(story)
        update_chapters_for_story!(story) if options[:chapters] != false
        stories << story
      end
      results.call(true)
    end

    def update_chapters_for_story!(story)
      crawler.get("#{story.location_path}", {}, log_level: Logger::WARN)
      update_chapters_for_story_from_html!(story, crawler.html)
    end

    def update_chapters_for_story_from_html!(story, html)
      new_chapters, position = [], 0
      parse_chapters_html(html).each do |chapter_html|
        position += 1
        chapter_attributes = parse_chapter_html(chapter_html, story)
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
      stories_html.css("div.z-list")
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
      status            = details_html.text.match(/- Complete/) ? "complete" : "ongoing"
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
        status: status,
        story_active_at: active_at,
        story_created_on: created_at,
        story_updated_at: updated_at,
      }
    end

    def parse_chapters_html(chapters_html)
      chapters_html.css("#chap_select option")
    end

    def parse_chapter_html(chapter_html, story)
      # parse attributes
      title                  = chapter_html.text.remove(/\A\d+\. /)
      # convert location "/s/12547526/1/Lisa-s-Love-Limbo" => "/s/12547526/2/Lisa-s-Love-Limbo"
      location_path_parts    = story.location_path.split("/")
      location_path_parts[3] = chapter_html[:value]
      location_path          = location_path_parts.join("/")
      created_at             = story.story_created_on
      updated_at             = story.story_created_on
      # attributes
      {
        title: title,
        location_path: location_path,
        chapter_created_on: created_at,
        chapter_updated_at: updated_at,
      }.with_indifferent_access
    end
  end
end
