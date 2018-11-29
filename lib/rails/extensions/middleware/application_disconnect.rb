module Rails.application.class::Middleware
  # clear all connections
  class ApplicationDisconnect
    def initialize(app)
      @app = app
      @ignore_request_paths = /\A\/(assets)/
    end

    def call(env)
      # only connect for required pages
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
