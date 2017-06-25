class ApplicationController::Test < ApplicationController::TestCase

  testing "is_admin without admin ip" do
    assert_equal(false, @controller.is_admin?)
  end

  testing "is_admin with admin ip" do
    become_admin
    assert_equal(true, @controller.is_admin?)
  end

end
