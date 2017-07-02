class Story < ApplicationRecord
  # modules/constants
  class_constant_builder(:categories, %w[ category label ]) do |new_const|
    new_const.add(category: "story", label: "Story")
    new_const.add(category: "quest", label: "Quest")
  end

  # associations/scopes/validations/callbacks/macros
  has_one :spacebattles_story
  has_one :sufficientvelocity_story

  generate_column_scopes

  scope :seek_word_count_gteq, -> (word_count) { where_word_count(gteq: word_count.to_s.human_size_to_i) }
  scope :search_story_matches, -> (value) { seek_or(title_matches: value, author_matches: value, crossover_matches: value) }

  validates_presence_of_required_columns
  validates_in_list(:category, const.categories.map(&:category))

  # public/private/protected/classes
  def title=(new_title)
    self[:title] = new_title.to_s.normalize.presence
  end

  def description=(new_description)
    self[:description] = new_description.to_s.normalize.presence
  end

  def crossover=(new_crossover)
    self[:crossover] = new_crossover.to_s.normalize.presence
  end

  def word_count=(new_word_count)
    self[:word_count] = new_word_count.to_s.human_size_to_i
  end

  def recently_created?
    story_created_on >= 1.week.ago
  end

  def is_unlocked?
    !is_locked?
  end

  def read_url
    active_location.read_url
  end

  def active_location
    locations_sorted_by_updated_at.first
  end

  def locations
    [spacebattles_story, sufficientvelocity_story].compact
  end

  def locations_sorted_by_updated_at
    locations.sort_by do |location, i|
      [location.story_updated_at.beginning_of_hour, locations.reverse.index(location)]
    end.reverse
  end

end
