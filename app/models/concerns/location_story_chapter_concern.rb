module LocationStoryChapterConcern
  extend ActiveSupport::Concern

  included do
    # modules/constants
    class_constant_builder(:categories, %w[ category label ]) do |new_const|
      new_const.add(category: "chapter", label: "Chapter")
      new_const.add(category: "omake",   label: "Omake")
    end

    # associations/scopes/validations/callbacks/macros
    belongs_to :story, class_name: name.remove("Chapter")

    generate_column_scopes

    validates_presence_of_required_columns
    validates_in_list(:category, const.categories.map(&:category))
    validates(:position, uniqueness: { scope: :story_id })
    validate do
      # remove 1 day from created_on due to time-zone differences
      if chapter_created_on? && chapter_updated_at? && (chapter_created_on - 1.day) > chapter_updated_at
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
      if chapter_created_on? && chapter_created_on < story.story_created_on
        self.chapter_created_on = story.story_created_on
      end
      if chapter_created_on? && chapter_updated_at? && (chapter_created_on - 1.day) > chapter_updated_at
        self.chapter_updated_at = chapter_created_on
      end
    end

    after_save do
      # cache latest update to story for easy queries
      if story
        if saved_change_to_chapter_updated_at?
          story.reload
          story.read_url = story.read_url!
          story.story_updated_at = chapter_updated_at if story.story_updated_at < chapter_updated_at
          story.word_count = story.chapters.sum(&:word_count)
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

  def location_url
    "#{story.const.location_host}#{location_path}"
  end

  def <=>(other)
    position <=> other.position
  end
end
