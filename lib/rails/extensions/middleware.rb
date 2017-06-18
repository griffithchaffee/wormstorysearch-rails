# silence logger for specific paths
class Rails.application.class::MiddlewareLoggerSilencer
  def initialize(app)
    @app = app
    @ignore = /\A\/(ping|assets)/
  end

  def call(env)
    if env["REQUEST_PATH"] =~ @ignore && Rails.logger
      Rails.logger.silence(Logger::WARN) { return @app.call(env) }
    else
      @app.call(env)
    end
  end
end


# connect to subdomain organization
class Rails.application.class::MiddlewareApplicationConnect
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      ApplicationRecord.connect!
    rescue PG::ConnectionBad => exception
      Rails.logger.warn { "#{exception.class}: #{exception.message}".strip }
      ApplicationRecord.connect!(:by_ip)
    end
    @app.call(env)
  end
end


# clear all connections
class Rails.application.class::MiddlewareApplicationDisconnect
  def initialize(app)
    @app = app
  end

  def call(env)
    ApplicationRecord.disconnect_all
    response = @app.call(env)
    ApplicationRecord.disconnect_all
    response
  end
end
