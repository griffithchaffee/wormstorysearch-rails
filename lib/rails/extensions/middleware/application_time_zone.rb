# silence logger for specific paths
module Rails.application.class::Middleware
  class ApplicationTimeZone
    def initialize(app)
      @app = app
      @cookie_name = "browser.identity"
      @cookie_key  = "time_zone_offset"
    end

    def call(env)
      # initial browser request will not have cookie set so will use default
      time_zone = Rails.configuration.time_zone
      begin
        # parse cookie
        cookies = ActionDispatch::Request.new(env).cookie_jar
        cookie_json = cookies[@cookie_name].presence || "{}"
        cookie = JSON.parse(cookie_json).with_indifferent_access
        if cookie.key?(@cookie_key)
          # determine time_zone from offset
          time_zone_offset = cookie[@cookie_key].to_i
          time_zone_hour_offset = time_zone_offset / 60
          time_zone_hour_offset =
            if time_zone_hour_offset < 0
              "#{time_zone_hour_offset}"
            elsif time_zone_hour_offset > 0
              "+#{time_zone_hour_offset}"
            end
          time_zone = Time.find_zone!("Etc/GMT#{time_zone_hour_offset}").name
        end
      rescue StandardError => error
        begin
          # log errors and email
          cookie_json      ||= nil
          time_zone_offset ||= nil
          subject = "ApplicationTimeZone #{error.class}: #{error.message}"
          body = "
            cookie_json: #{cookie_json.inspect}
            time_zone_offset: #{time_zone_offset.inspect}

            Error: #{error.class}
            Message: #{error.message}
            Backtrace:
            #{error.backtrace.join("\n")}
          ".strip.lalign
          Rails.logger.fatal { "#{subject}\n#{body}" }
          DynamicMailer.email(subject: subject, body: body).deliver_now
        rescue StandardError => email_error
          # email failed to deliver
          Rails.logger.fatal do
            "FATAL ApplicationTimeZone #{email_error.class}: #{email_error.message}\n#{email_error.backtrace.join("\n")}"
          end
        end
      end
      Time.use_zone(time_zone) do
        @app.call(env)
      end
    end
  end
end
