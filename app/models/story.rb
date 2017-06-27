class Story < ApplicationRecord
  # modules/constants
  extend ClassOptionsAttribute

  class_constant(:locations, %w[ location label host ]) do |new_const|
    new_const.add(location: "fanfiction",         label: "FanFiction",         host: "https://www.fanfiction.net")
    new_const.add(location: "spacebattles",       label: "SpaceBattles",       host: "https://forums.spacebattles.com")
    new_const.add(location: "sufficientvelocity", label: "SufficientVelocity", host: "https://forums.sufficientvelocity.com")
  end

  # associations/scopes/validations/callbacks/macros
  has_many :chapters, dependent: :destroy, class_name: "StoryChapter"

  generate_column_scopes
  scope :seek_word_count_gteq, -> (word_count) { where_word_count(gteq: word_count.to_s.human_size_to_i) }

  validates_presence_of_required_columns
  validates_in_list(:location, const.locations.map(&:location))

  # transient story_active_at used in searchers
  attr_accessor :story_active_at

  before_save do
    # make sure story_updated_at same latest latest chapter update
    latest_chapter = chapters.order_chapter_updated_at(:desc).first
    if latest_chapter && story_updated_at < latest_chapter.chapter_updated_at
      self.story_updated_at = latest_chapter.chapter_updated_at
    end
  end

  # public/private/protected/classes
  def title=(new_title)
    self[:title] = new_title.to_s.strip.presence
  end

  def description=(new_description)
    self[:description] = new_description.to_s.strip.presence
  end

  def crossover=(new_crossover)
    self[:crossover] = new_crossover.to_s.strip.presence
  end

  def word_count=(new_word_count)
    self[:word_count] = new_word_count.to_s.human_size_to_i
  end

  def recently_created?
    story_created_on >= 1.week.ago
  end

  def location_label
    const.locations.fetch(location).label
  end

  def location_host
    const.locations.fetch(location).host
  end

  def location_url
    "#{location_host}#{location_path}"
  end

  def read_url
    chapters.size == 0 ? location_url : "#{location_url}/threadmarks"
  end

  def is_unlocked?
    !is_locked?
  end

end
