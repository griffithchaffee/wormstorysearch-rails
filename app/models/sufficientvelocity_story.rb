class SufficientvelocityStory < ApplicationRecord
  # modules/constants
  include LocationStoryConcern

  # load settings
  class_constant(:location_slug, "sufficientvelocity")
  Rails.application.settings.locations[const.location_slug].to_h.each do |key, value|
    class_constant("location_#{key}", value)
  end

  # associations/scopes/validations/callbacks/macros

  # public/private/protected/classes
  def read_url!
    chapters.size == 0 ? location_url : "#{location_url}/threadmarks"
  end

  def update_rating!(update_chapters: false)
    # mass update chapters
    if update_chapters
      chapters.sort.each(&:update_rating!)
    end
    # only select chapters that have been rated and at least a week old
    rated_chapters = chapters.select do |chapter|
      chapter.category == "chapter" &&
      chapter.likes > 0 &&
      chapter.chapter_created_on <= 3.days.ago
    end
    # update cached ratings
    self.average_chapter_likes = rated_chapters.sum(&:likes).to_i / rated_chapters.size.min(1)
    self.highest_chapter_likes = rated_chapters.map(&:likes).max.to_i
    save! if has_changes_to_save?
    self
  end

end
