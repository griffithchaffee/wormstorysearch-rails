class ApplicationController < ActionController::Base

  before_action(:set_admin_status)

  def set_admin_status
    session[:is_admin] = "true" if is_admin_passphrase?
    is_admin?
  end

  def is_admin?
    session[:is_admin].to_s == "true"
  end
  helper_method(:is_admin?)

  def is_admin_passphrase?
    params[:passphrase] == ENV["ADMIN_PASSPHRASE"]
  end
  helper_method(:is_admin_passphrase?)

  def is_admin_ip_address?
    request.remote_ip.in?(ENV["ADMIN_IP_ADDRESSES"].split(" "))
  end
  helper_method(:is_admin_ip_address?)

  def admin_only_action
    if !is_admin?
      flash.info("You must be an admin to perform this action")
      redirect_to(stories_path)
    end
  end

end
