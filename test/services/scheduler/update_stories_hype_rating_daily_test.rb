class Scheduler::Test < ApplicationTestCase

  testing "update_stories_hype_rating_daily" do
    # archived stories
    story = FactoryBot.create(:story, rating: 100, story_created_on: 36.hours.ago, hype_rating: 0)
    assert_same(0, story.reload.hype_rating)
    # missing author stories
    Scheduler.run(:update_stories_hype_rating_daily)
    # archived stories without locations are deleted
    assert_same(2000, story.reload.hype_rating)
  end

end
