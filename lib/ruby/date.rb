[Time, DateTime, Date].each do |klass|
  klass.send(:define_method, "is_date?") { self.class == Date }
  klass.send(:define_method, "is_time?") { self.class.in?([Time, DateTime]) }
  klass.send(:define_method, "to_brief_human_s") do
    if today?
      is_date? ? "Today" : strftime("%-l:%M %p")
    else
      strftime(year == Date.today.year ? "%b %-d" : "%b %-d, %Y")
    end
  end
  klass.send(:define_method, "to_full_human_s") do
    if today?
      is_date? ? "Today" : "Today at #{strftime("%-l:%M %p")}"
    elsif year == Date.today.year
      is_date? ? strftime("%b %-d") : "#{strftime("%b %-d")} at #{strftime("%-l:%M %p")}"
    else
      is_date? ? strftime("%b %-d, %Y") : "#{strftime("%b %-d, %Y")} at #{strftime("%-l:%M %p")}"
    end
  end

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
  klass.send(:define_method, "friendly_b_d_l_M_p") { "#{today? ? "today" : b_d} at #{l_M_p}" }
  klass.send(:define_method, "friendly_b_d_Y_l_M_p") { "#{today? ? "today" : b_d_Y} at #{l_M_p}" }
end

class Date
  delegate :to_i, to: :to_time

  class << self
    def today
      (Time.zone ? Time.zone.now : Time.use_zone(Rails.configuration.time_zone) { Time.zone.now }).to_date
    end
  end
end
