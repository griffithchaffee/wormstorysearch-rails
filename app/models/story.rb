class Story < ApplicationRecord
  # modules/constants
  class_constant(:dead_status_duration, 1.year)
  class_constant(:categories, SpacebattlesStory.const.categories)
  class_constant(:location_models, [SpacebattlesStory, SufficientvelocityStory, FanfictionStory])
  class_constant(:rating_trim_percent, 0.1)
  class_constant(:rating_deviations, 3)

  class_constant_builder(:statuses, %w[ status label ]) do |new_const|
    new_const.add(status: "complete", label: "Complete")
    new_const.add(status: "ongoing",  label: "Ongoing")
    new_const.add(status: "dead",     label: "Dead")
  end

  # associations/scopes/validations/callbacks/macros
  const.location_models.each do |location_model|
    has_many "#{location_model.const.location_slug}_stories".to_sym
  end

  generate_column_scopes

  scope :search_story_keywords, -> (keywords) do
    queries = []
    keywords.to_s.split("|").each do |words|
      words.to_s.tokenize(/[A-Za-z0-9^$]/).each do |word|
        # special starts with search
        if word.starts_with?("^") || word.ends_with?("$")
          queries << unscoped.seek_or(title_matches: word)
        else
          queries << unscoped.seek_or(
            title_matches: word,
            author_matches: word,
            crossover_matches: word,
            description_matches: word,
          )
        end
      end
    end
    all.seek_or { queries }
  end
  scope :seek_word_count_filter, -> (word_count_filters) do
    query = all
    word_count_filters.split(/\s|,/).each do |word_count_filter|
      filter = word_count_filter.starts_with?("<") ? :lteq : :gteq
      word_count = word_count_filter.remove(/[^0-9km]/).human_size_to_i
      query = query.where_word_count(filter => word_count) if word_count > 0
    end
    query
  end
  scope :seek_rating_filter, -> (rating_filters) do
    query = all
    rating_filters.split(/\s|,/).each do |rating_filter|
      filter = rating_filter.starts_with?("<") ? :lteq : :gteq
      rating = rating_filter.remove(/[^0-9.]/).to_f
      query = query.where_rating(filter => rating) if rating > 0
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

  def highly_rated?
    locations.any?(&:highly_rated?)
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
=begin
  def update_rating!(update_locations: false)
    new_rating = locations.map do |location|
      location.update_rating! if update_locations
      location.rating
    end.max || 0
    self.rating = new_rating.round(2)
    save! if has_changes_to_save?
    self
  end
=end
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

    def rating_averages(trim_percent: const.rating_trim_percent, deviations: const.rating_deviations)
      # caluclation is trimmed mean:
      # - remove highest/lowest trim_percent - https://www.easycalculation.com/statistics/learn-trimmed-mean.php
      # - calculate standard deviation average of remaining
      const.location_models.map do |location|
        location_slug = location.const.location_slug
        rating_column = location.const.location_rating_column
        model = const.location_models.find { |location_model| location_model.const.location_slug == location_slug.to_s }
        # trimmed mean
        query = model.unscoped.seek("#{rating_column}_not_eq" => 0).order(rating_column)
        ratings = query.pluck(rating_column)
        trim_size = trim_percent * ratings.size
        trimmed_ratings = ratings[trim_size..-trim_size]
        min_rating, max_rating = trimmed_ratings.minmax
        # build trim floor/ceiling
        query = model.unscoped.seek("#{rating_column}_gteq" => min_rating, "#{rating_column}_lteq" => max_rating).reorder(nil)
        standard_deviation = query.select("STDDEV_SAMP(#{rating_column}) AS standard_deviation").first.attributes.fetch("standard_deviation").to_f
        average            = query.select("AVG(#{rating_column}) AS average").first.attributes.fetch("average").to_f
        floor   = average - (standard_deviation / deviations)
        ceiling = average + (standard_deviation * deviations)
        # trimmed average
        trimmed_query = model.unscoped.seek("#{rating_column}_gteq" => floor, "#{rating_column}_lteq" => ceiling).reorder(nil)
        trimmed_average = trimmed_query.select("AVG(#{rating_column}) AS average").first.attributes.fetch("average").to_f
        [location_slug, trimmed_average.round(4)]
      end.to_h.with_indifferent_access
    end

    def preload_locations
      preload(const.location_models.map(&:table_name))
    end

    def preload_locations_with_chapters
      preload(const.location_models.map(&:table_name).map { |location| [location, :chapters] }.to_h)
    end
  end

end
