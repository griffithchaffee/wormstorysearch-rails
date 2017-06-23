class String

  def verify_in!(list, options = {})
    options = options.with_indifferent_access
    list = Array(list).flatten
    if self.in?(list)
      self
    else
      raise ArgumentError, "#{inspect} is not in the list #{list} #{options[:message]}".strip
    end
  end

  def verify_is!(value, options = {})
    options = options.with_indifferent_access
    if self == value.to_s
      self
    else
      raise ArgumentError, "#{inspect} expected to be #{value} #{options[:message]}".strip
    end
  end

  def to_dollars
    remove(/[^\d.]/).to_f
  end
  delegate :to_cents, to: :to_dollars

  def sql_quoted
    UmbrellaTable.connection.quote self
  end

  def sql_whitelist
    remove /[^-a-zA-Z0-9 ]/
  end

  def encode64(options = {})
    options = options.with_indifferent_access
    if options[:url]
      Base64.urlsafe_encode64 self
    else
      Base64.encode64 self
    end
  end

  def decode64(options = {})
    options = options.with_indifferent_access
    if options[:url]
      Base64.urlsafe_decode64 self
    else
      Base64.decode64 self
    end
  end

  def url_encode64(options = {})
    encode64 options.merge(url: true)
  end

  def url_decode64(options = {})
    decode64 options.merge(url: true)
  end

  def nameorize
    titleize.downcase
  end

  def to_name(options = {})
    options = options.with_indifferent_access
    result = self
    result = result.strip if options[:strip] != false
    result = result.remove(/('|")/) if options[:quotes] == true
    result = result.gsub(/ +/, " ") if options[:singlespaced] != false
    result
  end

  def to_queryable_s
    word_list_to_a.to_queryable_list
  end

  def to_ascii
    remove /[\u0080-\u00ff]/
  end

  def to_email
    remove(/\s/)
  end

  def to_adjusted_email
    to_email.downcase
  end

  def word_list_to_a
    split(/[,\s]+/).select(&:present?).map(&:strip)
  end

  def csv_to_a
    split(",").select(&:present?).map(&:strip)
  end

  def icsv_to_a
    csv_a = csv_to_a.map(&:strip)
    csv_a.map do |string_number|
      if string_number !~ /\A-?\d+\z/
        raise ArgumentError, "CSV #{self} value #{string_number.inspect} is not a valid integer"
      end
      string_number.to_i
    end
  end

  def key_value_to_h
    key_value_to_a.to_h.with_indifferent_access
  end

  def key_value_to_a
    csv_to_a.map do |key_and_value|
      key, value = key_and_value.split(":", 2)
      [key.strip, value.strip]
    end
  end

  def to_html
    gsub(/\r?\n/, "<br />").html_safe
  end

  def url_encode
    CGI.escape to_str
  end

  def url_decode
    CGI.unescape to_str
  end

  def escape_html
    CGI.escape_html to_str
  end

  def unescape_html
    CGI.unescape_html to_str
  end

  def escape_char(char)
    gsub(char) { "\\#{char}" }
  end

  def escape_single_quote
    escape_char "'"
  end

  def escape_double_quote
    escape_char '"'
  end

  def slugify
    scan(/[A-Za-z0-9]+/).join("_").underscore
  end

  def html_slugify
    slugify
  end

  def labelize
    strip.downcase.singularize.slugify
  end

  def lalign
    remove(/^ +/)
  end

  def to_multiline_s
    strip.remove(/^ +/)
  end

  def to_singleline_s
    strip.gsub(/ *\r?\n */, " ")
  end

  def unindent
    formatted = each_line.select(&:present?).join
    minindent = formatted.scan(/^ */).min_by { |line| line.length }
    gsub /^#{minindent}/, ""
  end

  def to_time_component
    if match(/\A[\d.]+(year|month|day|hour|minute|second)s?\z/)
      eval(self)
    else
      nil
    end
  end

  def regexp?
    start_with?("(?") && end_with?(")")
  end

  def to_regexp
    Regexp.new self
  end

  class << self
    def random_alphanumeric(size = 1)
      Array.new(size) { [*"0".."9", *"a".."z", *"A".."Z"].sample }.join
    end

    def random_alphanumeric_token
      random_alphanumeric 40
    end
  end
end
