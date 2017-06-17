require "csv"      # Importer/Exporter
require "open-uri" # PDFDocument

Rails.application.configure do
  # general
  config.colorize_logging = false
  config.eager_load = true
  config.cache_classes = true

  # used bust cached assets
  config.assets.version = Finalforms.version

  # include css/js manifest files
  config.assets.precompile = %w[
    universal.css
    iepatch.css

    vendor.js
    finalforms.js
    iepatch.js
  ]

  # ignore css/js assets since manifest files include handle them
  config.assets.precompile << Proc.new { |path, fullpath| path !~ /(js|css|less|coffee)\z/ }
  config.assets.cache = ActiveSupport::Cache.lookup_store(:null_store)

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
  config.time_zone = "Eastern Time (US & Canada)"

  # Your secret key is used for verifying the integrity of signed cookies.
  # If you change this key, all old signed cookies will become invalid!
  # Make sure the secret is at least 30 characters and all random.
  # You can use `rake secret` to generate a secure secret key.
  # Make sure your secret_key_base is kept private
  config.secret_key_base = "c25586dba719b2b942cae579240b4774926eaccce030a52f4d8eb94b47b861457545da55582bf3e16097b93ac1de2a73463b5b17e3fe4975d36e0063b47276fd"
end
