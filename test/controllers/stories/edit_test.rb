class StoriesController::Test < ApplicationController::TestCase

  action = "get edit"

  testing "#{action}" do
    story = FactoryGirl.create(:story, crossover: "CROSSOVER", description: "DESCRIPTION")
    get(:edit, params: { id: story.id })
    assert_response_admin_only
  end

  testing "#{action} with view_layout=modal as admin" do
    story = FactoryGirl.create(:story, crossover: "CROSSOVER", description: "DESCRIPTION")
    @request.env["HTTP_X_VIEW_LAYOUT"] = "modal"
    become_admin
    get(:edit, params: { id: story.id })
    assert_response_ok
    assert_in_response_body([
      story.title,
      story.description,
      story.crossover,
      story.read_url,
    ])
    assert_not_in_response_body(%w[ Archived Locked ])
  end

  testing "#{action} as admin" do
    story = FactoryGirl.create(:story, crossover: "CROSSOVER", description: "DESCRIPTION")
    become_admin
    get(:edit, params: { id: story.id })
    assert_response_ok
    assert_in_response_body([
      story.title,
      story.description,
      story.crossover,
      story.read_url,
      *%w[ Archive Lock ],
    ])
  end


end
