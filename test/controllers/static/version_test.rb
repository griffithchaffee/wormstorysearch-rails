class StaticController::Test < ApplicationController::TestCase

  action = "get version"

  testing "#{action}" do
    get(:version)
    assert_response_ok
  end

end
