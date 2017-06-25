module ApplicationTestConcern
  extend ActiveSupport::Concern

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
