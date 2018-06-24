class StoryAuthorsController::Test < ApplicationController::TestCase

  action = "get edit"

  testing "#{action}" do
    story_author = FactoryBot.create(:story_author)
    get(:edit, params: { id: story_author.id })
    assert_response_admin_only
  end

  testing "#{action} as admin" do
    story_author = FactoryBot.create(:story_author)
    become_admin
    assert_raises(ArgumentError) do
      get(:edit, params: { id: story_author.id })
    end
  end

  testing "#{action} with view_layout=modal as admin" do
    story_author = FactoryBot.create(:story_author)
    become_admin
    set_view_layout("modal")
    get(:edit, params: { id: story_author.id })
    assert_response_ok
    assert_in_response_body([
      *story_author.name,
      *Story.const.location_models.map { |location_model| story_author.send("#{location_model.const.location_slug}_name") }
    ])
  end

end
