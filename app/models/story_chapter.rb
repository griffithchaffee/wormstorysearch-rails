class StoryChapter < ApplicationRecord
  # modules/constants

  # associations/scopes/validations/callbacks/macros
  belongs_to :story

  generate_column_scopes

  validates_presence_of_required_columns

  after_save do
    # cache latest update to story for easy queries
    if saved_change_to_attribute?(:chapter_updated_at)
      story.update!(story_updated_at: chapter_updated_at) if story.story_updated_at < chapter_updated_at
    end
  end

  # public/private/protected/classes

  def title=(new_title)
    self[:title] = new_title.to_s.strip.presence
  end

end
