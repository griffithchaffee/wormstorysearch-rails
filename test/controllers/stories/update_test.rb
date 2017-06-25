class StoriesController::Test < ApplicationController::TestCase

  action = "patch update"

  def update_setup
    @story = FactoryGirl.create(:story, location: "spacebattles", crossover: "ORIG_CROSS", description: "ORIG_DESC")
    @original_attributes = @story.attributes
    @update_attributes = FactoryGirl.build(
      :story,
      location: "sufficientvelocity",
      is_locked: true,
      crossover: "NEW_CROSS",
      description: "NEW_DESC",
      story_created_on: @original_attributes["story_created_on"] - 1.hour,
      story_updated_at: @original_attributes["story_updated_at"] - 1.hour,
      word_count: @original_attributes["word_count"] + 1,
    ).attributes.except(*%w[ id created_at updated_at ])
  end

  testing "#{action}" do
    update_setup
    patch(:update, params: { "id" => @story.id, story: @update_attributes })
    assert_response_redirect(stories_path, flash: { notice: 1 })
    # update changes
    changed_attributes = %w[ crossover description ]
    assert_hash_change(@original_attributes, @update_attributes, @story.reload.attributes, changed_attributes)
  end

  testing "#{action} when locked" do
    update_setup
    @story.update!(is_locked: true)
    @original_attributes["is_locked"] = true
    @update_attributes["is_locked"] = false
    # request
    patch(:update, params: { "id" => @story.id, story: @update_attributes })
    assert_response_redirect(stories_path, flash: { info: 1 })
    # no changes
    assert_no_hash_change(@original_attributes, @update_attributes, @story.reload.attributes)
  end

  testing "#{action} when admin" do
    update_setup
    become_admin
    # request
    patch(:update, params: { "id" => @story.id, story: @update_attributes })
    assert_response_redirect(stories_path, flash: { notice: 1 })
    # update changes
    changed_attributes = %w[ crossover description is_locked ]
    assert_hash_change(@original_attributes, @update_attributes, @story.reload.attributes, changed_attributes)
  end

end
