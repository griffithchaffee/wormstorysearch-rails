class Story < ApplicationRecord
  # modules/constants

  LOCATIONS = %w[ spacebattles ]

  # associations/scopes/validations/callbacks/macros
  has_many :chapters, class_name: "StoryChapter"

  generate_column_scopes

  validates_presence_of_required_columns
  validates_in_list :location, LOCATIONS

  # transient story_active_at used in searchers
  attr_accessor :story_active_at

  # public/private/protected/classes

  def title=(new_title)
    self[:title] = new_title.to_s.strip.presence
  end

  def location_host
    case location.verify_in!(%w[ spacebattles ])
    when "spacebattles" then "https://forums.spacebattles.com"
    end
  end

  def location_url
    "#{location_host}#{location_path}"
  end

  def threadmarks_url
    "#{location_url}/threadmarks"
  end

end
