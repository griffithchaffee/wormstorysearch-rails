module ActiveModel
  class Errors
    alias_method :_original_full_message, :full_message

    def full_message(attribute, message)
      message.strip.starts_with?('^') ? message.strip.gsub(/\A\^+/, '') : _original_full_message(attribute, message.strip)
    end
  end
end
