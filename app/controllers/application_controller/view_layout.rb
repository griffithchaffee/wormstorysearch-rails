class ApplicationController < ActionController::Base

  layout(:view_layout)

  def view_layout
    return @view_layout if !@view_layout.nil?
    provided_layout ||= params[:layout].to_s
    @view_layout = provided_layout == "" ? "application" : provided_layout
    @view_layout = false if @view_layout == "false"
    @view_layout
  end
  helper_method :view_layout

end
