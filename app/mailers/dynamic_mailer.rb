class DynamicMailer < ApplicationMailer

  def email(params = {})
    params = params.with_indifferent_access.assert_valid_keys(*%w[ reply_to subject body ])
    params[:to] = "hometurfpublic@gmail.com"
    @body = params.delete(:body)
    mail(params.select_present)
  end

end
