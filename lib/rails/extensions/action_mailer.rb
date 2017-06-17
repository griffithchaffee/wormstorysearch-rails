require "mail"

class Mail::Message
  attr_accessor :record
end

class ActionMailer::MessageDelivery
  alias_method :original_deliver_now, :deliver_now
  alias_method :original_deliver_later, :deliver_later

  # queue delivery
  def deliver_later
    raise "deliver_later is currently untested but should only queue Email record"
    if deliver_in_batches?
      deliver_in_batches
    else
      message.record.save_if_changed!
    end
  end

  def deliver_in_batches?
    %w[ to cc bcc ].any? { |field| Array(message.send(field)).size > UniversalMailer.max_recipients }
  end

  def deliver_in_batches
    record = message.record
    bcc_recipients = Array(message.to) + Array(message.cc) + Array(message.bcc)
    bcc_recipients.each_slice(UniversalMailer.max_recipients) do |bcc_batch|
      batch_record = record.dup.save_if_changed!(to: nil, cc: nil, bcc: bcc_batch)
    end
    # mark queued email as sent
    if record.saved? && !record.was_sent?
      record.save_if_changed!(was_sent: true, sent_at: Time.zone.now)
    end
    :batched
  end

  # deliver with queue fallback
  def deliver_now
    # automatically batch delivery of large emails
    return deliver_in_batches if deliver_in_batches?
    logger = ActionMailer::Base.logger
    result = message
    record = message.record
    begin
      # test errors
      raise record.subject.remove(/\ARAISE /).constantize if Rails.env.test? && record && record.subject.to_s.start_with?("RAISE ")
      # create custom delivery timeout since Mail::STMP.deliver! does not support setting timeout options
      delivery_timeout =
        case message.delivery_method
        when Mail::SMTP then message.delivery_method.settings.fetch(:delivery_timeout)
        else UniversalMailer.smtp_settings.fetch(:delivery_timeout)
        end
      Timeout.timeout(delivery_timeout) { result = original_deliver_now }
      # invalid records should still raise errors because invalid emails should never be submitted
      record.save_if_changed!(was_sent: true, sent_at: Time.zone.now) if record
    rescue *delivery_rescue_classes => mailer_error
      record.save_if_changed! if record
      logger.warn do
        if record
          "MAILER: #{mailer_error.class}: #{mailer_error.message}\nEmail [#{record.id}]: #{record.subject}\n#{mailer_error.backtrace.join("\n")}"
        else
          "MAILER: #{mailer_error.class}: #{mailer_error.message}\n#{mailer_error.backtrace.join("\n")}"
        end
      end
    end
    if record
      logger.debug { "\n#{record.to_pretty_s}" }
    end
    result
  end

  def delivery_rescue_classes
    [
      IOError,
      Timeout::Error,
      Errno::ECONNRESET,
      Errno::ECONNABORTED,
      Errno::EPIPE,
      Errno::ETIMEDOUT,
      Net::SMTPServerBusy,
      Net::SMTPSyntaxError,
      Net::SMTPUnknownError,
      Net::SMTPAuthenticationError,
      OpenSSL::SSL::SSLError,
    ]
  end

end
