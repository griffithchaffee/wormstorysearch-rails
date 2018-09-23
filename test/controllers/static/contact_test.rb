class StaticController::Test < ApplicationController::TestCase

  def contact_setup
    @reply_to = FactoryBot.generate(:email)
    @subject = "SUBJECT"
    @body = "BODY"
  end

  action = "get contact"

  testing "#{action}" do
    get(:contact)
    assert_response_ok
  end

  action = "post contact"

  testing "#{action} with reply_to email" do
    contact_setup
    post(:contact, params: { reply_to: @reply_to, subject: @subject, body: @body, captcha: "2" })
    assert_response_redirect(stories_path, flash: { notice: 1 })
    assert_mail(0, { reply_to: @reply_to, subject: @subject, body: @body })
  end

  testing "#{action} without reply_to params" do
    contact_setup
    post(:contact, params: { reply_to: "", subject: @subject, body: @body, captcha: "two" })
    assert_response_redirect(stories_path, flash: { notice: 1 })
    assert_mail(0, { subject: @subject, body: @body })
  end

  testing "#{action} with invalid reply_to" do
    contact_setup
    @reply_to = %Q[INVALID"<>=@gmail.com]
    post(:contact, params: { reply_to: @reply_to, subject: @subject, body: @body, captcha: "2" })
    assert_response_redirect(stories_path, flash: { notice: 1 })
    assert_mail(0, { subject: @subject, body: [@body, @reply_to] })
  end

  %i[ subject body ].each do |attribute|
    testing "#{action} without #{attribute}" do
      contact_setup
      post(:contact, params: { reply_to: @reply_to, subject: @subject, body: @body, captcha: "2" }.merge(attribute => nil ))
      assert_response_ok(flash: { alert: 1 })
    end
  end


end
