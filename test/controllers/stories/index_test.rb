class StoriesController::Test < ApplicationController::TestCase

  action = "get index"

  testing "#{action} without stories" do
    get(:index)
    assert_response_ok
  end

  testing "#{action} with stories" do
    stories = []
    archived_story = FactoryGirl.create(:story)
    Story.const.location_models.each do |location_model|
      location_story = FactoryGirl.create("#{location_model.const.location_slug}_story")
      stories << location_story.story
    end
    Story.archive_management!
    assert_equal(true, archived_story.reload.is_archived?)
    get(:index)
    assert_response_ok
    assert_in_response_body([
      *stories.map(&:title),
      *stories.map(&:read_url),
    ])
    assert_not_in_response_body([
      *archived_story.title
    ])
  end

end
