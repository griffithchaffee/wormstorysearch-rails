class Scheduler::Test < ApplicationTestCase

  testing "update_stories_statuses" do
    complete_story = FactoryGirl.create(:story, status: "complete")
    ongoing_story = FactoryGirl.create(:story, status: "ongoing")
    stale_story = FactoryGirl.create(:story, status: "ongoing", story_updated_at: 13.months.ago)
    dead_story = FactoryGirl.create(:story, status: "dead")
    Scheduler.run(:update_story_statuses)
    assert_equal(
      %w[ complete ongoing dead dead ],
      [complete_story, ongoing_story, stale_story, dead_story].map(&:reload).map(&:status)
    )
  end

end
