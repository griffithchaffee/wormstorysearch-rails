source "https://rubygems.org"

ruby "2.7.8"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# core
gem "rails", "~> 5.1.6"
gem "pg", platforms: :ruby
gem "puma"
gem "unicorn"
gem "colored"
gem "action_presenter-base", "= 0.1"
gem "sprockets", "= 3.7.2"

# assets
gem "sassc-rails"
gem "uglifier"
gem "coffee-rails"
gem "turbolinks"
#gem "therubyracer", platforms: :ruby
gem "mini_racer"

# scheduler
gem "whenever"

# crawler
gem "loofah"
gem "faraday"
gem "faraday_middleware"
gem "http-cookie"
gem "byebug"

group :development, :test do
  # firefly
  gem "firefly_server"#, path: "/root/griffithchaffee/firefly_server"
  # tests
  gem "factory_bot", "= 6.2.1"
  gem "minitest-reporters"
  gem "byebug"
  gem "database_cleaner"
  # system tests
  #gem "capybara", "~> 2.14"
  #gem "selenium-webdriver", "~> 3.4"
  # https://github.com/thoughtbot/capybara-webkit/wiki/Installing-Qt-and-compiling-capybara-webkit
  #gem "capybara-webkit" # dnf install qt5-qtwebkit-devel
end
