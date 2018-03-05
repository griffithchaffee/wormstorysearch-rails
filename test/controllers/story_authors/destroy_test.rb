class StoryAuthorsController::Test < ApplicationController::TestCase

  action = "delete destroy"

  testing "#{action}" do
    story_author = FactoryGirl.create(:story_author)
    delete(:destroy, params: { id: story_author.id })
    assert_response_admin_only
    assert_equal(1, StoryAuthor.count)
  end

  testing "#{action} as admin" do
    story_author = FactoryGirl.create(:story_author)
    become_admin
    delete(:destroy, params: { id: story_author.id })
    assert_response_redirect(story_authors_path, flash: { notice: 1 })
    assert_equal(0, StoryAuthor.count)
  end

end
