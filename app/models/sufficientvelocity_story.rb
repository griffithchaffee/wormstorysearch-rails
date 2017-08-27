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
=begin
  def update_rating!(update_chapters: true)
    story_chapters = chapters.sort.select { |chapter| chapter.category == "chapter" }
    if update_chapters
      searcher = LocationSearcher::SufficientvelocitySearcher.new
      story_chapters.each { |chapter| searcher.update_chapter_likes!(chapter) }
    end
    self.average_chapter_likes = story_chapters.sum(&:likes) / story_chapters.size.min(1)
    save! if has_changes_to_save?
    self
  end
=end
end
