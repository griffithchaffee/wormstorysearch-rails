Rails.application.configure do
  # Session store
  config.session_store(:session, key: "testing_cookie", expire_after: 1.hour)
end

# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
# config.i18n.load_path += Dir[Rails.root.join("my", "locales", "*.{rb,yml}").to_s]
# config.i18n.default_locale = false
I18n.enforce_available_locales = false

# Inflections
ActiveSupport::Inflector.inflections(:en) do |inflect|
  #inflect.acronym "RESTful"
  #inflect.plural /^(ox)$/i, "\1en"
  #inflect.singular /^(ox)en/i, "\1"
  #inflect.irregular "person", "people"
  #inflect.uncountable %w( fish sheep )
  #inflect.plural "coed", "coed"
  #inflect.singular "coed", "coed"
end

# CSP-Report when we decide to implement it
Mime::Type.lookup_by_extension(:json).send("synonyms") << "application/csp-report"

# skip logging of unpermitted parameter notifications due to verbosity
ActiveSupport::Notifications.unsubscribe("unpermitted_parameters.action_controller")




#Rails.application.assets.logger = Logger.new '/dev/null'
#Rails.application.configure do
  #config.assets.logger = Logger.new("/dev/null")
#end
