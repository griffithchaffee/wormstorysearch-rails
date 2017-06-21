class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout -> { params[:layout] || "application" }
end
