module ApplicationTestConcern
  extend ActiveSupport::Concern

  included do
    setup do
      clear_mail_queue
    end

    teardown do
      assert_mail_queue(0, "auto verify no mail_queue") if !@asserted_mail_queue
    end
  end

  def assert_hash_change(original_hash, update_hash, new_hash, expected_changes = [])
    update_hash.each do |key, value|
      assert_not_equal(original_hash[key], value, "#{key}: original value must be different from update value")
      if key.in?(expected_changes)
        assert_equal(new_hash[key].inspect, update_hash[key].inspect, "#{key}: should change")
      else
        assert_equal(new_hash[key].inspect, original_hash[key].inspect, "#{key}: should not change")
      end
    end
  end

  def assert_no_hash_change(*params)
    assert_hash_change(*params)
  end

  def clear_mail_queue
    mail_queue.clear
  end

  def mail_queue
    ActionMailer::Base.deliveries
  end

  def assert_mail_queue(size, message = nil)
    @asserted_mail_queue = true
    error_message = message || (size < mail_queue.size ? "unknown emails were sent" : "emails are missing")
    assert_equal(size, mail_queue.size, error_message)
  end

  def assert_mail(mail_or_key, values)
    @asserted_mail_queue = true
    mail = mail_queue[mail_or_key] if mail_or_key.is_a?(Numeric)
    assert_not_nil(mail, "mail_queue[#{mail_or_key}] is blank")
    values = values.with_indifferent_access.reverse_merge!(
      from:     "noreply@wormstorysearch.com",
      reply_to: "noreply@wormstorysearch.com",
      to:       "hometurfpublic@gmail.com",
      cc:       nil,
      bcc:      nil,
    )
    %w[ from reply_to to cc bcc subject body ].each do |attribute|
      error_message = "#{attribute} - #{mail.inspect}"
      expected_value = values[attribute]
      mail_value = mail.send(attribute)
      case attribute
      when *%w[ from reply_to to cc bcc ]
        assert_equal([expected_value].flatten.compact.sort, [mail_value].flatten.compact.sort, error_message)
      when "body"
        [expected_value].flatten.map(&:to_s).each do |body_value|
          assert(mail.text_part.to_s.include?(body_value), "mail.text_part should include: #{body_value}")
          assert(mail.html_part.to_s.include?(body_value.escape_html), "mail.html_part should include: #{body_value}")
        end
      else assert_equal(expected_value, mail_value, error_message)
      end
    end
  end

  class_methods do
    def testing(test_name, &block)
      full_test_name = "#{name} #{test_name}".slugify
      if full_test_name.starts_with?("#{name}_#{name}".slugify)
        raise ArgumentError, "remove class prefix from test: #{test_name}"
      end
      test(full_test_name, &block)
    end
  end

end
