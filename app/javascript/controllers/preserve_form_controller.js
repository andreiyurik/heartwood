import { Controller } from "@hotwired/stimulus"

// A page refresh must not close a form someone is filling in.
export default class extends Controller {
  sync() {
    this.element.toggleAttribute("data-turbo-permanent", this.element.querySelector("form") !== null)
  }
}
