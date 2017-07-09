module LocationStoryConcern
  extend ActiveSupport::Concern

  included do
    # modules/constants
    class_constant_builder(:categories, %w[ category label ]) do |new_const|
      new_const.add(category: "story", label: "Story")
      new_const.add(category: "quest", label: "Quest")
    end

    # associations/scopes/validations/callbacks/macros
    belongs_to :story
    has_many :chapters, dependent: :destroy, foreign_key: :story_id, class_name: "#{name}Chapter"

    generate_column_scopes
    scope :seek_word_count_gteq, -> (word_count) { where_word_count(gteq: word_count.to_s.human_size_to_i) }

    validates_presence_of_required_columns
    validates_in_list(:category, const.categories.map(&:category))
    validates :location_id, uniqueness: true
    validate do
      if story_created_on? && story_updated_at? && story_created_on > story_updated_at
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
      if saved_change_to_attribute(:story_id)
        Story.seek(id_in: saved_change_to_story_id.compact).each(&:sync_with_active_location!)
      end
    end

    after_destroy do
      if story_id
        Story.where(id: story_id).each(&:sync_with_active_location!)
      end
    end

    # transient story_active_at used in searchers
    attr_accessor :story_active_at

    (%w[ title crossover description ] & column_names).each do |column|
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
    story_created_on >= 1.week.ago
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

  def is_unlocked?
    !is_locked?
  end

  def story!(options = {})
    options = options.with_indifferent_access.assert_valid_keys(*%w[ search create ])
    # already set
    return story if is_locked? || story
    # "Well Traveled [Worm](Planeswalker Taylor)" => "Well Traveled"
    parsed_title = Story.new(title: title).title
    normalize_author = -> (name) { name.downcase.remove(/[^a-z0-9]/) }
    # find existing story
    if options[:search] != false
      query = Story.where(category: category)
      [title, parsed_title].each do |search_title|
        search = query.seek(title_ieq: search_title)
        return search.first if search.count == 1
        search = query.seek(title_matches: search_title).select { |result| normalize_author.call(result.author) == normalize_author.call(author) }
        return search.first if search.count == 1
      end
    end
    # create story by title
    new_story = Story.new(attributes.slice(*Story.column_names).except(*%w[ id created_at updated_at ]))
    if !"crossover".in?(self.class.column_names)
      new_story.crossover = parse_crossover_from_title
    end
    new_story.save! if options[:create] != false
    new_story
  end

  def parse_crossover_from_title(local_title = title)
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

  def <=>(other)
    sorter = -> (record) do
      [record.story_updated_at, record.story_created_on, -record.id]
    end
    sorter.call(self) <=> sorter.call(other)
  end
end
