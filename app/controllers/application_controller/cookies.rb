class ApplicationController < ActionController::Base

  before_action do
    %w[ browser.identity ].each do |cookie_slug|
      Rails.logger.info { "Cookie [#{cookie_slug}]: #{cookies[cookie_slug]}" }
    end
  end

end
