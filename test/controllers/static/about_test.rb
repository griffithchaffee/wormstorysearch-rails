class StaticController::Test < ApplicationController::TestCase

  action = "get about"

  testing "#{action}" do
    get(:contact)
    assert_response_ok
  end

end
