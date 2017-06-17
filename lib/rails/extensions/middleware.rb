# silence logger for specific paths
class Finalforms::LoggerSilencer
  def initialize(app)
    @app = app
    @ignore = /\A\/(ping|assets)/
  end

  def call(env)
    if env["REQUEST_PATH"] =~ @ignore && Rails.logger
      Rails.logger.silence Logger::WARN do
        return @app.call(env)
      end
    else
      @app.call(env)
    end
  end
end


# connect to subdomain organization
class Finalforms::OrganizationConnect
  def initialize(app)
    @app = app
  end

  def call(env)
    domain = env["HTTP_HOST"].split(":").first
    subdomain = domain.split(".").first.try(:downcase)
    connect_to_organization = -> (resource) do
      begin
        # default connect attempt
        resource.connect!
      rescue PG::ConnectionBad => exception
        # log and retry by ip
        Rails.logger.warn do
          [
            "#{exception.class}: #{exception.message}".strip,
            "domain=#{domain} uri=#{env["REQUEST_URI"]} source=#{env["REMOTE_ADDR"]}",
            "host=#{resource.database_configuration.host} ip=#{resource.database_configuration.ip}",
            "host_to_ip=#{DatabaseConfiguration.host_to_ip}",
          ].join(" - ")
        end
        resource.connect! :by_ip
      end
    end

    Rails.logger.tagged(subdomain) do
      # connect to umbrella and organization database
      connect_to_organization.call Organization
      organization = Organization.find_by(subdomain: subdomain) || Organization.default
      connect_to_organization.call organization
      env["finalforms.organization"]           = organization
      env["finalforms.organization.domain"]    = domain
      env["finalforms.organization.subdomain"] = subdomain
      env["finalforms.organization.found"]     = subdomain == organization.subdomain || subdomain == Organization.subdomain
      # set request timezone
      Time.use_zone(env["finalforms.organization"].time_zone) do
        @app.call(env)
      end
    end
  end
end


# clear all connections
class Finalforms::OrganizationDisconnect
  def initialize(app)
    @app = app
  end

  def call(env)
    Organization.disconnect_all
    response = @app.call(env)
    # streaming response needs its connection to stay open
    Organization.disconnect_all if response[1]["X-Accel-Buffering"] != "no"
    response
  end
end

class Finalforms::OrganizationNotFound
  def initialize(app)
    @app = app
    @ignore = /\A\/(ping|assets)/
  end

  def call(env)
    if env["finalforms.organization.found"] || env["REQUEST_PATH"] =~ @ignore
      @app.call(env)
    else
      raise Organization::NotFound, "organization [#{env["finalforms.organization.subdomain"]}] not found"
    end
  end
end
