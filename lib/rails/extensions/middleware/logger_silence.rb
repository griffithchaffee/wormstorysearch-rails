# silence logger for specific paths
module Rails.application.class::Middleware
  class LoggerSilencer
    def initialize(app)
      @app = app
      @silence_request_paths = /\A\/(assets|favicon)/
    end

    def call(env)
      if Rails.logger && env["REQUEST_PATH"] =~ @silence_request_paths
        Rails.logger.info { "Started GET #{env["REQUEST_PATH"].inspect}" }
        response = nil
        Rails.logger.silence(Logger::WARN) do
          response = @app.call(env)
        end
        response
      else
        @app.call(env)
      end
    end
  end
end
