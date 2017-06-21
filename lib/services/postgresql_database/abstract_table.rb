class PostgresqlDatabase
  class AbstractTable < ActiveRecord::Base
    self.abstract_class = true

    class << self
      def setup_single_database_configuration!(rails_config_file)
        # database_configuration
        define_singleton_method(:database_configuration) do
          database_configurations = File::Configuration.load_rails_config_file(rails_config_file)
          database_configuration = PostgresqlDatabase::Configuration.new(database_configurations.fetch(Rails.env))
          database_configuration[:abstract_table] = self
          database_configuration
        end
        # manage
        %w[ connect connect! disconnect ].each do |database_method|
          define_singleton_method(database_method) { |*params| database_configuration.manage.send(database_method, *params) }
        end
        # add default postgresql tables
        setup_postgresql_tables!
        self
      end

      def setup_postgresql_tables!
        # PGDatabase
        pg_database = Class.new(self) do
          self.table_name = :pg_database
          self.primary_key = :datname
        end
        const_set(:PGDatabase, pg_database)
        # PGStatDatabase
        pg_stat_database = Class.new(self) do
          self.table_name = :pg_stat_database
          self.primary_key = :datname
        end
        const_set(:PGStatDatabase, pg_stat_database)
        # PGActivityDatabase
        pg_stat_activity = Class.new(self) do
          self.table_name = :pg_stat_activity
          self.primary_key = :datname
        end
        const_set(:PGActivityDatabase, pg_stat_database)
        self
      end

      def create_abstract_table!(abstract_table_name)
        # add table predicate helpers
        abstract_tables = subclasses.select(&:abstract_class?)
        abstract_tables.each do |outer_abstract_table|
          predicate_method = "#{outer_abstract_table.name.underscore}?"
          abstract_tables.each do |inner_abstract_table|
            # instance method
            inner_abstract_table.send(:define_method, predicate_method) { self.class.send(predicate_method) }
            # class method
            inner_abstract_table.send(:define_singleton_method, predicate_method) { inner_abstract_table == outer_abstract_table }
          end
        end
        abstract_table
      end
    end
  end
end
