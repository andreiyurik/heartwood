import { Controller } from "@hotwired/stimulus"

// Shows how the app read a typed date. The reading comes from the server: FuzzyDate is the only parser.
export default class extends Controller {
  static targets = [ "input", "frame" ]
  static values = { url: String }

  disconnect() {
    clearTimeout(this.timer)
  }

  read() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.#ask(), 250)
  }

  oldStyle({ params: { suffix } }) {
    this.inputTarget.value = `${this.inputTarget.value.trim()} ${suffix}`
    this.inputTarget.focus()
    this.#ask()
  }

  #ask() {
    const date = this.inputTarget.value.trim()
    if (date) {
      this.frameTarget.src = `${this.urlValue}?${new URLSearchParams({ date, frame: this.frameTarget.id })}`
    } else {
      this.frameTarget.removeAttribute("src")
      this.frameTarget.replaceChildren()
    }
  }
}
