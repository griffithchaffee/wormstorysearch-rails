class String
  def slugify
    scan(/[A-Za-z0-9]+/).join("_").underscore
  end

  def normalize
    strip.squeeze(" ")
  end

  def lalign
    remove(/^ +/)
  end

  def human_size_to_i
    case self
    # 123, 123.5
    when /\A\d+(\.\d+)?\z/   then self
    # 1.1K, 1.25k
    when /\A\d+(\.\d+)?k\z/i then self.remove(/[^\d.]/).to_f * 1_000
    # 1.1M, 1.25m
    when /\A\d+(\.\d+)?m\z/i then self.remove(/[^\d.]/).to_f * 1_000_000
    end.to_i
  end

  def verify_in!(list, options = {})
    options = options.with_indifferent_access
    list = Array(list).flatten
    if self.in?(list)
      self
    elsif list.size == 1
      raise ArgumentError, "#{inspect} expected to be #{list.first} #{options[:message]}".strip
    else
      raise ArgumentError, "#{inspect} is not in the list #{list} #{options[:message]}".strip
    end
  end
  alias_method :verify_is!, :verify_in!

  def escape_html
    CGI.escape_html(to_str)
  end

end
