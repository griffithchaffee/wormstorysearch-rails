ActionView::Base.field_error_proc = Proc.new do |original_html, instance|
  fragment = Loofah.fragment(original_html)
  fragment.children.each do |tag|
    if tag.is_a?(Nokogiri::XML::Element) && tag.name =~ /\A(select|input|textarea)\z/i
      error_messages = Array(instance.object.errors.full_messages_for(instance.instance_variable_get('@method_name').to_sym))
      error_message = (Array(tag['data-content']) + error_messages).map { |string| string.escape_html }.join('.<br />')
      error_message = { popover: { content: error_message, title: 'Validation Error', html: 'true', trigger: 'focus' } }
      tag['class'] = [tag['class'].to_s.strip, 'validation-error'].join(' ').strip
      tag['data-notification'] = error_message.to_json
    end
  end
  fragment.to_s.html_safe
end
