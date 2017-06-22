class ApplicationMailer < ActionMailer::Base
  default(
    to: "hometurfpublic@gmail.com",
    from: "noreply@#{Rails.application.settings.domain}",
    reply_to: "noreply@#{Rails.application.settings.domain}",
  )
  layout("mailer")
end
