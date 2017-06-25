class ApplicationTestTaskAssistant
  class << self
    def root
      "#{Rails.root}/test"
    end

    def find_files(glob)
      regex = Regexp.new(glob || "")
      Dir["#{root}/**/*"].select { |file| file.remove(root) =~ regex }
    end

    def find_test_files(glob)
      find_files(glob).select do |file|
        next if test_directories.none? { |directory| file.starts_with?(directory) }
        file.ends_with?("_test.rb")
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
    Time.use_zone "UTC" do
      ENV["BROADCAST_TO_STDOUT"] = "false"
      Rake::Task["app:load"].invoke
      Rake::Task["tests:prepare"].invoke
      ApplicationTestTaskAssistant.find_test_files(params[:glob]).each do |path|
        require path
      end
    end
  end
end
