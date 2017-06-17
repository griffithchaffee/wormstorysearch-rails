# load ruby extensions
Dir["#{Rails.root}/lib/ruby/*.rb"].each { |file| require file }
# load services
Dir["#{Rails.root}/lib/services/*.rb"].each { |file| require file }
# load rails extensions
Dir["#{Rails.root}/lib/rails/extensions/*.rb"].each { |file| require file }
# rails initializers
Class.new(Rails::Railtie) do
  { before_initialize: "configurations", after_initialize: "initializers" }.each do |callback, directory|
    config.send(callback) { Dir["#{Rails.root}/lib/rails/#{directory}/**/*.rb"].each { |file| instance_eval(File.read(file), file) } }
  end
end

# application abstract table
class ApplicationRecord < PostgresqlDatabase::AbstractTable
  self.abstract_class = true
  setup_single_database_configuration!("postgresql_database.yml.erb")
end

begin
  ApplicationRecord.connect
rescue ActiveRecord::NoDatabaseError => e
  puts "#{e.class}: #{e.message}"
end

# establish_connection management
ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.send(:define_method, :resolve_connection) do |hash_or_env|
  configuration =
    case hash_or_env
    when PostgresqlDatabase::Configuration then hash_or_env
    when Hash then PostgresqlDatabase::Configuration.new(hash_or_env)
    when Rails.env, Rails.env.to_sym then ApplicationRecord.database_configuration
    else raise ArgumentError, "unable to resolve database configuration: #{hash_or_env.inspect}"
    end
  # save host ip incase of DNS failure
  configuration.setup
end

# initial database connection
ActiveRecord::ConnectionHandling.send(:remove_const, :DEFAULT_ENV)
ActiveRecord::ConnectionHandling::DEFAULT_ENV = -> { Rails.env }

# skip database.yml load
class << Rails.application.config
  define_method(:database_configuration) { {} }
end
