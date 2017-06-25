class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception

  def is_admin?
    if Rails.env.development?
      true
    else
      request.remote_ip == Rails.application.settings.admin_ip
    end
  end

  helper_method :is_admin?
end
