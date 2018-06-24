source "https://rubygems.org"

ruby "2.4.1", patchlevel: "111"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# core
gem "rails", "~> 5.1.1"
gem "pg",    "~> 0.21", platforms: :ruby
gem "puma",  "~> 3.7"
gem "unicorn"
gem "colored"
gem "action_presenter-base", "= 0.1"

# assets
gem "sass-rails"#,   "~> 5.0"
gem "uglifier"#,     ">= 1.3.0"
gem "coffee-rails"#, "~> 4.2"
gem "turbolinks"#,   "~> 5"
gem "therubyracer", platforms: :ruby

# scheduler
gem "whenever"

# crawler
gem "loofah"
gem "faraday"
gem "http-cookie"

group :development, :test do
  # firefly
  gem "firefly_server"#, path: "/root/griffithchaffee/firefly_server"
  # tests
  gem "factory_bot"
  gem "minitest-reporters"
  gem "byebug"
  gem "database_cleaner"
  # system tests
  #gem "capybara", "~> 2.14"
  #gem "selenium-webdriver", "~> 3.4"
  # https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit
  #gem "capybara-webkit" # dnf install qt5-qtwebkit-devel
end
