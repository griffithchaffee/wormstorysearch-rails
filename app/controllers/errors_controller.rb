class ErrorsController < ApplicationController

  before_action { request.format = :html }

  def catch_all
  end

  def internal_server_error
  end

  def unprocessable_entity
  end

  def bad_request
  end

  def not_found
  end

  def internal_server_error_test
    raise "testing internal_server_error"
  end

  def unprocessable_entity_test
    raise ActiveRecord::RecordInvalid.new(Story.new), "testing unprocessable_entity"
  end

  def catch_all_test
    raise ActionController::UnknownFormat, "testing catch_all"
  end

private

  def exception
    request.env["action_dispatch.exception"]
  end
  helper_method :exception

  def original_exception
    exception.try(:original_exception)
  end
  helper_method :original_exception

  def exception_status_code
    request.env["action_dispatch.exception.status_code"]
  end
  helper_method :exception_status_code

  def exception_rescue_action
    request.env["action_dispatch.exception.rescue_action"]
  end
  helper_method :exception_rescue_action

end
