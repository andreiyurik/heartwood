import { Controller } from "@hotwired/stimulus"

// A page refresh must not close a form someone is filling in, nor reset a frame
// that is still fetching one: a morph that drops the frame's src cancels the load.
export default class extends Controller {
  hold() {
    this.element.setAttribute("data-turbo-permanent", "")
  }

  sync() {
    this.element.toggleAttribute("data-turbo-permanent", this.element.querySelector("form") !== null)
  }

  release({ detail: { success } }) {
    if (success) this.element.removeAttribute("data-turbo-permanent")
  }
}
