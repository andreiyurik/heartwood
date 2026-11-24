import { Controller } from "@hotwired/stimulus"

// Shows the picked picture before sending, so whoever answers sees it really is attached.
export default class extends Controller {
  static targets = [ "name", "preview" ]

  show({ target }) {
    const file = target.files[0]
    if (!file) return

    this.nameTarget.textContent = file.name
    this.previewTarget.src = URL.createObjectURL(file)
    this.previewTarget.hidden = false
  }
}
