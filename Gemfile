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

# assets
gem "sass-rails",   "~> 5.0"
gem "uglifier",     ">= 1.3.0"
gem "coffee-rails", "~> 4.2"
gem "turbolinks",   "~> 5"
gem "therubyracer", platforms: :ruby

# scheduler
gem "whenever"

group :development, :test do
  # firefly
  gem "listen"
  # tests
  gem "factory_girl"
  gem "minitest-reporters"
  gem "pry-rails"
  gem "byebug"
end
