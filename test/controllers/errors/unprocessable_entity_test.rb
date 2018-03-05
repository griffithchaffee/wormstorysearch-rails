class ErrorsController::Test < ApplicationController::TestCase

  action = "get unprocessable_entity"

  testing action do
    get(:unprocessable_entity)
    assert_response_ok
  end

  action = "get unprocessable_entity_test"

  testing action do
    assert_raises(ActiveRecord::RecordInvalid) do
      get(:unprocessable_entity_test)
    end
  end

end
