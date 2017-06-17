module ActionController
  class Parameters
    def optional(key)
      value = self[key]
      if value.present? || value == false
        value
      else
        self.class.new
      end
    end
  end
end
