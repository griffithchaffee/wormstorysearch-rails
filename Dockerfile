FROM ruby:2.7.8
RUN gem install bundler -v 2.3.18
WORKDIR /wormstorysearch
RUN apt-get update
RUN apt-get install -y \
  #libv8-dev 
  clang
COPY ./Gemfile ./Gemfile* ./
#COPY . .
#RUN bundle config build.nokogiri set force_ruby_platform true
  #RUN bundle config build.nokogiri --use-system-libraries
#RUN gem install libv8 -- --with-system-v8
#RUN gem install nokogiri --platform=ruby -v 1.13.10
RUN bundle check || bundle install
COPY . .
EXPOSE 8080
#CMD bundle exec rails s -b 0.0.0.0
CMD bundle exec ./bin/firefly_server
