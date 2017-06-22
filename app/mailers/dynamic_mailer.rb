class DynamicMailer < ApplicationMailer

  def email(params = {})
    params = params.with_indifferent_access.assert_valid_keys(*%w[ subject body ])
    params[:to] = "hometurfpublic@gmail.com"
    @body = params.delete(:body)
    mail(params)
  end

end
