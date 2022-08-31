class StaticPresenter < ApplicationPresenter

  # labels
  define_extension(:label_for, :name_label,     :name,     content: "Your Name")
  define_extension(:label_for, :reply_to_label, :reply_to, content: "Reply To")
  define_extension(:label_for, :subject_label,  :subject,  content: "Subject")
  define_extension(:label_for, :body_label,     :body,     content: "Body")
  define_extension(:label_for, :captcha_label,  :captcha,  content: "Prove you're not a bot")
  # fields
  define_extension(:text_field_tag, :name_field,     :name,     placeholder: "John Smith")
  define_extension(:text_field_tag, :reply_to_field, :reply_to, placeholder: "john.smith@example.com")
  define_extension(:text_field_tag, :subject_field,  :subject,  placeholder: "Topic of contact...")
  define_extension(:text_area_tag,  :body_field,     :body,     placeholder: "Describe your reason for contact...", rows: 5)
  define_extension(:text_field_tag, :captcha_field,  :captcha)

end
