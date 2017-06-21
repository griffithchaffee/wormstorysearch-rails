class Story < ApplicationRecord
  # modules/constants

  # associations/scopes/validations/callbacks/macros
  has_many :chapters, class_name: "StoryChapter"

  generate_column_scopes

  validates_presence_of_required_columns

  # public/private/protected/classes

  def title=(new_title)
    self[:title] = new_title.to_s.strip.presence
  end

end
