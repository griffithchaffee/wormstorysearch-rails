class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception

  def is_admin?
    if Rails.env.production?
      request.remote_ip == "70.185.183.167"
    else
      true
    end
  end

  helper_method :is_admin?
end
