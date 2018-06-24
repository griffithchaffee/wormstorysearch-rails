require File.expand_path("../../config/environment", __FILE__)

require "rails/test_help"
require "factory_bot"
FactoryBot.find_definitions

require_relative "lib/application_test_concern"
require_relative "lib/application_test_case"
require_relative "lib/application_record_test_case"
require_relative "lib/application_controller_test_case"
require_relative "lib/application_integration_test_case"
require_relative "lib/application_minitest_reporter"
Minitest::Reporters.use!(Minitest::Reporters::ApplicationReporter.new)

# prepare database
DatabaseCleaner.clean_with(:truncation)
