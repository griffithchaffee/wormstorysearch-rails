module LocationStoryConcern
  extend ActiveSupport::Concern

  included do
    # modules/constants
    class_constant(:categories, Story.const.categories)

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
      # cache latest update to story for easy queries
      if story && story.is_unlocked?
        if saved_changes?
          story.sync_with_locations!
        end
      end
      if saved_change_to_attribute(:story_id)
        Story.archive_management!
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

  def story!
    # already set
    return story if is_locked? || story
    # "Well Traveled [Worm](Planeswalker Taylor)" => "Well Traveled"
    parsed_title = title.remove(/\(.*?\)/).remove(/\[.*?\]/).normalize
    query = Story.where(category: category)
    # find existing story by title
    [title, parsed_title].each do |search_title|
      search = query.where(title: search_title)
      return search.first if search.count == 1
      search = query.seek(title_matches: search_title)
      return search.first if search.count == 1
    end
    # create story by title
    Story.create!(attributes.slice(*Story.column_names).except(*%w[ id created_at updated_at ]))
  end

  def parse_crossover_from_title(local_title = title)
    [/\(Worm ?(X|\/) ?(?<value>.*?)\)/, /\[Worm ?(X|\/) ?(?<value>.*?)\]/, /\((?<value>.*?)\)/, /\[(?<value>.*?)\]/].each do |regex|
      scan = local_title.scan(regex).flatten
      local_title.scan(regex).flatten.each do |raw_crossover|
        if raw_crossover
          crossover = raw_crossover.split(/[^-A-Za-z0-9]/).select do |word|
            word !~ /worm|canon/i &&
            word !~ /\AAlt|AU/ &&
            !word.downcase.in?(%w[ fic power fusion fanfic cross taylor pre post prepost quest a x cross crossover ])
          end.select(&:present?).join(" ").normalize
          return crossover if crossover.present?
        end
      end
    end
    nil
  end
end
