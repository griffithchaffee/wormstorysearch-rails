class FanfictionStory < ApplicationRecord
  # modules/constants
  include LocationStoryConcern

  # load settings
  class_constant(:location_slug, "fanfiction")
  Rails.application.settings.locations[const.location_slug].to_h.each do |key, value|
    class_constant("location_#{key}", value)
  end

  # associations/scopes/validations/callbacks/macros
  after_create do
    if story && story.is_unlocked?
      # overwrite crossover
      if crossover? && story.crossover != crossover
        story.crossover = crossover
      end
      # default description
      if !story.description? && story.description != description
        story.description = description
      end
      story.save! if story.has_changes_to_save?
    end
  end

  # public/private/protected/classes
  def read_url!
    location_url
  end

end