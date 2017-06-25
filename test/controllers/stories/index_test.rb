class StoriesController::Test < ApplicationController::TestCase

  action = "get index"

  testing "#{action} without stories" do
    get(:index)
    assert_response_ok
  end

  testing "#{action} with stories" do
    stories = []
    5.times { stories << FactoryGirl.create(:story) }
    get(:index)
    assert_response_ok
    assert_in_response_body([
      *stories.map(&:title),
      *stories.map(&:read_url),
    ])
  end

end
