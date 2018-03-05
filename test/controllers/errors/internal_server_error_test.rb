class ErrorsController::Test < ApplicationController::TestCase

  action = "get internal_server_error"

  testing action do
    get(:internal_server_error)
    assert_response_ok
  end

  action = "get internal_server_error_test"

  testing action do
    assert_raises(RuntimeError) do
      get(:internal_server_error_test)
    end
  end

end
