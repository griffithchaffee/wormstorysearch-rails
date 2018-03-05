class ErrorsController::Test < ApplicationController::TestCase

  action = "get not_found"

  testing action do
    get(:not_found)
    assert_response_ok
  end

end
