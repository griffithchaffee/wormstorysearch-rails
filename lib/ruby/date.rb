[Time, DateTime, Date].each do |klass|
  klass.send(:define_method, "to_timestamp") { strftime "%Y-%m-%d %T" }
  klass.send(:define_method, "b_d_Y")   { strftime "%b %-d, %Y" }
  klass.send(:define_method, "B_d")     { strftime "%B %-d" }
  klass.send(:define_method, "b_d")     { strftime "%b %-d" }
  klass.send(:define_method, "m_d")     { strftime "%-m/%-d" }
  klass.send(:define_method, "m_d_y")   { strftime "%-m/%-d/%y" }
  klass.send(:define_method, "m_d_Y")   { strftime "%-m/%-d/%Y" }
  klass.send(:define_method, "zeroed_m_d_y")   { strftime "%m/%d/%y" }
  klass.send(:define_method, "zeroed_m_d_Y")   { strftime "%m/%d/%Y" }
  klass.send(:define_method, "l_M_p")   { strftime "%-l:%M %p" }
  klass.send(:define_method, "m_d_y_R") { strftime "%-m/%-d/%y %R" }
  klass.send(:define_method, "m_d_Y_H_M")   { strftime "%-m/%-d/%Y %-H:%M" }
  klass.send(:define_method, "m_d_y_l_M_p") { strftime "%-m/%-d/%y %-l:%M %p" }
  klass.send(:define_method, "b_d_Y_l_M_p") { strftime "%b %-d, %Y - %-l:%M %p" }
  klass.send(:define_method, "m_d_Y_l_M_p") { strftime "%-m/%-d/%Y - %-l:%M %p" }
  klass.send(:define_method, "friendly_m_d_Y") { today? ? "today" : m_d_Y }
  klass.send(:define_method, "friendly_b_d")   { today? ? "today" : b_d }
  klass.send(:define_method, "friendly_b_d_Y") { today? ? "today" : b_d_Y }
  klass.send(:define_method, "friendly_b_d_Y_l_M_p") do
    date = today? ? "today" : b_d_Y
    time = l_M_p
    "#{date} at #{time}"
  end
end

class Date
  delegate :to_i, to: :to_time

  class << self
    def epoch
      new(1970, 1, 1)
    end

    def today
      (Time.zone ? Time.zone.now : Time.use_zone(Rails.configuration.time_zone) { Time.zone.now }).to_date
    end

    def tomorrow
      today + 1.day
    end

    def yesterday
      today - 1.day
    end

    def strpfriendly(value)
      value = value.to_s.remove(/[^0-9\/]/)
      Date.strptime value, value =~ /\d{1,2}\/\d{1,2}\/\d{4}/ ? "%m/%d/%Y" : "%m/%d/%y"
    end
  end

  def change_if_lt(date_part, comparison, value = comparison)
    send(date_part) < comparison ? change(date_part => value) : self
  end

  def change_if_gt(date_part, comparison, value = comparison)
    send(date_part) > comparison ? change(date_part => value) : self
  end

  def to_h
    { year: year, month: month, day: day }
  end

  def years_ago
    today = Date.today
    years = today.year - year - (today.month < month || (today.month == month && today.day <= day) ? 1 : 0)
    years
  end

  def days_ago
    (Date.today - self).to_i
  end

  def years_from_now
    years_ago * -1
  end

  def days_from_now
    days_ago * -1
  end

  def filename
    strftime "%m_%d_%Y"
  end
end
