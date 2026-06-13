import { Controller } from "@hotwired/stimulus"

// Type-ahead for the event place field. Suggestions are pure enhancement: the
// text input find-or-creates a Place on submit whether or not one is picked.
export default class extends Controller {
  static targets = ["input", "list"]
  static values = { url: String }

  connect() {
    this._timer = null
  }

  search() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.fetchSuggestions(), 250)
  }

  async fetchSuggestions() {
    const query = this.inputTarget.value.trim()
    if (query.length < 2) return this.clear()

    const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
      headers: { Accept: "text/html" }
    })
    this.listTarget.innerHTML = response.ok ? await response.text() : ""
  }

  choose(event) {
    const option = event.target.closest("[data-place-name]")
    if (!option) return

    event.preventDefault()
    this.inputTarget.value = option.dataset.placeName
    this.clear()
  }

  clear() {
    this.listTarget.innerHTML = ""
  }
}
