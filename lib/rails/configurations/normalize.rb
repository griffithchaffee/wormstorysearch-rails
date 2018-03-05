Rails.application.configure do
  # general
  config.colorize_logging = false
  config.eager_load = true
  config.cache_classes = true
  config.active_record.belongs_to_required_by_default = false

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
  # time_zone automatically set each request
  # config.time_zone = "UTC"

  # using UTC would require updating profile on locations so scraper parsed times are correct
  config.time_zone = "Pacific Time (US & Canada)"

  # used bust cached assets
  config.assets.version = Rails.application.settings.version
  config.assets.cache = ActiveSupport::Cache.lookup_store(:null_store)
  # debug does not concat assets
  config.assets.debug = false

  # precompile css/js assets
  config.assets.precompile = %w[
    application.scss
    application.coffee
  ]

  # precompile non css/js assets
  precompile_proc = -> (path, fullpath) { path !~ /\.(js|coffee|css|scss|less)\z/ }
  config.assets.precompile << precompile_proc

  # session
  config.session_store :identity_session_store, key: "_identity_session_id"
end
