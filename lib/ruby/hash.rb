class Hash

  def select_present
    select { |k,v| v.present? }
  end

  def reordered_deep_merge!(other_hash, &block)
    this_copy = dup
    both_keys = (keys + other_hash.keys).reverse.uniq.reverse
    clear
    both_keys.each do |key|
      this_value = this_copy[key]
      other_value = other_hash[key]
      if other_value.is_a?(Hash) && this_value.is_a?(Hash)
        other_value = this_value.reordered_deep_merge other_value
      end
      self[key] = other_hash.key?(key) ? other_value : this_value
    end
    self
  end

  def reordered_deep_merge(other_hash, &block)
    dup.reordered_deep_merge! other_hash, &block
  end

  def deep_reverse_merge!(other_hash)
    result = deep_reverse_merge other_hash
    clear
    merge! result
  end

  def deep_reverse_merge(other_hash)
    other_hash.deep_merge self
  end

  def to_pretty_s
    map do |key, value|
      "#{key}=#{value}"
    end.join " "
  end

  def with_strong_access
    ActionController::Parameters.new self
  end

  def to_struct
    Struct.new(*keys.map(&:to_sym)).new(*values)
  end

  def to_ostruct
    OpenStruct.new self
  end

  def to_key_value_a
    map { |k,v| "#{k}:#{v}" }
  end

  def with_method_access
    HashWithMethodAccess.new self
  end

  def dig_html(name)
    # "key1[key2][key3][]" -> ["key1", "key2", "key3"]
    parts = name.to_s.split /\]\[|\[\]?|\]/
    parts.present? ? dig(*parts) : nil
  end

  def dig_fetch(key, *rest)
    value = fetch key
    if rest.blank?
      value
    else
      value.dig_fetch *rest
    end
  end

  def fetch_or_raise(key, message)
    fetch(key)
  rescue KeyError
    raise KeyError, message
  end
end

class ActionController::Parameters
  def reverse_merge(hash)
    hash.with_strong_access.permit!.merge self
  end

  def optional(key)
    value = self[key]
    if value.present? || value == false
      value
    else
      self.class.new
    end
  end
end
