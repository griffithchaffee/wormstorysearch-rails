module LocationStoryChapterConcern
  extend ActiveSupport::Concern

  included do
    class_constant_builder(:categories, %w[ category label ]) do |new_const|
      new_const.add(category: "chapter", label: "Chapter")
      new_const.add(category: "omake",   label: "Omake")
    end

    before_validation do
      if will_save_change_to_title? && !category?
        self.category = category!
      end
    end

    validate do
      if chapter_created_on? && chapter_updated_at? && chapter_created_on > chapter_updated_at
        errors.add(:chapter_updated_at, "[#{chapter_updated_at}] must come after chapter creation date [#{chapter_created_on}]")
      elsif chapter_created_on? && chapter_created_on < story.story_created_on
        errors.add(:chapter_created_on, "[#{chapter_created_on}] must come after story creation date [#{story.story_created_on}]")
      end
    end

    after_save do
      # cache latest update to story for easy queries
      if story && story.is_unlocked?
        if saved_change_to_attribute?(:chapter_updated_at)
          story.update!(story_updated_at: chapter_updated_at) if story.reload.story_updated_at < chapter_updated_at
        end
      end
    end
  end

  def title=(new_title)
    self[:title] = new_title.to_s.strip.presence
  end

  def word_count=(new_word_count)
    self[:word_count] = new_word_count.to_s.human_size_to_i
  end

  def category!
    "omake".in?(title.slugify.split("_")) ? "omake" : "chapter"
  end

  def category_label
    const.categories.fetch(category)
  end

  def category!
    "omake".in?(title.slugify.split("_")) ? "omake" : "chapter"
  end
end
