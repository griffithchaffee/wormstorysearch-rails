class Story < ApplicationRecord
  # modules/constants
  class_constant_builder(:categories, %w[ category label ]) do |new_const|
    new_const.add(category: "story", label: "Story")
    new_const.add(category: "quest", label: "Quest")
  end

  # associations/scopes/validations/callbacks/macros
  has_many :spacebattles_stories
  has_many :sufficientvelocity_stories
  has_many :fanfiction_stories

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

  def category_label
    const.categories.fetch(category).label
  end

  def is_unlocked?
    !is_locked?
  end

  def read_url
    active_location.read_url
  end

  def active_location
    @active_location ||= locations_sorted_by_updated_at.first
  end

  def locations
    [spacebattles_stories, sufficientvelocity_stories, fanfiction_stories].flatten
  end

  def locations_sorted_by_updated_at
    locations.sort_by do |location, i|
      [location.story_updated_at.to_date, locations.reverse.index(location)]
    end.reverse
  end

  def sync_with_locations!
    self.word_count = active_location.word_count
    self.story_updated_at = active_location.story_updated_at
    save! if has_changes_to_save?
    self
  end

  class << self
    # remove stories without any locations
    def archive_management!
      should_be_archived = unscoped
        .seek(id_not_in: SpacebattlesStory.select_story_id)
        .seek(id_not_in: SufficientvelocityStory.select_story_id)
        .seek(id_not_in: FanfictionStory.select_story_id)
      should_not_be_archived = unscoped.seek(id_not_in: should_be_archived.select_id)
      # perform archiving
      should_be_archived.where(is_archived: false).update_all(is_archived: true) +
      should_not_be_archived.where(is_archived: true).update_all(is_archived: false)
    end
  end

end
