class ApplicationController < ActionController::Base

  def is_admin?
    if Rails.env.development?
      true
    else
      request.remote_ip == Rails.application.settings.admin_ip
    end
  end
  helper_method :is_admin?

  def admin_only_action
    if !is_admin?
      flash.info("You must be an admin to perform this action")
      redirect_to(stories_path)
    end
  end

end
