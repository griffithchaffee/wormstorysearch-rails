class StoriesController::Test < ApplicationController::TestCase

  action = "get show"

  testing "#{action}" do
    story = FactoryGirl.create(:story, crossover: "CROSSOVER", description: "DESCRIPTION")
    get(:show, params: { id: story.id })
    assert_response_ok
    assert_in_response_body([
      story.author,
      story.title,
      story.description,
      story.crossover,
      story.read_url,
    ])
    assert_equal("application", @controller.view_layout)
  end

  testing "#{action} with locations" do
    story = FactoryGirl.create(:story, crossover: "CROSSOVER", description: "DESCRIPTION")
    story.const.location_models.each do |location_model|
      FactoryGirl.create("#{location_model.const.location_slug}_story", story: story)
    end
    get(:show, params: { id: story.id })
    assert_response_ok
    assert_in_response_body([
      story.author,
      story.title,
      story.description,
      story.crossover,
      story.read_url,
    ])
  end

  testing "#{action} with locations and view_layout=modal" do
    story = FactoryGirl.create(:story, crossover: "CROSSOVER", description: "DESCRIPTION")
    story.const.location_models.each do |location_model|
      FactoryGirl.create("#{location_model.const.location_slug}_story", story: story)
    end
    @request.env["HTTP_X_VIEW_LAYOUT"] = "modal"
    get(:show, params: { id: story.id })
    assert_response_ok
    assert_in_response_body([
      story.author,
      story.title,
      story.description,
      story.crossover,
      story.read_url,
    ])
    assert_equal("modal", @controller.view_layout)
  end

end
