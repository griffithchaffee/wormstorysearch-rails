module LocationStoryChapterConcern
  extend ActiveSupport::Concern

  included do
    # modules/constants
    class_constant_builder(:categories, %w[ category label ]) do |new_const|
      new_const.add(category: "chapter", label: "Chapter")
      new_const.add(category: "omake",   label: "Omake")
    end

    # associations/scopes/validations/callbacks/macros
    validates_in_list(:category, const.categories.map(&:category))
    validate do
      if chapter_created_on? && chapter_updated_at? && chapter_created_on > chapter_updated_at
        errors.add(:chapter_updated_at, "[#{chapter_updated_at}] must come after chapter creation date [#{chapter_created_on}]")
      elsif chapter_created_on? && chapter_created_on < story.story_created_on
        # chapters can slightly newer than story due to timezone conversions
        if chapter_created_on == story.story_created_on - 1.day
          self.chapter_created_on = story.story_created_on
        else
          errors.add(:chapter_created_on, "[#{chapter_created_on}] must come after story creation date [#{story.story_created_on}]")
        end
      end
    end

    before_validation do
      if will_save_change_to_title? && !category?
        self.category = category!
      end
    end

    after_save do
      # cache latest update to story for easy queries
      if story && story.is_unlocked?
        if saved_change_to_attribute?(:chapter_updated_at) && story.reload.story_updated_at < chapter_updated_at
          story.story_updated_at = chapter_updated_at
          story.read_url = story.read_url!
          story.save! if story.has_changes_to_save?
        end
      end
    end
  end

  # public/private/protected/classes
  def title=(new_title)
    self[:title] = new_title.to_s.normalize.presence
  end

  def word_count=(new_word_count)
    self[:word_count] = new_word_count.to_s.human_size_to_i
  end

  def category_label
    const.categories.fetch(category).label
  end

  def category!
    "omake".in?(title.slugify.split("_")) ? "omake" : "chapter"
  end
end
