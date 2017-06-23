class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception
  def is_admin?
    request.remote_ip.in?(%w[ 127.0.0.1 70.185.183.167 ])
  end

  helper_method :is_admin?
end
