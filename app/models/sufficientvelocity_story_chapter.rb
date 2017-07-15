class SufficientvelocityStoryChapter < ApplicationRecord

  # modules/constants
  include LocationStoryChapterConcern

  # associations/scopes/validations/callbacks/macros
  belongs_to :story, class_name: "SufficientvelocityStory"

  generate_column_scopes

  validates_presence_of_required_columns

  # public/private/protected/classes
  def read_url
    "#{SufficientvelocityStory.const.location_host}#{location_path}"
  end

end
