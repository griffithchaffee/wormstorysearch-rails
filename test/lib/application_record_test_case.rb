class ApplicationRecord::TestCase < ActiveSupport::TestCase
  include ApplicationTestConcern

  def factory
    self.class.name.split("::").first.underscore
  end

end
