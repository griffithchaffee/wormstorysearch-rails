class ApplicationController < ActionController::Base

  layout(:view_layout)

  class ViewLayout
    attr_reader :layout

    def initialize(layout, options = {})
      layout = layout.to_s
      options = options.with_indifferent_access
      @layout =
        case layout
        when "" then options.fetch(:default_layout) { "application" }
        when "false" then false
        else layout
        end
    end
  end

  def view_layout
    @view_layout ||= ViewLayout.new(request.headers["X-View-Layout"] || params[:view_layout]).layout
  end
  helper_method :view_layout

end
