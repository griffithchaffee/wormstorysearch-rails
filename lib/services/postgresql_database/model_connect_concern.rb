class Database
  module ModelConnectConcern
    extend ActiveSupport::Concern

    included do
      # rescueable finder error
      self.const_set(:NotFound, ActiveRecord::RecordNotFound)
      # autoassign defaults
      before_validation do
        # database defaults
        self.database_name = subdomain.underscore if !database_name? && subdomain?
        %w( database_host database_username database_password ).each do |attribute|
          send "#{attribute}=", self.class.default.send(attribute) if !send("#{attribute}?")
        end
        true
      end
      # class attribute used to store connected to record
      cattr_accessor :abstract_table
      cattr_accessor :database_configuration, instance_writer: false, instance_reader: false
      cattr_accessor :connected_to
      # setters
      self.abstract_table = "#{self}Table".constantize
      self.database_configuration = Database::Configuration.load_configuration_file("#{Rails.root}/config/databases/#{table_name}.yml.erb")
      self.database_configuration.reverse_merge!(Umbrella.application.database_configuration)
    end

    def database_configuration
      # use umbrella defaults with record specific overrides
      self.class.database_configuration.merge(
        host:     database_host,
        database: database_name,
        username: database_username,
        password: database_password,
      )
    end

    def database
      Database.new(self)
    end

    def rename_database!(new_database_name)
      update! database_name: new_database_name
      abstract_table.connection.execute "ALTER DATABASE #{database_name} RENAME TO #{new_database_name};"
      connect!
    end

    module ClassMethods
      def order_for_connect
        order(:subdomain)
      end

      def connected(options = {})
        options = options.with_indifferent_access
        records = order_for_connect.load
        records.each_with_index do |record, i|
          record.database.connect
          puts "#{Time.zone.now.to_timestamp} #{record.subdomain}: #{i + 1}/#{records.size}" if options[:log].present?
          yield record, { records: records, index: i }.with_indifferent_access
        end.size
      end

      def default_subdomain
        database_configuration.default_subdomain!
      end

      def default
        unscoped.find_by! subdomain: default_subdomain
      rescue ActiveRecord::RecordNotFound
        raise self::NotFound, "default #{self} [#{default_subdomain}] could not be found"
      rescue ActiveRecord::StatementInvalid => error
        if error.message.starts_with? "PG::UndefinedTable"
          raise ActiveRecord::NoDatabaseError, "database [#{database_configuration.database}] does not exist"
        else
          raise error
        end
      end

      def autocreate_params(subdomain)
        {}
      end

      def autocreate!(params = {})
        params = params.with_indifferent_access
        subdomain = params.fetch(:subdomain, default_subdomain)
        create! autocreate_params(subdomain).with_indifferent_access.reverse_merge(
          subdomain: subdomain,
          database_name: subdomain.underscore,
          database_host: database_configuration.host!,
          database_username: database_configuration.username!,
          database_password: database_configuration.password!,
        ).merge(params)
        unscoped.find_by! subdomain: subdomain
      end

      def connect_to(subdomain)
        record = find_by! subdomain: subdomain
        record.database.connect
        record
      end
    end
  end
end
