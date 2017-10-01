class FanfictionStory < ApplicationRecord
  # modules/constants
  include LocationStoryConcern

  # load settings
  class_constant(:location_slug, "fanfiction")
  Rails.application.settings.locations[const.location_slug].to_h.each do |key, value|
    class_constant("location_#{key}", value)
  end
  class_constant_builder(:statuses, %w[ status label ]) do |new_const|
    new_const.add(status: "ongoing",  label: "Ongoing")
    new_const.add(status: "complete", label: "Complete")
  end

  # associations/scopes/validations/callbacks/macros
  validates_in_list(:status, const.statuses.map(&:status))

  before_validation do
    if will_save_change_to_favorites? && favorites > 0
      self.favorites_updated_at = Time.zone.now
    end
  end

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

  after_save do
    if saved_change_to_favorites?
      Story.preload_locations.find(story_id).update_rating!
    end
  end

  # public/private/protected/classes
  def read_url!
    location_url
  end

  def update_rating!
    searcher = LocationSearcher::FanfictionSearcher.new
    run_at = Time.zone.now
    searcher.update_story_favorites!(self)
    self.favorites_updated_at = run_at if favorites_updated_at
    self
  end

end
