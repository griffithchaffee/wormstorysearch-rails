class StoriesController::Test < ApplicationController::TestCase

  action = "get edit"

  testing "#{action} without modal layout" do
    story = FactoryGirl.create(:story)
    assert_raises(ArgumentError) do
      get(:edit, params: { id: story.id })
    end
  end

  testing "#{action} with modal layout" do
    story = FactoryGirl.create(:story, crossover: "CROSS", description: "DESC")
    get(:edit, params: { id: story.id, layout: "modal" })
    assert_response_ok
    assert_in_response_body([
      story.title,
      "Crossover:",
      story.crossover,
      "Description:",
      story.description,
    ])
    assert_not_in_response_body(["Lock:"])
  end

  testing "#{action} with modal layout as admin" do
    become_admin
    story = FactoryGirl.create(:story, crossover: "CROSS", description: "DESC")
    get(:edit, params: { id: story.id, layout: "modal" })
    assert_response_ok
    assert_in_response_body("Lock:")
  end

end
