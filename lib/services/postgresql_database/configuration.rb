class PostgresqlDatabase
  class Configuration < ActiveSupport::HashWithIndifferentAccess
    class_attribute :host_to_ip
    self.host_to_ip = { localhost: "127.0.0.1" }.with_indifferent_access

    %w[ database host username password abstract_table namespace ].each do |key|
      define_method(key) { fetch(key) }
    end

    def postgres
      merge(database: "postgres")
    end

    def by_host
      self
    end

    def by_ip
      merge(host: ip)
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

    def manage
      PostgresqlDatabase.new(self)
    end
  end
end
