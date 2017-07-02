class ApplicationController::TestCase < ActionController::TestCase
  include ApplicationTestConcern

  teardown do
    assert_flash if !@asserted_flash
  end

  def assert_flash(expected_flash = {})
    expected_flash = expected_flash.with_indifferent_access
    @asserted_flash = true
    %i[ notice info warn alert ].each do |level|
      assert_equal(expected_flash[level].to_i, flash[level].to_a.size, "flash.#{level} [flash=#{flash.inspect}]")
    end
  end

  def assert_response_ok(options = {})
    options = options.with_indifferent_access
    assert_response(200, "#{options[:message]} flash=#{flash.inspect}".strip)
    assert_flash(options[:flash].to_h)
  end

  def assert_response_redirect(path, options = {})
    options = options.with_indifferent_access
    error_message = "#{options[:message]} flash=#{flash.inspect}".strip
    assert_response(302, error_message)
    assert_flash(options[:flash].to_h)
    assert_redirected_to(path, error_message)
  end

  def assert_in_response_body(values)
    Array(values).each do |value|
      assert_equal(true, @response.body.to_s.include?(value.to_s), "@response.body should include: #{value}")
    end
  end

  def assert_not_in_response_body(values)
    Array(values).each do |value|
      assert_equal(false, @response.body.to_s.include?(value.to_s), "@response.body should not include: #{value}")
    end
  end

  def become_admin
    @controller.request.env["REMOTE_ADDR"] = Rails.application.settings.admin_ip
  end

end
