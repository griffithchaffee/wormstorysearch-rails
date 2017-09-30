class SufficientvelocityStory::Test < ApplicationRecord::TestCase

  include LocationStoryConcern::TestConcern

  testing "read_url" do
    story = FactoryGirl.create(factory)
    assert_equal("SufficientVelocity", story.const.location_label)
    assert_equal("https://forums.sufficientvelocity.com", story.const.location_host)
    # no chapters
    assert_equal(story.location_url, story.read_url)
    # add chapter
    FactoryGirl.create("#{factory}_chapter", story: story)
    assert_equal("#{story.location_url}/threadmarks", story.reload.read_url)
  end

  testing "update_rating!" do
    story = FactoryGirl.create(factory, story_created_on: 1.month.ago, story_updated_at: 1.month.ago)
    valid_chapter1   = FactoryGirl.create(:sufficientvelocity_story_chapter, story: story, chapter_created_on: 1.month.ago, chapter_updated_at: 1.week.ago, likes: 10)
    valid_chapter2   = FactoryGirl.create(:sufficientvelocity_story_chapter, story: story, chapter_created_on: 1.month.ago, chapter_updated_at: 1.week.ago, likes: 20)
    new_chapter     = FactoryGirl.create(:sufficientvelocity_story_chapter, story: story, chapter_created_on: 1.day.ago, chapter_updated_at: 1.hour.ago)
    unliked_chapter = FactoryGirl.create(:sufficientvelocity_story_chapter, story: story, chapter_created_on: 1.month.ago, chapter_updated_at: 1.week.ago, likes: 0)
    omake_chapter   = FactoryGirl.create(:sufficientvelocity_story_chapter, story: story, chapter_created_on: 1.month.ago, chapter_updated_at: 1.week.ago, category: "omake")
    # after_save update story rating
    assert_equal([20, 15.0], [story.highest_chapter_likes, story.average_chapter_likes])
  end

end
