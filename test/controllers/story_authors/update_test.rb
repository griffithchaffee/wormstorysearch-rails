class StoryAuthorsController::Test < ApplicationController::TestCase

  action = "patch update"

  def update_setup
    @story_author = FactoryGirl.create(:story_author)
    @original_attributes = { name: "ORIG_NAME" }
    @new_attributes = { name: "NEW_NAME" }
    Story.const.location_models.each do |location_model|
      @original_attributes["#{location_model.const.location_slug}_name"] = "ORIG_#{location_model.const.location_slug.upcase}"
      @new_attributes["#{location_model.const.location_slug}_name"] = "NEW_#{location_model.const.location_slug.upcase}"
    end
    @story_author.update!(@original_attributes)
  end

  testing "#{action}" do
    update_setup
    patch(:update, params: { "id" => @story_author.id, story_author: @new_attributes })
    assert_response_admin_only
    @original_attributes.each do |key, value|
      assert_equal(value, @story_author.send(key))
    end
  end

  testing "#{action} when admin" do
    update_setup
    become_admin
    # request
    patch(:update, params: { "id" => @story_author.id, story_author: @new_attributes })
    @story_author.reload
    assert_response_redirect(story_authors_path, flash: { notice: 1 })
    # update changes
    @new_attributes.each do |key, value|
      assert_equal(value, @story_author.send(key), "#{key}")
    end
  end

end
