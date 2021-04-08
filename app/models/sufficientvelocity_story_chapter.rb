class SufficientvelocityStoryChapter < ApplicationRecord

  # modules/constants
  include LocationStoryChapterConcern

  # associations/scopes/validations/callbacks/macros
  before_validation do
    if likes_changed? && likes > 0
      self.likes_updated_at = Time.zone.now
    end
  end

  after_save do
    if saved_change_to_likes?
      story.update_rating!
    end
  end

  # public/private/protected/classes
  def read_url
    "#{SufficientvelocityStory.const.location_host}#{location_path}"
  end

  def update_rating!(searcher: LocationSearcher::SufficientvelocitySearcher.new)
    searcher.login! if !searcher.is_authentication?(:authenticated)
    searcher.update_chapter_likes!(self)
  rescue StandardError => error
    update_columns(likes_updated_at: Time.zone.now)
    raise(error)
    self
  end

end
