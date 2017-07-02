class Hash

  def with_strong_access
    ActionController::Parameters.new self
  end

  def to_struct
    Struct.new(*keys.map(&:to_sym)).new(*values)
  end

  def to_deep_struct
    transform_values do |value|
      value.is_a?(Hash) ? value.to_deep_struct : value
    end.to_struct
  end
end

class ActionController::Parameters
  def optional(key)
    value = self[key]
    value.present? || value == false ? value : self.class.new
  end
end
