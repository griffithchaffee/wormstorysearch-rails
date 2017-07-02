module LocationSearcher
  class UniversalSearcher

    def build_story(story_attributes)
      story_attributes = story_attributes.with_indifferent_access
      story_finder = { location_id: story_attributes[:location_id] }
      story = story_model.find_by(story_finder) || story_model.new
      story.assign_attributes(story_attributes.except(*%w[
        story_created_on
        story_updated_at
      ]))
      if story.unsaved? || search_options[:reset]
        story.assign_attributes(story_attributes.slice(*%w[
          story_created_on
          story_updated_at
        ]))
      end
      story
    end

    def save_story(story)
      story.story = story.story!
      story.save! if story.has_changes_to_save?
      story
    end

    def is_worm_story?(story)
      title_words = story.title.slugify.split("_")
      is_worm_story = (title_words & %w[ worm wormverse wormfic wormsnip taylor ]).present?
      is_worm_story ||= title_words.find { |title| title.starts_with?("wormx") }
      is_worm_story
    end

    class << self
      def search!(*params)
        new.search!(*params)
      end
    end

  end
end
