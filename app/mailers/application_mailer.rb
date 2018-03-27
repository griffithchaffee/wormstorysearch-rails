class ApplicationMailer < ActionMailer::Base
  default(
    from: ENV["GMAIL_FROM"],
    reply_to: ENV["GMAIL_FROM"],
  )
  layout("mailer")
end
