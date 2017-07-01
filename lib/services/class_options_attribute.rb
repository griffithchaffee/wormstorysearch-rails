module ClassOptionsAttribute
  def class_options_attribute(name, options = {})
    options = options.with_indifferent_access
    # class definition
    define_singleton_method(name) do
      variable = "@#{name}"
      instance_variable_get(variable) || instance_variable_set(variable, ActiveSupport::OrderedOptions.new)
    end
    # instance accessor
    if options[:instance_accessor] != false
      define_method(name) { self.class.send(name) }
    end
  end

  def class_constant(name, value)
    class_options_attribute(:const) if !respond_to?(:const)
    self.const.send("#{name}=", value)
    raise ArgumentError, "class_constant does not accept a block" if block_given?
    value
  end

  def class_constant_builder(name, *params)
    class_options_attribute(:const) if !respond_to?(:const)
    new_const = ClassConstant.new(name, *params)
    self.const.send("#{name}=", new_const)
    yield new_const if block_given?
    new_const
  end

  class ClassConstant
    include Enumerable

    def initialize(name, keys)
      @name = name
      @keys = keys.map(&:to_sym)
      @added = []
    end

    # fetch by hash or primary key
    def with(finder)
      if finder.is_a?(Hash)
        select { |value| value.to_h.slice(*finder.keys.map(&:to_sym)).sort == finder.sort }
      else
        select { |value| value[@keys.first] == finder }
      end
    end

    def fetch(finder)
      with(finder).first
    end

    def fetch!(finder)
      value = fetch(finder)
      raise ArgumentError, "no #{@name} found with: #{finder}" if value.blank?
      raise ArgumentError, "multiple #{@name} found with: #{finder}" if value.size > 1
      value
    end

    def add(new_value)
      new_value = new_value.symbolize_keys
      missing_keys = @keys - new_value.keys
      extra_keys   = new_value.keys - @keys
      raise ArgumentError, "#{@name} constant missing keys: #{missing_keys}" if missing_keys.any?
      raise ArgumentError, "#{@name} constant extra keys: #{extra_keys}" if extra_keys.any?
      new_value = Struct.new(*@keys).new(*@keys.map { |key| new_value[key] })
      @added << new_value
    end

    delegate(:each, to: :@added)
  end
end
