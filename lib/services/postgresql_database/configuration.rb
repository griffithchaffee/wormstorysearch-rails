class PostgresqlDatabase
  class Configuration < ActiveSupport::HashWithIndifferentAccess
    class_attribute :host_to_ip
    self.host_to_ip = { localhost: "127.0.0.1" }.with_indifferent_access

    def postgres
      merge(database: "postgres")
    end

    def database
      fetch(:database)
    end

    def host
      fetch(:host)
    end

    def username
      fetch(:username)
    end

    def password
      fetch(:password)
    end

    def ip
      host_to_ip[host] || set_ip!
    end

    def setup
      by_ip
      by_host
    end

    def set_ip!
      host_to_ip[host] = IPSocket.getaddress(host)
    end

    def by_ip
      merge host: ip
    end

    def by_host
      self
    end

    def abstract_table
      fetch(:abstract_table)
    end

    def manage
      PostgresqlDatabase.new(self)
    end
  end
end
