class StoryAuthorsController::Test < ApplicationController::TestCase

  action = "get index"

  testing "#{action} without story_authors" do
    get(:index)
    assert_response_ok
  end

  testing "#{action} with story_authors" do
    story_author = FactoryBot.create(:story_author)
    get(:index)
    assert_response_ok
    assert_in_response_body([
      *story_author.name,
      *Story.const.location_models.map { |location_model| story_author.send("#{location_model.const.location_slug}_name") }
    ])
  end

end
