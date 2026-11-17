module ClipboardHelper
  def button_to_copy_to_clipboard(content, **options, &)
    tag.button type: "button", class: options.fetch(:class, "btn btn--round"), data: {
      controller: "copy-to-clipboard", action: "copy-to-clipboard#copy",
      copy_to_clipboard_success_class: "btn--success", copy_to_clipboard_content_value: content
    }, &
  end
end
