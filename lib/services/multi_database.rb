class DatabaseConfiguration < ActiveSupport::HashWithIndifferentAccess
  class_attribute :host_to_ip
  self.host_to_ip = { localhost: "127.0.0.1" }.with_indifferent_access

  def postgres
    merge database: "postgres"
  end

  def database
    fetch :database
  end

  def host
    fetch :host
  end

  def username
    fetch :username
  end

  def password
    fetch :password
  end

  def ip
    host_to_ip[host] || set_ip!
  end

  def setup
    by_ip
    by_host
  end

  def set_ip!
    host_to_ip[host] = IPSocket.getaddress host
  end

  def by_ip
    merge host: ip
  end

  def by_host
    self
  end
end

class MultiDatabaseConfiguration
  def initialize(config_file = "databases.yml.erb")
    @namespaces = load_config_file(config_file).with_indifferent_access
    @namespaces.each do |namespace, hash|
      next if namespace == "defaults"
      hash = hash[Rails.env] if hash[Rails.env]
      hash[:configuration] = DatabaseConfiguration.new hash[:configuration] if hash[:configuration]
      @namespaces[namespace] = Struct.new(*hash.keys.map(&:to_sym)).new(*hash.values)
    end
  end

  def load_config_file(file)
    YAML.load ERB.new(File.read("#{Rails.root}/config/#{file}")).result
  end

  def to_h
    @namespaces
  end

  def method_missing(method, *params, &block)
    if method.to_s.in? @namespaces.keys
      return @namespaces[method]
    else
      super method, *params, &block
    end
  end
end
