class ApplicationTestTaskAssistant
  class << self
    def root
      "#{Rails.root}/test"
    end

    def find_files(glob)
      regex = Regexp.new(glob || "")
      Dir["#{root}/**/*"].select { |file| file.remove(root) =~ regex }
    end

    def find_test_directory_files(glob)
      find_files(glob).select do |file|
        test_directories.any? { |directory| file.starts_with?(directory) }
      end.sort
    end

    def test_directory_names
      %w[ controllers integration mailers models system ]
    end

    def test_directories
      test_directory_names.map { |name| "#{root}/#{name}" }
    end
  end
end

namespace :tests do
  desc "Require lib directory"
  task :prepare do
    require "#{ApplicationTestTaskAssistant.root}/test_helper"
  end

  desc "Run all tests"
  task :run, :glob do |name, params|
    if !Rails.env.test?
      puts "Tests can only be run in the test environment: " + "RAILS_ENV=test rake tests".green
      exit!
    end
    if ENV["RESET"] == "true"
      Rake::Task["database:reset"].invoke
    end
    ENV["BROADCAST_TO_STDOUT"] = "false"
    Time.use_zone "UTC" do
      Rake::Task["app:load"].invoke
      Rake::Task["tests:prepare"].invoke
      # load test concerns
      ApplicationTestTaskAssistant.find_test_directory_files(/_test_concern\.rb\z/).each do |test_concern_file|
        require test_concern_file
      end
      # load tests
      ApplicationTestTaskAssistant.find_test_directory_files(params[:glob]).each do |test_file|
        require test_file if test_file.ends_with?("_test.rb")
      end
    end
  end
end
