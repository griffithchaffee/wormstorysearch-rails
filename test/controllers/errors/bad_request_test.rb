class ErrorsController::Test < ApplicationController::TestCase

  action = "get bad_request"

  testing action do
    get(:bad_request)
    assert_response_ok
  end

end
