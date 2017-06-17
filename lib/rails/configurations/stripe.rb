{
  # test
  api_test_secret_key: "sk_test_W7c7bGK2ryU0DaWfPQMLEeGx",
  api_test_public_key: "pk_test_A5eO8oiFCZAEIfq3idFRmkC7",
  api_test_client_key: "ca_Ab2KpBU1ux5CSQjypCu74bsbMvVaXIqX",
  # live
  api_live_secret_key: "sk_live_avBoPtgf1SJVeajI3eKjJxn6",
  api_live_public_key: "pk_live_Pp8IVl1Eeu5uGFOf87SBAsQ2",
  api_live_client_key: "ca_Ab2KivpJgX4JLND5CTf6tlQYUmjy2Sfr",
  # oauth
  api_oauth2_options: {
    site: "https://connect.stripe.com",
    authorize_url: "/oauth/authorize",
    token_url: "/oauth/token"
  },
  platform_account_id: "acct_1AANA6HlpGcWFqwT",
  demo_account_id: "acct_1AKxPoEkwAbIT3f0"
}.each do |key, value|
  Stripe.class_variable_set("@@#{key}", value)
  Stripe.mattr_reader(key)
end
Stripe.send(:define_singleton_method, :modes) { %w[ live test ] }
Stripe.send(:define_singleton_method, "processing?") { api_key.in?([api_live_secret_key, api_test_secret_key]) }

# WARNING: when changing version, be sure to check if stripe script tag needs to be updated in layouts/universal
# https://stripe.com/docs/stripe.js
Stripe.api_version = "2017-04-06"
Stripe.api_key = nil

# key accessor methods designed to be called in a process block
%w[ client_key public_key secret_key ].each do |key|
  Stripe.send(:define_singleton_method, "api_#{key}") do
    # api_key set using Stripe.process
    raise ArgumentError, "Stripe keys must be called in a Stripe.process block" if !processing?
    mode = api_key == api_live_secret_key ? "live" : "test"
    send("api_#{mode}_#{key}")
  end
end

# set api_key to a mode
Stripe.send(:define_singleton_method, :process) do |mode = Organization.connected_to.stripe_mode, &block|
  # verify mode
  raise ArgumentError, "Stripe mode must be #{modes.to_or_s}" if mode.not_in?(modes)
  # force test mode when not in production
  if !Rails.env.production? && mode == "live"
    Rails.logger.warn("Stripe mode overridden to test when not in production")
    mode = "test"
  end
  # set api_key
  begin
    self.api_key = send("api_#{mode}_secret_key")
    block.call
  ensure
    self.api_key = nil
  end
end
