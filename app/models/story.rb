class Story < ApplicationRecord
  # modules/constants

  LOCATIONS = {
    spacebattles:       "SpaceBattles",
    sufficientvelocity: "SufficientVelocity",
  }.with_indifferent_access

  # associations/scopes/validations/callbacks/macros
  has_many :chapters, class_name: "StoryChapter"

  generate_column_scopes

  validates_presence_of_required_columns
  validates_in_list :location, LOCATIONS.keys

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

  def word_count=(unformatted_word_count)
    unformatted_word_count = unformatted_word_count.to_s
    self[:word_count] =
      case unformatted_word_count
      # 123, 123.5
      when /\A\d+(\.\d+)?\z/   then unformatted_word_count
      # 1.1K, 1.25k
      when /\A\d+(\.\d+)?k\z/i then unformatted_word_count.remove(/[^\d.]/).to_f * 1_000
      # 1.1M, 1.25m
      when /\A\d+(\.\d+)?m\z/i then unformatted_word_count.remove(/[^\d.]/).to_f * 1_000_000
      else 0
      end.to_i
  end

  def recently_created?
    story_created_on >= 1.week.ago
  end

  def location_label
    LOCATIONS[location]
  end

  def location_host
    case location.verify_in!(LOCATIONS)
    when "spacebattles"       then "https://forums.#{location}.com"
    when "sufficientvelocity" then "https://forums.#{location}.com"
    end
  end

  def location_url
    "#{location_host}#{location_path}"
  end

  def threadmarks_url
    chapters.size == 0 ? location_url : "#{location_url}/threadmarks"
  end

  def is_unlocked?
    !is_locked?
  end

end
