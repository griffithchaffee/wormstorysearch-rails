require File.expand_path("../../config/environment", __FILE__)

require "rails/test_help"
#require "minitest/reporters"
require "factory_girl"
FactoryGirl.find_definitions

require_relative "lib/application_test_concern"
require_relative "lib/application_record_test_case"
require_relative "lib/application_controller_test_case"
require_relative "lib/minitest_pretty_reporter"
Minitest::Reporters.use!(Minitest::Reporters::SuiteReporter.new)
