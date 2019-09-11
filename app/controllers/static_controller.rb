class StaticController < ApplicationController

  def contact
    name, reply_to, subject, body, captcha = params.values_at(*%w[ name reply_to subject body captcha ])
    if request.post?
      if subject.blank? || body.blank?
        flash.now.alert("A subject and body must be provided")
      elsif captcha.to_s.slugify_for_comparison != "abc"
        flash.now.alert("Looks like your a bot")
      else
        email_regex = /\A[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~.]+@([-a-zA-Z0-9]+\.)+[a-zA-Z]+\z/
        if reply_to.present? && reply_to !~ email_regex
          body = "Reply To: #{reply_to}\n#{body}"
          reply_to = nil
        end
        DynamicMailer.email(
          reply_to: reply_to,
          subject: "WormStorySearch Support: #{subject}",
          body: body
        ).deliver_now
        flash.notice("Contact email successfully sent")
        redirect_to(stories_path)
      end
    end
  end

  # used for health check
  def ping
    render(inline: "pong")
  end

end
