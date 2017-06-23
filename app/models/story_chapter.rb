class StoryChapter < ApplicationRecord
  # modules/constants
  CATEGORIES = %w[ chapter omake ]

  # associations/scopes/validations/callbacks/macros
  belongs_to :story

  generate_column_scopes

  validates_presence_of_required_columns
  validates_in_list :category, CATEGORIES

  before_save do
    if will_save_change_to_title?
      self.category = "omake".in?(title.downcase.split(/\W/)) ? "omake" : "chapter"
    end
  end

  after_save do
    # cache latest update to story for easy queries
    if saved_change_to_attribute?(:chapter_updated_at)
      story.update!(story_updated_at: chapter_updated_at) if story.reload.story_updated_at < chapter_updated_at
    end
  end

  # public/private/protected/classes
  def title=(new_title)
    self[:title] = new_title.to_s.strip.presence
  end

  def word_count=(new_word_count)
    self[:word_count] = new_word_count.to_s.human_size_to_i
  end

end
