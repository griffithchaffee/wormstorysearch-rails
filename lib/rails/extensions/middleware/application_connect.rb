module Rails.application.class::Middleware
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
          Rails.logger.warn { "ApplicationDatabase connecting by_ip: #{error.class}: #{error.message} [#{env["REQUEST_PATH"]}]" }
          ApplicationDatabase.connect!(:by_ip)
        end
      end
      tags = []
      tags << env["action_dispatch.request_id"] if !Rails.env.development?
      Rails.logger.tagged(tags) do
        @app.call(env)
      end
    end
  end
end
