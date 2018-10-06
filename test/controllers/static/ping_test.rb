class StaticController::Test < ApplicationController::TestCase

  action = "get ping"

  testing "#{action}" do
    get(:ping)
    assert_response_ok
  end

end
