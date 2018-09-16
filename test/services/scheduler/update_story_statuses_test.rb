class Scheduler::Test < ApplicationTestCase

  testing "update_stories_statuses" do
    complete_story = FactoryBot.create(:story, status: "complete")
    old_complete_story = FactoryBot.create(:story, status: "complete", story_updated_at: Story.const.dead_status_duration.ago - 1.day)
    ongoing_story = FactoryBot.create(:story, status: "ongoing", story_updated_at: Story.const.dead_status_duration.ago + 1.day)
    stale_story = FactoryBot.create(:story, status: "ongoing", story_updated_at: Story.const.dead_status_duration.ago - 1.day)
    dead_story = FactoryBot.create(:story, status: "dead")
    Scheduler.run(:update_story_statuses)
    assert_equal(
      %w[ complete complete ongoing dead dead ],
      [complete_story, old_complete_story, ongoing_story, stale_story, dead_story].map(&:reload).map(&:status)
    )
  end

end
