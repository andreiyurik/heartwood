import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, title: String }

  connect() {
    this.element.hidden = !navigator.share
  }

  share() {
    navigator.share({ title: this.titleValue, url: this.urlValue }).catch(() => {})
  }
}
