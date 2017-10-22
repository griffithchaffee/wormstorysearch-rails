class StoriesController::Test < ApplicationController::TestCase

  action = "patch update"

  def update_setup
    @story = FactoryGirl.create(:story)
    @original_attributes = {
      title: "ORIG_TITLE",
      crossover: "ORIG_CROSS",
      description: "ORIG_DESC",
    }
    @new_attributes = {
      title: "NEW_TITLE",
      crossover: "NEW_CROSS",
      description: "NEW_DESC",
    }
    @story.update!(@original_attributes)
  end

  testing "#{action}" do
    update_setup
    patch(:update, params: { "id" => @story.id, story: @new_attributes })
    assert_response_redirect(stories_path, flash: { notice: 1 })
    # update changes
    @new_attributes.each do |key, value|
      assert_equal(value, @story.reload.send(key))
    end
  end

  testing "#{action} when locked" do
    update_setup
    @story.update!(is_locked: true)
    # request
    patch(:update, params: { "id" => @story.id, story: @new_attributes.merge(is_locked: false, is_archived: false) })
    assert_response_redirect(stories_path, flash: { info: 1 })
    # no changes
    @original_attributes.each do |key, value|
      assert_equal(value, @story.reload.send(key))
    end
    assert_equal([true, false], [@story.is_locked, @story.is_archived])
  end

  testing "#{action} when admin" do
    update_setup
    become_admin
    # request
    patch(:update, params: { "id" => @story.id, story: @new_attributes.merge(is_locked: true, is_archived: true) })
    assert_response_redirect(stories_path, flash: { notice: 1 })
    # update changes
    @new_attributes.each do |key, value|
      assert_equal(value, @story.reload.send(key))
    end
    assert_equal([true, true], [@story.is_locked, @story.is_archived])
  end

end
