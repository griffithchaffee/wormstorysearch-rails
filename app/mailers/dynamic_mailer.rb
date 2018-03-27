class DynamicMailer < ApplicationMailer

  def email(params = {})
    params = params.with_indifferent_access.assert_valid_keys(*%w[ reply_to subject body to ])
    params = params.select { |k,v| v.present? }.reverse_merge(to: "wormstorysearch@gmail.com")
    @body = params.delete(:body)
    mail(params)
  end

end
