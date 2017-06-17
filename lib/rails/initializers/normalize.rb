Rails.application.configure do
  # Session store
  #config.session_store :cookie_store, key: '_finalforms_session'
  #config.session_store :session #, key: 'testing_cookie', expire_after: 2.hours
  Rails.application.config.session_store(:active_record_store)
end

# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
# config.i18n.default_locale = false
I18n.enforce_available_locales = false

# Inflections
ActiveSupport::Inflector.inflections(:en) do |inflect|
  #inflect.acronym 'RESTful'
  #inflect.plural /^(ox)$/i, '\1en'
  #inflect.singular /^(ox)en/i, '\1'
  #inflect.irregular 'person', 'people'
  #inflect.uncountable %w( fish sheep )
  #inflect.plural 'coed', 'coed'
  #inflect.singular 'coed', 'coed'
  #inflect.singular 'data', 'data'
  #inflect.plural 'equipment', 'equipments'
end

# CSP-Report when we decide to implement it
Mime::Type.lookup_by_extension(:json).send("synonyms") << "application/csp-report"
