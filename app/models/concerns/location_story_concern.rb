module LocationStoryConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :story
    has_many :chapters, dependent: :destroy, foreign_key: :story_id, class_name: "#{name}Chapter"

    generate_column_scopes
    scope :seek_word_count_gteq, -> (word_count) { where_word_count(gteq: word_count.to_s.human_size_to_i) }

    validates_presence_of_required_columns
    validates :location_id, uniqueness: true
    validate do
      if story_created_on? && story_updated_at? && story_created_on > story_updated_at
        errors.add(:story_updated_at, "[#{story_updated_at}] must come after story creation date [#{story_created_on}]")
      end
    end

    before_validation do
      self.read_url = read_url! if !read_url?
    end

    # transient story_active_at used in searchers
    attr_accessor :story_active_at
  end

  def title=(new_title)
    self[:title] = new_title.to_s.strip.presence
  end

  def word_count=(new_word_count)
    self[:word_count] = new_word_count.to_s.human_size_to_i
  end

  def recently_created?
    story_created_on >= 1.week.ago
  end

  def location_url
    "#{const.location_host}#{location_path}"
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
end
