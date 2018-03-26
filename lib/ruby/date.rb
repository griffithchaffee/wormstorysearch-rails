[Time, DateTime, Date].each do |klass|
  klass.send(:define_method, "is_date?") { self.class == Date }
  klass.send(:define_method, "is_time?") { self.class.in?([Time, DateTime]) }
  # duplicate logic in app/assets/javascripts/lib/time.coffee
  klass.send(:define_method, "to_calendar_brief_s") do |full_month: false|
    strfmonth = full_month ? "%B" : "#{strfmonth}"
    if today?
      is_date? ? "Today" : strftime("%-l:%M %p")
    else
      strftime(year == Date.today.year ? "#{strfmonth} %-d" : "#{strfmonth} %-d, %Y")
    end
  end
  # duplicate logic in app/assets/javascripts/lib/time.coffee
  klass.send(:define_method, "to_calendar_full_s") do |full_month: false|
    strfmonth = full_month ? "%B" : "#{strfmonth}"
    if today?
      is_date? ? "Today" : "Today at #{strftime("%-l:%M %p")}"
    elsif year == Date.today.year
      is_date? ? strftime("#{strfmonth} %-d") : "#{strftime("#{strfmonth} %-d")} at #{strftime("%-l:%M %p")}"
    else
      is_date? ? strftime("#{strfmonth} %-d, %Y") : "#{strftime("#{strfmonth} %-d, %Y")} at #{strftime("%-l:%M %p")}"
    end
  end
  # custom formatters
  klass.send(:define_method, "to_timestamp") { strftime "%Y-%m-%d %T" }
end

class Date
  delegate :to_i, to: :to_time

  class << self
    def today
      (Time.zone ? Time.zone.now : Time.use_zone(Rails.configuration.time_zone) { Time.zone.now }).to_date
    end

    def smart_parse(date)
      attempt_parse = -> (parse_date, parse_format) do
        begin
          DateTime.strptime(parse_date, parse_format).to_date
        rescue ArgumentError
        end
      end
      # m/d/y
      if date =~ /\A\d{1,2}\/\d{1,2}\/\d{2}\z/
        attempt_parse.call(date, "%m/%d/%y")
      # m/d/Y
      elsif date =~ /\A\d{1,2}\/\d{1,2}\/\d{4}\z/
        attempt_parse.call(date, "%m/%d/%Y")
      # Y-m-d
      elsif date =~ /\A\d{4}-\d{1,2}-\d{1,2}\z/
        attempt_parse.call(date, "%Y-%m-%d")
      # m/d
      elsif date =~ /\A\d{1,2}\/\d{1,2}\z/
        result = attempt_parse.call("#{date}/#{Date.today.year}", "%m/%d/%Y")
        result = result - 1.year if result > Date.today
        result
      end
    end
  end
end

class DateTime
  class << self
    def smart_parse(datetime)
      attempt_parse = -> (parse_datetime, parse_format) do
        begin
          DateTime.strptime(parse_datetime, parse_format)
        rescue ArgumentError
        end
      end
      # m/d/y H:M
      if datetime =~ /\A\d{1,2}\/\d{1,2}\/\d{2} \d{1,2}:\d{1,2}\z/
        attempt_parse.call(datetime, "%m/%d/%y %H:%M")
      # m/d/Y H:M
      elsif datetime =~ /\A\d{1,2}\/\d{1,2}\/\d{4} \d{1,2}:\d{1,2}\z/
        attempt_parse.call(datetime, "%m/%d/%Y %H:%M")
      # Y-m-d H:M
      elsif datetime =~ /\A\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}\z/
        attempt_parse.call(datetime, "%Y-%m-%d %H:%M")
      # Y-m-d H:M:S
      elsif datetime =~ /\A\d{4}-\d{1,2}-\d{1,2} \d{1,2}:\d{1,2}:\d{1,2}\z/
        attempt_parse.call(datetime, "%Y-%m-%d %H:%M:%S")
      # default "2017-12-22T08:37:05-07:00"
      elsif datetime =~ /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[-+]\d{2}:\d{2}\z/
        attempt_parse.call(datetime, "%Y-%m-%dT%H:%M:%S%:z")
      end
    end
  end
end

