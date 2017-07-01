class SpacebattlesStory::Test < ApplicationRecord::TestCase

  include LocationStoryConcern::TestConcern

  testing "location" do
    story = FactoryGirl.create(factory)
    assert_equal("SpaceBattles", story.const.location_label)
    assert_equal("https://forums.spacebattles.com", story.const.location_host)
    # no chapters
    assert_equal(story.location_url, story.read_url)
    FactoryGirl.create("#{factory}_chapter", story: story)
    assert_equal(story.location_url, story.reload.read_url)
  end

end
