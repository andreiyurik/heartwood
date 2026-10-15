import { Controller } from "@hotwired/stimulus"

// Single-key shortcuts: <a data-controller="hotkey" data-hotkey-key-value="n"
// data-action="keydown@window->hotkey#trigger">. Fields get focus, anything else a click.
export default class extends Controller {
  static values = { key: String }

  trigger(event) {
    if (event.key !== this.keyValue || event.metaKey || event.ctrlKey || event.altKey) return
    if (this.#typing(event.target)) return

    event.preventDefault()
    this.element.matches("input, textarea, select") ? this.element.focus() : this.element.click()
  }

  #typing(target) {
    return target.isContentEditable || target.matches("input, textarea, select")
  }
}
