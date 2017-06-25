class StoriesController::Test < ApplicationController::TestCase

  action = "get show"

  testing "#{action} without modal layout" do
    story = FactoryGirl.create(:story)
    assert_raises(ArgumentError) do
      get(:show, params: { id: story.id })
    end
  end

  testing "#{action} with modal layout" do
    story = FactoryGirl.create(:story, description: "DESC")
    get(:show, params: { id: story.id, layout: "modal" })
    assert_response_ok
    assert_in_response_body([
      story.author,
      story.title,
      story.description,
      story.read_url,
    ])
  end

end
