require_relative "postgresql_database/configuration"
require_relative "postgresql_database/abstract_table"
require_relative "postgresql_database/model_connect_concern"

class PostgresqlDatabase

  # store active connections
  cattr_accessor :connections
  self.connections = {}

  # macros
  attr_accessor :database_configuration
  delegate *%w[ database abstract_table namespace ], to: :database_configuration
  delegate *%w[ connection ], to: :abstract_table

  def initialize(database_configuration)
    self.database_configuration = database_configuration
  end

  def exists?
    unobtrusive_connect(:postgres) { abstract_table::PGDatabase.where(datname: database).exists? }
  end

  def create!
    unobtrusive_connect(:postgres) { connection.create_database(database) }
  end

  def drop!
    unobtrusive_connect(:postgres) { connection.drop_database(database) }
  end

  def migrate!
    unobtrusive_connect { migrations.exec_migration(connection, :up) }
  end

  def rollback!
    unobtrusive_connect { migrations.exec_migration(connection, :down) }
  end

  def migrate_to_latest_schema!
    unobtrusive_connect { build_migrations(latest_schema).exec_migration(connection, :up) }
  end

  def current_schema
    unobtrusive_connect { ActiveRecord::SchemaDumper.dump(connection, StringIO.new).string }
  end

  def create
    if !exists?
      Rails.logger.info(database) { "creating database" }
      create!
      ActiveRecord::Migration[migration_version].suppress_messages { migrate_to_latest_schema! }
      #ApplicationDatabase.reset_column_information
    end
  end

  def drop
    if exists?
      Rails.logger.info(database) { "dropping database" }
      drop!
    end
  end

  def migrate(force = false)
    if force.to_s.in?(%w[ true force ]) || current_schema != latest_schema
      Rails.logger.info(database) { "migrating" }
      migrate!
      Rails.logger.warn(database) { "current schema != latest schema" } if current_schema != latest_schema
    else
      Rails.logger.info(database) { "current schema == latest schema" }
    end
  end

  def rollback
    Rails.logger.info(database) { "reverting" }
    rollback!
  end

  def migrations
    raise "migration file #{migration_file} does not exist" if !File.file?(migration_file)
    build_migrations File.read(migration_file)
  end

  def latest_schema
    raise "schema file #{schema_file} does not exist" if !File.file?(schema_file)
    File.read schema_file
  end

  def update_schema
    Rails.logger.info(database) { "updating schema #{schema_file}" }
    File.open(schema_file, "w") { |file| file.write(current_schema) }
  end

  def migration_file
    "#{Rails.root}/db/migrations/#{namespace}.rb"
  end

  def schema_file
    "#{Rails.root}/db/schemas/#{namespace}.rb"
  end

  def unobtrusive_connect(*params, &block)
    was_connected = connected?
    result = connect(*params, &block)
    was_connected ? connect : disconnect
    result
  end

  def connect(method = :by_host)
    new_connection = abstract_table.establish_connection(database_configuration.send(method))
    connections[abstract_table] = new_connection
    if block_given?
      result = yield
      disconnect
      result
    end
  end

  def connect!(*params)
    result = connect(*params)
    raise ConnectionNotEstablished if !connection.active?
    result
  end

  def disconnect
    active_connection = connections[abstract_table]
    if active_connection
      abstract_table.remove_connection(active_connection)
    end
  ensure
    connections.delete(abstract_table)
  end

  def connected?
    connections.key?(abstract_table)
  end

  def build_migrations(methods)
    Class.new(ActiveRecord::Migration[migration_version]) { class_eval(methods) }.new
  end

  def migration_version
    5.1
  end

  class << self
    def disconnect_all
      connections.each(&:disconnect)
    end
  end

  class ConnectionNotEstablished < StandardError; end
end
