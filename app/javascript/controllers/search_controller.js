import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this._timer = null
  }

  debounce() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.element.requestSubmit(), 300)
  }

  submit() {
    clearTimeout(this._timer)
    this.element.requestSubmit()
  }
}
