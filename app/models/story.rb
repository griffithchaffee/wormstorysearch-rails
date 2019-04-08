class Story < ApplicationRecord
  # modules/constants
  class_constant(:dead_status_duration, 8.months)
  class_constant(:categories, SpacebattlesStory.const.categories)
  Rails.application.settings.stories.to_h.each do |const_slug, value|
    class_constant(const_slug, value)
  end
  Rails.application.settings.locations.each do |location|
    location.model = "#{location.slug.capitalize}Story".constantize
  end
  class_constant(:location_models, Rails.application.settings.locations.map(&:model))

  class_constant_builder(:statuses, %w[ status label ]) do |new_const|
    new_const.add(status: "complete", label: "Complete")
    new_const.add(status: "ongoing",  label: "Ongoing")
    new_const.add(status: "dead",     label: "Dead")
  end

  # associations/scopes/validations/callbacks/macros
  belongs_to :author, class_name: "StoryAuthor"
  const.location_models.each do |location_model|
    has_many "#{location_model.const.location_slug}_stories".to_sym, inverse_of: :story
  end

  generate_column_scopes
  scope :search_story_keywords, -> (keywords) do
    queries = []
    searcher = -> (value) do
      next if value.blank?
      # special starts with search
      if value.starts_with?("^") || value.ends_with?("$")
        queries << unscoped.seek(title_matches: value)
      else
        queries << unscoped.seek_or(
          title_matches: value,
          crossover_matches: value,
          description_matches: value,
          "author.any_name_matches" => value,
        )
      end
    end
    keywords.to_s.split("|").each do |words|
      words.strip!
      if words.starts_with?("~")
        words.tokenize(/[A-Za-z0-9$^]/).each(&searcher)
      else
        searcher.call(words.remove(/"/))
      end
    end
    all.seek_or { queries }
  end
  scope :seek_word_count_filter, -> (word_count_filters) do
    query = all
    word_count_filters.split(/\s|,/).map do |word_count_filter|
      if "-".in?(word_count_filter)
        gteq, lteq = word_count_filter.split("-", 2)
        gteq = ">#{gteq}"
        lteq = "<#{lteq}"
        [gteq, lteq]
      else
        word_count_filter
      end
    end.flatten.select(&:present?).each do |word_count_filter|
      filter = word_count_filter.starts_with?("<") ? :lteq : :gteq
      word_count = word_count_filter.remove(/[^0-9km]/).human_size_to_i
      query = query.where_word_count(filter => word_count) if word_count > 0 && word_count < 100_000_000
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
  scope :seek_updated_after_filter, -> (updated_after) do
    updated_after_date = Date.smart_parse(updated_after)
    if updated_after_date
      where_story_updated_at(gteq: DateTime.smart_parse("#{updated_after_date} 23:59:59"))
    else
      all
    end
  end
  scope :seek_updated_before_filter, -> (updated_before) do
    updated_before_date = Date.smart_parse(updated_before)
    if updated_before_date
      where_story_updated_at(lteq: DateTime.smart_parse("#{updated_before_date} 00:00:00"))
    else
      all
    end
  end
  scope :seek_is_nsfw_eq, -> (value) do
    case value
    when "any" then all
    when *%w[ true false ] then where(is_nsfw: value)
    else all
    end
  end
  scope :seek_is_archived_eq, -> (value) do
    case value
    when "any" then all
    when *%w[ true false ] then where(is_archived: value)
    else all
    end
  end
  scope :seek_location_slug_in, -> (location_slugs) do
    query = all
    const.location_models.each do |location_model|
      if location_model.const.location_slug.in?(location_slugs)
        query = query.where(id: location_model.select_story_id)
      end
    end
    query
  end

  validates_presence_of_required_columns
  validates_in_list(:category, const.categories.map(&:category))
  validates_in_list(:status, const.statuses.map(&:status))

  before_update do
    # remove dead status if updated
    if status == "dead" && will_save_change_to_attribute?(:story_updated_at) && story_updated_at > const.dead_status_duration.ago
      self.status = "ongoing"
    end
  end

  # override accessors to cleanup values
  (%w[ title crossover description ]).each do |column|
    define_method("#{column}=") do |value|
      self[column] = value.to_s.normalize.presence
    end
  end

  # public/private/protected/classes
  def crossover_title
    crossover? ? "#{title} [#{crossover}]" : title
  end

  def word_count=(new_word_count)
    self[:word_count] = new_word_count.to_s.human_size_to_i
  end

  def author_name
    author.try(:name) || "Unavailable"
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
      self.word_count = locations.map(&:word_count).max
      self.story_updated_at = active_location.story_updated_at
      self.is_archived = false
    else
      self.is_archived = true
    end
    update_rating!
  end

  def reset_to_active_location!
    if active_location
      self.title       = active_location.title
      self.author      = active_location.author
      self.description = locations.find { |location| location.const.location_slug == "fanfiction" }.try(:description)
      self.crossover   = active_location.parse_crossover_from_title
    end
    sync_with_active_location!
  end

  def update_rating!(update_locations: false)
    new_rating = locations.map do |location|
      location.update_rating! if update_locations
      location.rating
    end.max || 0
    self.rating = new_rating.round(2)
    save! if has_changes_to_save?
    self
  end

  def duplicate_stories
    Story.seek(title_ieq: title, author_id_eq: author_id, id_not_eq: id).order(:story_created_on)
  end

  def merge_with_story!(duplicate_story)
    primary_story = self
    duplicate_story.locations.each do |location_story|
      location_story.update!(story: primary_story)
    end
    if duplicate_story.author && primary_story.author && duplicate_story.author != primary_story.author
      primary_story.author.merge_with_author!(duplicate_story.author)
    end
    duplicate_story.destroy!
  end

  def <=>(other)
    sorter = -> (record) do
      [record.title, record.id]
    end
    sorter.call(self) <=> sorter.call(other)
  end

  class << self
    # archive stories without any locations
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

    # mark old stories dead
    def update_statuses!
      seek(
        status_eq: "ongoing",
        story_updated_at_lteq: const.dead_status_duration.ago,
      ).update_all(status: "dead")
    end

    def location_rating_multipliers
      const.location_models.map do |location_model|
        location_slug = location_model.const.location_slug
        rating_column = location_model.const.location_rating_column
        ratings = location_model.seek("#{rating_column}_not_eq" => 0).pluck(rating_column).sort
        trim_size = (ratings.size * const.rating_trim_percent).floor
        trimmed_ratings = ratings[trim_size..(ratings.size - trim_size)]
        mean         = ratings.inject { |sum, rating| sum + rating }.to_f / ratings.size
        trimmed_mean = trimmed_ratings.inject { |sum, rating| sum + rating }.to_f / trimmed_ratings.size
        rating_multiplier = (const.average_story_rating.to_f / trimmed_mean).round(2)
        puts "#{location_slug}: #{rating_multiplier}"
        {
          location: location_slug,
          multiplier: rating_multiplier,
          count: ratings.size,
          min: ratings.first,
          max: ratings.last,
          mean: mean.round(2),
          trimmed_count: trimmed_ratings.size,
          trimmed_min: trimmed_ratings.first,
          trimmed_max: trimmed_ratings.last,
          trimmed_mean: trimmed_mean.round(2),
        }
      end
    end

    def preload_locations
      preload(const.location_models.map(&:table_name))
    end

    def preload_locations_with_authors
      preload(const.location_models.map { |location_model| { location_model.table_name => :author } })
    end

    def preload_locations_with_chapters
      preload(const.location_models.map(&:table_name).map { |location| [location, :chapters] }.to_h)
    end

    # candidates for merging
    def where_has_duplicates
      unscoped
        .select("story1.*")
        .from("stories story1, stories story2")
        .where("LOWER(story1.title) = LOWER(story2.title)")
        .where("story1.author_id = story2.author_id")
        .where("story1.id != story2.id")
    end
  end

end
