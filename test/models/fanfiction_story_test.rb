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

end
