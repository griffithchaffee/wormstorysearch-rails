class SufficientvelocityStoryChapter < ApplicationRecord

  # modules/constants
  include LocationStoryChapterConcern

  # associations/scopes/validations/callbacks/macros
  belongs_to :story, class_name: "SufficientvelocityStory"

  generate_column_scopes

  validates_presence_of_required_columns
  validates_in_list :category, const.categories.map(&:category)

  # public/private/protected/classes

end
