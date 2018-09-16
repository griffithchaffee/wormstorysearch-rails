class StoriesController::Test < ApplicationController::TestCase

  action = "get clicked"

  testing("#{action}") do
    story = FactoryBot.create(:story)
    assert_equal(0, story.reload.clicks)
    get(:clicked, params: { id: story.id })
    assert_response_ok
    assert_in_response_body("clicked")
    assert_equal(1, story.reload.clicks)
  end

  Story.const.location_models.each do |location_model|
    testing("#{action} with #{location_model} location") do
      story = FactoryBot.create(:story)
      location_story = FactoryBot.create("#{location_model.const.location_slug}_story", story: story)
      assert_equal(0, story.reload.clicks)
      assert_equal(0, location_story.reload.clicks)
      get(:clicked, params: { id: story.id, location_model: location_story.class.name, location_id: location_story.id })
      assert_response_ok
      assert_in_response_body("clicked")
      assert_equal(1, story.reload.clicks)
      assert_equal(1, location_story.reload.clicks)
    end
  end

end
