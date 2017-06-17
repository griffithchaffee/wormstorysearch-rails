class Hash
  def select_present
    select { |k,v| v.present? }
  end

  def with_strong_access
    ActionController::Parameters.new(self)
  end

  def to_struct
    Struct.new(*keys.map(&:to_sym)).new(*values)
  end

  def to_ostruct
    OpenStruct.new(self)
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
    hash.with_strong_access.permit!.merge(self)
  end
end
