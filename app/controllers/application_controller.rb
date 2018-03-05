class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception
  prepend_before_action :autocreate_session

  def autocreate_session
    session[:remote_ip] = request.remote_ip
    session
  end

end
