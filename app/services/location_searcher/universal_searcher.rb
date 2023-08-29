module LocationSearcher
  class UniversalSearcher

    def crawler
      return @crawler if @crawler
      @crawler = SiteCrawler.new(config.location_host)
      @crawler.throttle = 3.seconds
      @crawler.proxy = config.location_proxy.presence
      @crawler.default_headers["User-Agent"] = "Worm Story Search (+http://wormstorysearch.com; wormstorysearch@gmail.com)"
      @crawler.default_headers["Accept-Encoding"] = "identity"
      @crawler
    end

    def build_story(story_attributes, options = {})
      options = options.with_indifferent_access
      on_create_only_attributes = options.fetch(:on_create_only) { [] }
      story_attributes = story_attributes.with_indifferent_access
      story_finder = { location_id: story_attributes[:location_id] }
      story = story_model.find_by(story_finder) || story_model.new
      story.assign_attributes(story_attributes.except(*on_create_only_attributes))
      if story.unsaved? || search_options[:reset]
        story.assign_attributes(story_attributes.slice(*on_create_only_attributes))
      end
      story
    end

    def save_story(story)
      story.author = story.author!
      story.story = story.story!
      return if !(story.story && story.story.saved?)
      Rails.logger.info do
        log = "Save: #{story.title.green} [#{story.id || "New"}]".ljust(70)
        log += " => #{story.story.title.green}"
        log += " [#{story.story.crossover}]".green if story.story.crossover?
        log += " [#{story.story_id}]"
        log
      end
      story.save! if story.has_changes_to_save?
      story
    end

    def is_worm_story?(story)
      title_words = story.title.slugify.split("_")
      is_worm_story = (title_words & %w[ worm wormverse wormfic wormsnip taylor ]).present?
      is_worm_story ||= title_words.any? { |title| title.starts_with?("wormx") }
      is_worm_story
    end

    def verify_response_status!(debug_message:, status: 200)
      if !crawler.response.status.in?(Array(status))
        raise InvalidResponse, "Invalid Response Status [#{crawler.response.status}]: #{debug_message}"
      end
    end

    def inspect
      crawler = self.crawler
      remove_instance_variable(:@crawler)
      result = super
      @crawler = crawler
      result
    end

    class << self
      def search!(*params)
        new.search!(*params)
      end
    end

    class InvalidResponse < StandardError
    end

  end
end
