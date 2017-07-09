class Story < ApplicationRecord
  # modules/constants
  class_constant(:dead_status_duration, 1.year)
  class_constant(:categories, SpacebattlesStory.const.categories)
  class_constant(:location_models, [SpacebattlesStory, SufficientvelocityStory, FanfictionStory])

  class_constant_builder(:statuses, %w[ status label ]) do |new_const|
    new_const.add(status: "ongoing",  label: "Ongoing")
    new_const.add(status: "dead",     label: "Dead")
    new_const.add(status: "complete", label: "Complete")
  end

  # associations/scopes/validations/callbacks/macros
  const.location_models.each do |location_model|
    has_many "#{location_model.const.location_slug}_stories".to_sym
  end

  generate_column_scopes

  scope :seek_word_count_gteq, -> (word_count) { where_word_count(gteq: word_count.to_s.human_size_to_i) }
  scope :search_story_keywords, -> (words) do
    query = all
    words.to_s.tokenize(/[A-Za-z0-9^$]/).each do |word|
      # special starts with search
      if word.starts_with?("^") || word.ends_with?("$")
        query = query.seek_or(title_matches: word)
      else
        query = query.seek_or(
          title_matches: word,
          author_matches: word,
          crossover_matches: word,
          description_matches: word,
        )
      end
    end
    query
  end

  validates_presence_of_required_columns
  validates_in_list(:category, const.categories.map(&:category))
  validates_in_list(:status, const.statuses.map(&:status))

  before_update do
    # remove dead status if updated
    if is_unlocked? && status == "dead" && will_save_change_to_attribute?(:story_updated_at) && story_updated_at > const.dead_status_duration.ago
      self.status = "ongoing"
    end
  end

  # public/private/protected/classes
  def crossover_title
    crossover? ? "#{title} [#{crossover}]" : title
  end

  def title=(new_title)
    self[:title] = new_title.to_s
      .gsub("’", "'")
      .gsub(/—|~|–|-+/, "-")
      .gsub(/\|/, "/")
      .gsub(/;/, ":")
      .gsub(/;/, ":")
      .remove(/[^-A-Za-z0-9 .':{}()\[\]?,!&*+_\/]/) # non ascii
      .remove(/\(.*?\)/).remove(/\[.*?\]/).remove(/\{.*?\}/) # crossover
      .remove(/[(){}"\[\]]/)  # stray parenthesis and brackets
      .gsub(/ *:+ */, ": ")   # normalize colons
      .gsub(/ +,+ */, ", ")   # normalize commas
      .gsub(/ +\.+ */, ". ")  # normalize periods
      .gsub(/(-+ +)+/, " - ") # normalize dashes
      .gsub(/([^A-Z.])\.{1}\z/, "\\1") # trailing periods except for ... and Y.Z.
      .normalize.remove(/\A[^A-Za-z0-9]+|[^A-Za-z0-9.!'?]+\z/) # remove weird starting/ending characters
      .normalize.presence # cleanup
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
    active_location.read_url if active_location
  end

  def active_location
    locations_sorted_by_updated_at.first
  end

  def locations
    const.location_models.map do |location_model|
      send("#{location_model.const.location_slug}_stories").sort
    end.flatten
  end

  def locations_sorted_by_updated_at
    locations.sort_by do |location, i|
      [location.story_updated_at.to_date, locations.reverse.index(location)]
    end.reverse
  end

  def sync_with_active_location!
    if active_location
      self.word_count = active_location.word_count
      self.story_updated_at = active_location.story_updated_at
      self.is_archived = false
    else
      self.is_archived = true
    end
    save! if has_changes_to_save?
    self
  end

  class << self
    # remove stories without any locations
    def reset_archived_state!
      should_be_archived = all
      const.location_models.each do |location_model|
        should_be_archived = should_be_archived.seek(id_not_in: location_model.select_story_id)
      end
      should_not_be_archived = all.seek(id_not_in: should_be_archived.select_id)
      # perform archiving
      should_be_archived.where(is_archived: false).update_all(is_archived: true) +
      should_not_be_archived.where(is_archived: true).update_all(is_archived: false)
    end

    def update_statuses!
      seek(
        status_eq: "ongoing",
        is_locked_eq: false,
        story_updated_at_lteq: const.dead_status_duration.ago,
      ).update_all(status: "dead")
    end
  end

end
