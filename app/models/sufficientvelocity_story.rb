class SufficientvelocityStory < ApplicationRecord
  # modules/constants
  include LocationStoryConcern

  # associations/scopes/validations/callbacks/macros

  # public/private/protected/classes
  def read_url!
    chapters.size == 0 ? location_url : "#{location_url}/threadmarks"
  end

  def update_rating!(update_chapters: false)
    # mass update chapters
    if update_chapters
      searcher = LocationSearcher::SufficientvelocitySearcher.new
      searcher.login!
      chapters.sort.each { |chapter| chapter.update_rating!(searcher: searcher) }
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

  def crossover_for_story
    universal_parse_crossover_from_title
  end

end
