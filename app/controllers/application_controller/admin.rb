class ApplicationController < ActionController::Base

  def is_admin?
    return true if Rails.env.development?
    session[:is_admin] = "true" if params[:passphrase] == ENV["ADMIN_PASSPHRASE"]
    session[:is_admin].to_s == "true"
  end
  helper_method :is_admin?

  def admin_only_action
    if !is_admin?
      flash.info("You must be an admin to perform this action")
      redirect_to(stories_path)
    end
  end

end
