class FanfictionStory::Test < ApplicationRecord::TestCase

  include LocationStoryConcern::TestConcern

  testing "read_url" do
    story = FactoryGirl.create(factory)
    assert_equal("FanFiction", story.const.location_label)
    assert_equal("https://www.fanfiction.net", story.const.location_host)
    # no chapters
    assert_equal(story.location_url, story.read_url)
    # add chapter
    FactoryGirl.create("#{factory}_chapter", story: story)
    assert_equal(story.location_url, story.reload.read_url)
  end

  testing "update_rating!" do
    location_story = FactoryGirl.create(factory)
    story = location_story.story
    # after_save update story rating
    location_story.update!(favorites: 30)
    # story rating should be updated
    assert_equal(location_story.rating, story.reload.rating)
  end

end
