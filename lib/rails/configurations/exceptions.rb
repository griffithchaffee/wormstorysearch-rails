Rails.application.configure do
  # allow rerouting of exceptions to controllers
  config.consider_all_requests_local = false
  config.action_dispatch.show_exceptions = true
  config.exceptions_app = -> (env) do
    catch_all_action = :catch_all
    exception        = env["action_dispatch.exception"]
    status_code      = ActionDispatch::ExceptionWrapper.new(env, exception).status_code
    rescue_action    = (ActionDispatch::ExceptionWrapper.rescue_responses[exception.class.name] || catch_all_action).to_s
    real_action      = (ErrorsController.action_methods.include?(rescue_action) ? rescue_action : catch_all_action).to_s
    original_exception = env["action_dispatch.exception"].try(:original_exception)
    env["HTTP_ACCEPT"] = "text/html"
    env["action_dispatch.exception.status_code"]   = status_code
    env["action_dispatch.exception.rescue_action"] = rescue_action
    env["action_dispatch.exception.real_action"]   = real_action
    begin
      skip_email = false
      # generic /etc/passwd scanning
      if exception.class.to_s == "ActionController::UnknownFormat"
        skip_email ||= "/etc/passwd".in?(exception.message)
      end
      # build skips
      case real_action
      when "not_found"
        skip_email ||= exception.class.to_s == "ActionController::RoutingError"
        # ignore /<model>/<id> exceptions
        if exception.class.to_s == "ActiveRecord::RecordNotFound"
          id    = exception.message.match(/'id'=(?<id>\d+)/).try(:[], :id)
          model = exception.message.match(/find (?<model>\w+) with/).try(:[], :model)
          skip_email ||= id && model && env["REQUEST_URI"].to_s.start_with?("/#{model.tableize}/#{id}")
        end
      when "internal_server_error"
        # ignore scanning for gifs and images
        if exception.class.to_s == "ActionView::MissingTemplate"
          skip_email ||= env["REQUEST_URI"] == "/"
        end
      when "catch_all"
        # ignore wrong formats (usually scanning)
        skip_email ||= exception.class.to_s == "ActionController::UnknownFormat"
      end
      if skip_email
        Rails.logger.warn { "ErrorsController [#{real_action.classify}]: #{exception.class}: #{exception.message}" }
      else
        subject        = "ErrorsController [#{real_action.classify}]: #{exception.class}: #{exception.message}".strip
        body           = "
          URL: #{env["HTTP_HOST"]}#{env["REQUEST_URI"]}
          Time: #{Time.zone.now}

          HOST: #{env["HTTP_HOST"]}
          URI: #{env["REQUEST_URI"]}
          METHOD: #{env["REQUEST_METHOD"]}
          USER AGENT: #{env["HTTP_USER_AGENT"]}
          REFERER: #{env["HTTP_REFERER"]}
          REMOTE IP: #{env["HTTP_X_FORWARDED_FOR"] || env["REMOTE_ADDR"]}
          #{"PARAMS:\n" + env["rack.input"].gets.to_s.unescape_html if env["REQUEST_METHOD"] != "GET"}

          STATUS: #{status_code}
          RESCUE: #{rescue_action}
          ACTION: #{real_action}

          Exception: #{exception.class}: #{exception.message}
          #{"Original: #{original_exception.class}: #{exception.message}" if original_exception}

          Backtrace:
          #{exception.backtrace.join("\n")}

        ".strip.gsub(/^ +/, "")
        if Rails.env.development?
          Rails.logger.error { "#{subject}\n#{body}" }
        else
          Rails.logger.error { "#{subject}\n#{body}" }
          begin
            DynamicMailer.email(subject: subject, body: body).deliver_now
          rescue StandardError => mailer_error
            Rails.logger.fatal { "MAILER: #{mailer_error.class}: #{mailer_error.message}\n#{mailer_error.backtrace.join("\n")}" }
          end
        end
      end
      ErrorsController.action(real_action).call env
    rescue StandardError => error
      subject        = "ExceptionsApp [#{error.class}]: #{error.message}".strip
      body           = "
        Time: #{Time.zone.now}

        HOST: #{env["HTTP_HOST"]}
        METHOD: #{env["REQUEST_METHOD"]}
        URI: #{env["REQUEST_URI"]}
        USER AGENT: #{env["HTTP_USER_AGENT"]}
        REFERER: #{env["HTTP_REFERER"]}
        REMOTE IP: #{env["HTTP_X_FORWARDED_FOR"] || env["REMOTE_ADDR"]}

        STATUS: #{status_code}
        RESCUE: #{rescue_action}
        ACTION: #{real_action}

        #{error.class}: #{error.message}

        #{exception.backtrace.join("\n")}
      ".strip.gsub(/^ +/, "")
      if Rails.env.development?
        Rails.logger.error { "#{exception.class}: #{exception.message}\n#{exception.backtrace.join("\n")}" }
      else
        Rails.logger.fatal { "#{subject}\n#{body}" }
        begin
          DynamicMailer.email(subject: subject, body: body).deliver_now
        rescue StandardError => mailer_error
          Rails.logger.fatal { "MAILER: #{mailer_error.class}: #{mailer_error.message}\n#{mailer_error.backtrace.join("\n")}" }
        end
      end
      ErrorsController.action(catch_all_action).call env
    end
  end
end
