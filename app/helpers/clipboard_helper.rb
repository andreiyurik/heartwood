module ClipboardHelper
  def button_to_copy_to_clipboard(content, &)
    tag.button class: "btn btn--circle", data: {
      controller: "copy-to-clipboard", action: "copy-to-clipboard#copy",
      copy_to_clipboard_success_class: "btn--success", copy_to_clipboard_content_value: content
    }, &
  end
end
