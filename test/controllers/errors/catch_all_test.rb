class ErrorsController::Test < ApplicationController::TestCase

  action = "get catch_all"

  testing action do
    get(:catch_all)
    assert_response_ok
  end

  action = "get catch_all_test"

  testing action do
    assert_raises(ActionController::UnknownFormat) do
      get(:catch_all_test)
    end
  end

end
