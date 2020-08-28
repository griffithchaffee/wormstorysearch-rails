class ApplicationController < ActionController::Base

  before_action(:set_theme)
  helper_method(:get_theme)

  def set_theme
    if params[:theme].present?
      change_session_action_data(session_action_data, data_params: { theme: params[:theme] })
    end
    Rails.logger.fatal session_action_data.inspect
  end

  def get_theme
    case session_action_data.data_params[:theme]
    when "dark" then "dark"
    else "light"
    end
  end

end
