module LocationStoryConcern
  extend ActiveSupport::Concern

  included do
    # load settings
    class_constant(:location_slug, table_name.remove("_stories"))
    Rails.application.settings.locations[const.location_slug].to_h.each do |key, value|
      class_constant("location_#{key}", value)
    end

    # modules/constants
    class_constant_builder(:categories, %w[ category label ]) do |new_const|
      new_const.add(category: "story", label: "Story")
      new_const.add(category: "quest", label: "Quest")
    end

    # associations/scopes/validations/callbacks/macros
    belongs_to :story, inverse_of: name.underscore.pluralize.to_sym
    has_one :author, primary_key: :author_name, foreign_key: "#{const.location_slug}_name", class_name: "StoryAuthor"
    has_many :chapters, dependent: :destroy, foreign_key: :story_id, class_name: "#{name}Chapter", inverse_of: :story

    generate_column_scopes
    scope :seek_word_count_gteq, -> (word_count) { where_word_count(gteq: word_count.to_s.human_size_to_i) }

    validates_presence_of_required_columns
    validates_in_list(:category, const.categories.map(&:category))
    validates :location_id, uniqueness: true
    validate do
      # time zone differences on AOE can cause the updated time to be on the day before the created at date
      if story_created_on? && story_updated_at? && (story_created_on - 1.day) > story_updated_at.to_date
        errors.add(:story_updated_at, "[#{story_updated_at}] must come after story creation date [#{story_created_on}]")
      end
    end

    before_validation do
      self.read_url = read_url! if !read_url?
    end

    after_save do
      # cache latest updates to story for easy queries
      if saved_changes? && story
        story.sync_with_active_location!
      end
      # resync story with active location
      if saved_change_to_story_id?
        Story.seek(id_in: saved_change_to_story_id.compact).each(&:sync_with_active_location!)
      end
      # ensure author record exists
      if saved_change_to_author_name?
        author!
      end
      # update story rating
      if send("saved_change_to_#{const.location_rating_column}?")
        Story.preload_locations.find(story_id).update_rating!
      end
    end

    after_destroy do
      # resync story with active location
      if story_id
        Story.where(id: story_id).each(&:sync_with_active_location!)
      end
    end

    # transient story_active_at used in searchers
    attr_accessor :story_active_at

    # override accessors to cleanup values
    (%w[ title crossover description author_name ] & column_names).each do |column|
      define_method("#{column}=") do |value|
        self[column] = value.to_s.normalize.presence
      end
    end
  end

  # public/private/protected/classes
  def word_count=(new_word_count)
    self[:word_count] = new_word_count.to_s.human_size_to_i
  end

  def recently_created?
    story_created_on >= 10.days.ago
  end

  def location_url
    "#{const.location_host}#{location_path}"
  end

  def category_label
    const.categories.fetch(category).label
  end

  def story_updated_at!
    latest_chapter = chapters.order_chapter_updated_at(:desc).first
    if latest_chapter && story_updated_at < latest_chapter.chapter_updated_at
      latest_chapter.chapter_updated_at
    else
      story_updated_at || story_created_on
    end
  end

  def author!
    return nil if !author_name?
    return author if reload_author
    # already an author on an alternate location
    alternate_location_authors = StoryAuthor.seek(location_name_eq: author_name).order_id.reject do |alternate_location_author|
      # remove alternate locations with a different location name (prevent overwrite)
      alternate_location_author.send("#{const.location_slug}_name?") &&
      alternate_location_author.send("#{const.location_slug}_name") != author_name
    end
    if alternate_location_authors.present?
      alternate_location_author = alternate_location_authors.first
      alternate_location_author.update!("#{const.location_slug}_name" => author_name)
      alternate_location_author
    else
      StoryAuthor.create!("#{const.location_slug}_name" => author_name)
    end
    reload_author
  end

  def story!(return_associated_story: true, find_existing_story: true, create_new_story: true)
    # already set
    return story if story && return_associated_story
    # find existing story
    if find_existing_story
      author_stories = Story.seek(
        "author.#{const.location_slug}_name_eq" => author_name,
        "category_eq" => category
      )
      [title, parse_title].each do |search_title|
        same_title_stories     = author_stories.seek(title_ieq: search_title)
        matching_title_stories = author_stories.seek(title_matches: search_title)
        if same_title_stories.exists?
          return same_title_stories.first
        elsif matching_title_stories.exists?
          return matching_title_stories.first
        end
      end
    end
    # build story
    new_story = Story.new(attributes.slice(*Story.column_names).except(*%w[ id created_at updated_at ]))
    new_story.crossover = crossover_for_story
    new_story.author = author!
    new_story.title = parse_title
    new_story.save! if create_new_story && new_story.title?
    new_story
  end

  # "Well Traveled [Worm](Planeswalker Taylor)" => "Well Traveled"
  def parse_title(local_title = title)
    local_title.to_s
      .gsub("’", "'")
      .gsub(/—|~|–|-+/, "-")
      .gsub(/\|/, "/")
      .gsub(/;/, ":") # two different types of semicolons
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

  def universal_parse_crossover_from_title(local_title = title)
    [
      /\(Worm ?(X|\/) ?(?<value>.*?)\)/,
      /\[Worm ?(X|\/) ?(?<value>.*?)\]/,
      /\{Worm ?(X|\/) ?(?<value>.*?)\}/,
      /\((?<value>.*?)\)/,
      /\[(?<value>.*?)\]/,
      /\{(?<value>.*?)\}/
    ].each do |regex|
      scan = local_title.scan(regex).flatten
      local_title.scan(regex).flatten.each do |raw_crossover|
        if raw_crossover
          crossover = raw_crossover.split(/[^-A-Za-z0-9]/).select do |word|
            word !~ /worm|canon/i &&
            word !~ /\AAlt|AU/ &&
            !word.downcase.in?(%w[ fic power fusion fanfic cross taylor pre post prepost quest a s x cross crossover ])
          end.select(&:present?).join(" ").normalize
          return crossover if crossover.present?
        end
      end
    end
    nil
  end

  def highly_rated?
    rating > Story.const.highly_rated_threshold
  end

  def rating
    (send(const.location_rating_column) * const.location_rating_multiplier).round(2)
  end

  def <=>(other)
    sorter = -> (record) do
      [-record.story_updated_at.to_i, -record.story_created_on.to_i, -record.id]
    end
    sorter.call(self) <=> sorter.call(other)
  end
end
