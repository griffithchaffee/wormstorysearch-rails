class SufficientvelocityStoryChapter::Test < ApplicationRecord::TestCase

  include LocationStoryChapterConcern::TestConcern

  testing "updating likes" do
    story = FactoryBot.create(:sufficientvelocity_story, story_created_on: 2.months.ago, story_updated_at: 1.month.ago)
    chapter = FactoryBot.create(factory, story: story, chapter_created_on: 1.month.ago, chapter_updated_at: 1.week.ago)
    story = chapter.story
    # before_validation update likes_updated_at
    assert_nil(chapter.likes_updated_at)
    chapter.update!(likes: 10)
    assert_equal(Time.zone.now.to_date, chapter.likes_updated_at.to_date)
    # after_save update story rating
    assert_equal([10, 10.0], [story.highest_chapter_likes, story.average_chapter_likes])
  end

end
