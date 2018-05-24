module LocationSearcher
  class ArchiveofourownSearcher < UniversalSearcher
    attr_reader :config, :search_options, :story_model

    def initialize
      @story_model = ArchiveofourownStory
      @config = story_model.const
      @crawler = SiteCrawler.new(config.location_host)
    end

    def search!(active_after, search_options = {})
      @search_options = search_options.with_indifferent_access
      active_after = active_after.ago if active_after.is_a?(ActiveSupport::Duration)
      Rails.logger.silence(Logger::INFO) do
        update_stories!(active_after: active_after)
      end
      self
    end

    def update_story_kudos!(story)
      crawler.get(story.location_path, {}, log_level: Logger::INFO, follow_redirects: true)
      if crawler.response.status == 404
        story.destroy!
        return story
      end
      verify_response_status!(url: story.location_path)
      details_html = crawler.html.css("dl.stats").first
      # return if story not found
      if details_html.blank?
        story.update!(kudos_updated_at: Time.zone.now)
        return story
      end
      # parse kudos
      kudos = details_html.css("dd.kudos")
      if kudos.present?
        story.kudos = kudos.text.remove(/\D/).to_i
      end
      story.kudos_updated_at = Time.zone.now
      story.save! if story.has_changes_to_save?
      story
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
        search_params = {
          page: page,
          tag_id: "Parahumans Series - Wildbow",
          "work_search[sort_column]" => "revised_at",
        }
        crawler.get("/works", search_params, log_level: Logger::INFO)
        results = update_stories_from_html!(crawler.html, options)
        # stop on last page
        break if results[:more] != true
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
        # skip this weird story - http://archiveofourown.org/works/12857685/chapters/29363547
        next if story.title == "[-]"
        # stop if story too old
        return results.call(false) if options[:active_after] && story.story_active_at < options[:active_after]
        story = save_story(story)
        update_chapters_for_story!(story) if options[:chapters] != false
        stories << story
      end
      results.call(true)
    end

    def update_chapters_for_story!(story)
      crawler.get("#{story.location_path}/navigate", {}, log_level: Logger::WARN)
      update_chapters_for_story_from_html!(story, crawler.html)
    end

    def update_chapters_for_story_from_html!(story, html)
      new_chapters, position = [], 0
      parse_chapters_html(html).each do |chapter_html|
        position += 1
        chapter_attributes = parse_chapter_html(chapter_html)
        # index page does not include published date so set it to earliest chapter
        if chapter_attributes[:chapter_created_on] < story.story_created_on
          story.update!(story_created_on: chapter_attributes[:chapter_created_on])
        end
        # update chapter
        chapter = story.chapters.get(position: position) || story.chapters.build(position: position)
        original_chapter_updated_at = chapter.chapter_updated_at
        chapter.assign_attributes(chapter_attributes)
        new_chapter_updated_at = chapter.chapter_updated_at
        # only change chapter_updated_at on create and when old updated_at is invalid
        if chapter.saved?
          chapter.chapter_updated_at = original_chapter_updated_at
          if !chapter.valid?
            chapter.chapter_updated_at = new_chapter_updated_at
          end
        end
        chapter.save! if chapter.has_changes_to_save?
        new_chapters << chapter
      end
      story.chapters = new_chapters
    end

  private

    def parse_stories_html(stories_html)
      stories_html.css("li.work")
    end

    def parse_story_html(story_html)
      # html selections
      header_html      = story_html.css(".header").first
      title_html       = header_html.css("h4").first
      details_html     = story_html.css(".stats").first
      description_html = story_html.css(".summary").first
      crossover_html   = story_html.css(".fandoms")
      # parse attributes
      title             = title_html.css("a[href^='/works/']").first.text
      location_path     = title_html.css("a[href^='/works/']").first[:href]
      location_story_id = location_path.match(/\d+/)[0]
      author            = title_html.css("a[rel=author]").text
      description       = description_html.text.to_s.strip if description_html.present?
      word_count        = details_html.css("dd.words").text.remove(/\D/).to_i
      kudos             = details_html.css("dd.kudos").text.remove(/\D/).to_i
      status            = story_html.css("span.complete-yes").present? ? "complete" : "ongoing"
      is_nsfw           = story_html.css("span.rating-explicit").present?
      updated_on        = Date.parse(story_html.css("p.datetime").text)
      updated_at        = updated_on >= Date.today ? Time.zone.now : Time.at(updated_on.to_i)
      created_on        = updated_on
      active_at         = Time.parse("#{updated_on} 23:59:59")
      exclude_tags      = ["Worm - Wildbow", "Parahumans Series - Wildbow"]
      crossover         = (crossover_html.css(".tag").map(&:text) - exclude_tags).first
      # attributes
      {
        title: title,
        location_id: location_story_id,
        location_path: location_path,
        author_name: author,
        description: description,
        crossover: crossover,
        word_count: word_count,
        status: status,
        is_nsfw: is_nsfw,
        kudos: kudos,
        story_active_at: active_at,
        story_created_on: created_on,
        story_updated_at: updated_at,
      }
    end

    def parse_chapters_html(chapters_html)
      chapters_html.css("ol.chapter li")
    end

    def parse_chapter_html(chapter_html)
      # parse attributes
      # convert title "1. Glimmer 1.1" => "Glimmer 1.1"
      title         = chapter_html.css("a[href^='/works/']").first.text.split(" ")[1..-1].join(" ")
      location_path = chapter_html.css("a[href^='/works/']").first[:href]
      updated_on    = Date.parse(chapter_html.css("span.datetime").text)
      updated_at    = updated_on >= Date.today ? Time.zone.now : Time.at(updated_on.to_i)
      created_on    = updated_on
      # attributes
      {
        title: title,
        location_path: location_path,
        chapter_updated_at: updated_at,
        chapter_created_on: created_on,
      }.with_indifferent_access
    end
  end
end
