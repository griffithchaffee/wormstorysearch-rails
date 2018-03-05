class StoryAuthor < ApplicationRecord
  # modules/constants

  # associations/scopes/validations/callbacks/macros
  has_many :stories, foreign_key: :author_id, class_name: "Story", inverse_of: :author, dependent: :nullify
  Story.const.location_models.each do |location_model|
    has_many "#{location_model.const.location_slug}_stories".to_sym, primary_key: "#{location_model.const.location_slug}_name", foreign_key: "author_name", inverse_of: :author
  end

  generate_column_scopes
  scope :where_for_location_story, -> (location_story) do
    where("#{location_story.const.location_slug}_name" => location_story.author_name)
  end
  scope :seek_any_name_matches, -> (name) do
    break none if name.blank?
    seek_or(
      name_matches:                    name,
      spacebattles_name_matches:       name,
      sufficientvelocity_name_matches: name,
      fanfiction_name_matches:         name,
    )
  end
  scope :seek_location_name_eq, -> (name) do
    break none if name.blank?
    seek_or(
      spacebattles_name_eq:       name,
      sufficientvelocity_name_eq: name,
      fanfiction_name_eq:         name,
    )
  end

  validates_presence_of_required_columns
  Story.const.location_models.each do |location_model|
    validates(
      "#{location_model.const.location_slug}_name",
      uniqueness: {
        if: "#{location_model.const.location_slug}_name?".to_sym,
        message: -> (story_author, params) { "#{params[:value].inspect} has already been taken" }
      }
    )
  end

  before_validation do
    if !name?
      self.name = location_names.join(" / ").presence
    end
  end

  after_update do
    # update location stories to author if name changed
    Story.const.location_models.each do |location_model|
      if send("saved_change_to_#{location_model.const.location_slug}_name?")
        location_model.preload(story: :author).where(author_name: send("#{location_model.const.location_slug}_name")).each do |location_story|
          story = location_story.story
          if story
            story.author = self
            story.save! if story.has_changes_to_save?
          end
        end
      end
    end
  end

  # public/private/protected/classes
  def location_names
    Story.const.location_models.map do |location_model|
      send("#{location_model.const.location_slug}_name")
    end.select(&:present?).uniq
  end

  def merge_with_author!(duplicate_author)
    primary_author = self
    location_stories = []
    Story.const.location_models.map do |location_model|
      if !primary_author.send("#{location_model.const.location_slug}_name?")
        primary_author.send(
          "#{location_model.const.location_slug}_name=",
          duplicate_author.send("#{location_model.const.location_slug}_name")
        )
        duplicate_author.send("#{location_model.const.location_slug}_name=", nil)
        location_stories += location_model.where(author_name: primary_author.send("#{location_model.const.location_slug}_name"))
      end
    end
    # save name changes
    duplicate_author.save! if duplicate_author.has_changes_to_save?
    primary_author.save! if primary_author.has_changes_to_save?
    # update stories
    location_stories.each do |location_story|
      story = location_story.story
      if story
        story.update!(author: primary_author)
      end
    end
    # destroy duplicate author if no names
    if Story.const.location_models.none? { |location_model| duplicate_author.send("#{location_model.const.location_slug}_name?") }
      duplicate_author.destroy!
    end
  end

end
