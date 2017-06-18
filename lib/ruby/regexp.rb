class Regexp
  def to_javascript(options = nil)
    Regexp.new(
      inspect.
      sub('\\A' , '^').
      sub('\\Z' , '$').
      sub('\\z' , '$').
      sub(/^\// , '').
      sub(/\/[a-z]*$/ , '').
      gsub(/\(\?#.+\)/ , '').
      gsub(/\(\?-\w+:/ , '(').
      gsub(/\s/ , ''),
      self.options & 5
    ).inspect
  end
end
