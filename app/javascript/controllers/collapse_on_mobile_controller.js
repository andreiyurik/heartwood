import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.open = !matchMedia("(max-width: 40rem)").matches
  }
}
