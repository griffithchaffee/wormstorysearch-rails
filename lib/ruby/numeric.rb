class Numeric
  def min(min)
    self < min ? min : self
  end

  def max(max)
    self > max ? max : self
  end

  def min_max(min, max)
    min(min).max(max)
  end

  def percent(percentage)
    to_f * percentage.to_f / 100.0
  end

  def to_delimited_s
    to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1,").reverse
  end

  def to_filesize
    {
      "B"  => 1024,
      "KB" => 1024 * 1024,
      "MB" => 1024 * 1024 * 1024,
      "GB" => 1024 * 1024 * 1024 * 1024,
      "TB" => 1024 * 1024 * 1024 * 1024 * 1024
    }.each_pair { |e, s| return "#{(self.to_f / (s / 1024)).round(2)}#{e}" if self < s }
  end

  def to_timer_result
    Time.at(self).utc.strftime("%H:%M:%S").remove(/\A00:/)
  end
end

class Float
  def to_dollars
    round 2
  end

  def to_dollar_s
    "%.2f" % to_dollars
  end

  def to_dollar_amount
    to_dollar_s.gsub(/\A(-)?/, "\\1$")
  end

  def to_delimited_dollar_amount
    to_dollar_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1,").reverse.gsub(/\A(-)?/, "\\1$")
  end

  def to_cents
    (self * 100).to_i
  end
end

class Integer
  def to_dollars
    (self / 100.to_f).to_dollars
  end

  delegate :to_dollar_s, :to_dollar_amount, :to_delimited_dollar_amount, to: :to_dollars
end
