class StoryAuthor < ApplicationRecord
  # modules/constants

  # associations/scopes/validations/callbacks/macros
  has_many :stories, foreign_key: :author_id, class_name: "Story", inverse_of: :author
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
    # auto update name to combined location names
    old_location_names = Story.const.location_models.map do |location_model|
      if send("will_save_change_to_#{location_model.const.location_slug}_name?")
        send("#{location_model.const.location_slug}_name_was")
      else
        send("#{location_model.const.location_slug}_name")
      end
    end.compact
    if name == old_location_names.join(" / ").presence
      self.name = location_names.join(" / ").presence if location_names.present?
    end
  end

  # public/private/protected/classes
  def location_names
    Story.const.location_models.map do |location_model|
      send("#{location_model.const.location_slug}_name")
    end.select(&:present?).uniq
  end

end
