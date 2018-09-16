# silence logger for specific paths
module Rails.application.class::Middleware
  class ApplicationTimeZone
    def initialize(app)
      @app = app
    end

    def call(env)
      Time.use_zone(Rails.configuration.time_zone) do
        @app.call(env)
      end
    end
  end
end
