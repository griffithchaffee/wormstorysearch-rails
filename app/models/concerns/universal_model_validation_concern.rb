module UniversalModelValidationConcern
  extend ActiveSupport::Concern

  module ClassMethods
    def validates_presence_of_required_columns(options = {})
      options = options.with_indifferent_access
      # excluded columns
      exclude_columns = Array(options[:exclude]).map(&:to_s) + %w[ id updated_at created_at ]
      raw_columns = Array(options[:raw]).map(&:to_s)
      columns.get_all(null: false).each do |column|
        presence_validation = options[column.name].to_h.deep_symbolize_keys
        # skip excluded columns
        next if column.name.in?(exclude_columns)
        # boolean attribute
        if column.type == :boolean
          # booleans can only be true or false
          validates_is_boolean(column.name.to_sym, presence_validation)
        # integer attribute
        elsif column.type == :integer
          # integers can be zero and numericality should be used to validate otherwise
          validates_is_not_nil(column.name.to_sym, presence_validation)
        # belongs_to attribute
        elsif column.name.ends_with?("_id") && reflect_on_association(column.name.remove(/_id\z/)) && column.name.not_in?(raw_columns)
          association = column.name.remove(/_id\z/).to_sym
          # association message anchored for has_many through
          presence_validation.reverse_merge!(message: "^#{association.to_s.classify} can't be blank")
          validates(association, presence: presence_validation)
          # move validation errors to column for form field highlighting
          after_validation do
            errors[association].each { |message| errors.add(column.name, message) if message.not_in?(errors[column.name]) }
            errors.delete(association)
          end
        # polymorphic type attribute - skipped because id column performs validation
        elsif column.name.ends_with?("_type") && columns.get(null: false, name: column.name.gsub("_type", "_id")).present?
          next
        else
          # default presence validation
          validates(column.name.to_sym, presence: presence_validation)
        end
      end
    end

    def validates_is_boolean(attribute, validation = {})
      validation = validation.symbolize_keys.reverse_merge(
        in: [true, false],
        message: "must be true or false"
      )
      validates attribute, inclusion: validation.to_h
    end

    def validates_is_not_nil(attribute, validation = {})
      validation = validation.symbolize_keys.reverse_merge(
        in: [nil],
        message: "can't be blank"
      )
      validates attribute, exclusion: validation.to_h
    end

    def validates_uniqueness_scope(attribute, scope, validation = {})
      scopes = Array(scope).map { |scope| scope.to_s.remove(/_(id|type)\z/).nameorize }.uniq
      validation = validation.symbolize_keys.reverse_merge(
        scope: scope,
        message: "can't be used because one already exists for this #{scopes.to_and_s}"
      )
      validates attribute, uniqueness: validation
    end

    def validates_in_list(attribute, list, validation = {})
      raise ArgumentError, "unknown #{self} attribute #{attribute}" if columns.get(name: attribute.to_s).blank?
      validation = validation.symbolize_keys.reverse_merge(
        if: columns.get(name: attribute.to_s).type == :integer ? -> { !send(attribute).nil? } : "#{attribute}?".to_sym
      )
      if list.is_a? Array
        validation.reverse_merge! in: list, message: -> (key, attribute) { "value #{attribute[:value].inspect} is not included in the list: [#{list.to_or_s}]" }
        validates attribute, inclusion: validation
      else
        validate do
          if validation[:if].is_a?(Proc) ? instance_exec(&validation[:if]) : send(validation[:if])
            valid_list = list.is_a?(Proc) ? instance_exec(&list) : send(list)
            if send(attribute).not_in? valid_list
              errors.add attribute, "value #{send(attribute).inspect} is not included in the list: [#{valid_list.to_or_s}]"
            end
          end
        end
      end
    end

    def validates_format(attribute, validation = {})
      validation = validation.symbolize_keys.reverse_merge(
        with: constant.validators.get(name: attribute.to_s).validator,
        message: "is not in the correct format",
        if: "#{attribute}?".to_sym
      )
      validates attribute, format: validation
    end

  end
end
