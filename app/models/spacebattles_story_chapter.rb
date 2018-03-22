class SpacebattlesStoryChapter < ApplicationRecord

  # modules/constants
  include LocationStoryChapterConcern

  # associations/scopes/validations/callbacks/macros
  before_validation do
    if will_save_change_to_likes? && likes > 0
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
    "#{SpacebattlesStory.const.location_host}#{location_path}"
  end

  def update_rating!(searcher: LocationSearcher::SpacebattlesSearcher.new)
    searcher.login! if !searcher.is_authentication?(:authenticated)
    searcher.update_chapter_likes!(self)
    self
  end

end
