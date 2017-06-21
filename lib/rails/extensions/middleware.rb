# silence logger for specific paths
module Rails.application.class::Middleware
  class LoggerSilencer
    def initialize(app)
      @app = app
      @silence_request_paths = /\A\/(ping|assets|favicon)/
    end

    def call(env)
      if Rails.logger && env["REQUEST_PATH"] =~ @silence_request_paths
        Rails.logger.debug { "Started GET #{env["REQUEST_PATH"].inspect}" }
        response = nil
        Rails.logger.silence(Logger::WARN) { response = @app.call(env) }
        response
      else
        @app.call(env)
      end
    end
  end


  # connect to subdomain organization
  class ApplicationConnect
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["#{Rails.application.settings.namespace}.database.connect"] == true
        begin
          ApplicationDatabase.connect!
        rescue PG::ConnectionBad => error
          byebug
          Rails.logger.warn { "ApplicationDatabase connecting by_ip: #{error.class}: #{error.message} [#{env["REQUEST_PATH"]}]" }
          ApplicationDatabase.connect!(:by_ip)
        end
      end
      @app.call(env)
    end
  end


  # clear all connections
  class ApplicationDisconnect
    def initialize(app)
      @app = app
      @ignore_request_paths = /\A\/(ping|assets)/
    end

    def call(env)
      env["#{Rails.application.settings.namespace}.database.connect"] = env["REQUEST_PATH"] =~ @ignore_request_paths ? false : true
      if env["#{Rails.application.settings.namespace}.database.connect"]
        ApplicationDatabase.disconnect
        response = @app.call(env)
        ApplicationDatabase.disconnect
        response
      else
        response = @app.call(env)
      end
    end
  end
end
