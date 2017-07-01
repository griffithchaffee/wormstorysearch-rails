class SiteCrawler
  attr_reader :responses, :site_url, :cookie_jar
  attr_writer :logger

  def initialize(site_url, options = {})
    options = options.with_indifferent_access
    @site_url = site_url
    @cookie_jar = options[:cookie_jar] || HTTP::CookieJar.new
    load_cookies(options[:cookies]) if options[:cookies]
    @responses = []
  end

  def logger
    @logger ||= Rails.logger
  end

  def site(options = {}, &block)
    options = options.with_indifferent_access
    builder = -> (&rack_block) do
      Faraday.new(site_url) do |rack|
        # url encode post data
        rack_block.call(rack) if rack_block
        rack.request :url_encoded
        rack.use CookieManager, self
        rack.use RequestLogger, self
        rack.adapter Faraday.default_adapter
      end
    end
    if block
      builder.call(&block)
    elsif options[:multipart]
      builder.call { |rack| rack.request :multipart }
    else
      builder.call
    end
  end

  def dump_cookies
    cookies = StringIO.new
    cookie_jar.save cookies, format: :yaml, session: true
    cookies.string
  end

  def load_cookies(cookies)
    cookie_jar.load StringIO.new(cookies), format: :yaml, session: true
  end

  def get(path, params = {}, options = {}, &block)
    prepare_request
    options = options.with_indifferent_access.reverse_merge redirect_limit: 5
    headers = options.delete(:headers).to_h.with_indifferent_access
    logger.silence(options[:log_level] || logger.level) do
      responses.push site.get(path, params, headers, &block)
    end
    if options[:json] == true
      headers["Accept"] ||= "application/json"
    end
    if options[:follow_redirects] == true && response.status.in?([301, 302, 303])
      raise RedirectLimit, "redirect limit reached" if options[:redirect_limit] == 0
      get response.headers["Location"], {}, follow_redirects: true, redirect_limit: options[:redirect_limit] - 1
    end
    response.status
  end

  def post(path, params = {}, options = {}, &block)
    prepare_request
    options = options.with_indifferent_access
    headers = options.delete(:headers).to_h.with_indifferent_access
    logger.silence(options[:log_level] || logger.level) do
      if options[:json] == true
        headers["Content-Type"] ||= "application/json"
        headers["Accept"] ||= "application/json"
        json = params.is_a?(Hash) ? params.to_json : params
        responses.push site.post(path, json, headers, &block)
      elsif options[:multipart] == true
        responses.push site(multipart: true).post(path, params, headers, &block)
      else
        responses.push site.post(path, params, headers, &block)
      end
      if options[:follow_redirects] == true && response.status.in?([301, 302, 303])
        get response.headers["Location"], {}, follow_redirects: true
      end
    end
    response.status
  end

  def reset
    @responses.clear
    @html = nil
    @javascript = nil
  end

  def prepare_request
    @html = nil
    @javascript = nil
  end

  def response
    @responses.last
  end

  def javascript
    @javascript ||= JavascriptParser.new
  end

  class JavascriptParser
    attr_reader :window

    def initialize
      @window = V8::Context.new
    end

    def eval(js)
      window.eval js
    end

    def load_js_file(js_file)
      window.load js_file
      self
    end
  end

  def html
    @html ||= HtmlParser.new response.body
  end

  def html!(body)
    @html = HtmlParser.new body
  end

  def html_fragment(*params)
    HtmlFragmentParser.new response.body[*params]
  end

  def html_fragment!(fragment)
    HtmlFragmentParser.new fragment
  end

  class HtmlParser
    attr_reader :document
    attr_accessor :selection
    delegate :to_s, :text, to: :document

    def initialize(html)
      @html = html
      parse @html
      find_all("script").remove
      find_all("link").remove
    end

    def find_all(selector)
      self.selection = document.css(selector)
    end

    def find(selector)
      self.selection = find_all(selector).first
    end

    def text
      document.text
    end

    def reset
      parse @html
    end

    def parse(html)
      @document = Nokogiri::HTML html
    end
  end

  class HtmlFragmentParser
    attr_reader :fragment
    attr_accessor :selection
    delegate :to_s, :text, to: :fragment

    def initialize(fragment)
      @fragment = fragment
      parse @fragment
    end

    def find_all(selector)
      self.selection = fragment.css(selector)
    end

    def find(selector)
      self.selection = find_all(selector).first
    end

    def reset
      parse @fragment
    end

    def parse(fragment)
      @fragment = Nokogiri::HTML::fragment fragment
    end
  end

  class CookieManager < Faraday::Middleware
    def initialize(app, crawler)
      super(app)
      @crawler = crawler
    end

    def call(env)
      url = env[:url]
      cookies = @crawler.cookie_jar.cookies url
      # set request cookie
      if cookies.present?
        request_cookie = HTTP::Cookie.cookie_value cookies
        headers = env[:request_headers]
        if headers["Cookie"].present? && headers["Cookie"] != request_cookie
          headers["Cookie"] = request_cookie + ';' + headers["Cookie"]
        else
          headers["Cookie"] = request_cookie
        end
      end

      # store response cookie
      @app.call(env).on_complete do |res|
        headers = res[:response_headers]
        if headers.present?
          if set_cookie = headers["Set-Cookie"]
            @crawler.cookie_jar.parse set_cookie, url
          end
        end
      end
    end
  end

  class RequestLogger < Faraday::Middleware
    def initialize(app, crawler)
      super(app)
      @logger = crawler.logger
    end

    def call(env)
      started_at = Time.now.utc
      @logger.info("Crawler Started #{env[:method].to_s.upcase} #{env[:url]}")
      @logger.debug("Crawler[Request] Headers: #{env[:request_headers]}")
      if env[:body].is_a? Faraday::CompositeReadIO
        parts = env[:body].instance_variable_get(:@parts).map { |part| part.instance_variable_get :@part }
        parts.unshift "\n" if parts.present?
        @logger.debug("Crawler[Request] Body: #{parts.join("\n").inspect}")
      elsif env[:body].present?
        @logger.debug("Crawler[Request] Body: #{env[:body]}") if env[:body].present?
      end
      @app.call(env).on_complete do |res|
        finished_at = Time.now.utc
        total_ms = ((finished_at.to_f - started_at.to_f) * 1000).to_i
        @logger.debug("Crawler[Response] (Status: #{res.status} | Time: #{total_ms}ms) Headers: #{res[:response_headers]}")
        @logger.info("Crawler Completed #{res.status} in #{total_ms}ms")
      end
    end
  end

  class CrawlerError < StandardError; end
  class RedirectLimit < CrawlerError; end
end
