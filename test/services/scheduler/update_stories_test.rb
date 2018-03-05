class Scheduler::Test < ApplicationTestCase

  testing "update_stories" do
    # archived stories
    archived_story1 = FactoryGirl.create(:story, is_archived: true)
    archived_story2 = FactoryGirl.create(:story, is_archived: true)
    FactoryGirl.create(:spacebattles_story, story: archived_story1)
    # missing author stories
    missing_author_story1 = FactoryGirl.create(:story, author: nil)
    missing_author_story2 = FactoryGirl.create(:story, author: nil)
    missing_author_story2_location = FactoryGirl.create(:spacebattles_story, story: missing_author_story2)
    missing_author_story2.update!(author: nil)
    assert_equal([false, false], [missing_author_story1, missing_author_story2].map { |story| story.reload.author.present? })
    # duplicate stories
    duplicate_story1 = FactoryGirl.create(:story)
    duplicate_story2 = FactoryGirl.create(:story, title: duplicate_story1.title, author: duplicate_story1.author)
    assert_equal([duplicate_story1, duplicate_story2].map(&:id), Story.where_has_duplicates.sort.map(&:id))
    Scheduler.run(:update_stories)
    # archived stories without locations are deleted
    assert_equal([true, false], [archived_story1, archived_story2].map { |story| Story.where(id: story.id).exists? })
    # missing author stories are updated
    assert_equal([false, true], [missing_author_story1, missing_author_story2].map { |story| story.reload.author.present? })
    assert_equal(
      [nil, missing_author_story2_location.author],
      [missing_author_story1, missing_author_story2].map { |story| story.reload.author }
    )
    # duplicate stories are merged
    assert_equal([true, false], [duplicate_story1, duplicate_story2].map { |story| Story.where(id: story.id).exists? })
  end

end
