import { Controller } from "@hotwired/stimulus"

// A page refresh must not close a form someone is filling in, nor reset a frame
// that is still fetching one: a morph that drops the frame's src cancels the load.
// A frame inside the form (a date's reading) fetches and loads too; those are not this frame's.
export default class extends Controller {
  hold(event) {
    if (this.#own(event)) this.element.setAttribute("data-turbo-permanent", "")
  }

  sync(event) {
    if (this.#own(event)) this.element.toggleAttribute("data-turbo-permanent", this.element.querySelector("form") !== null)
  }

  release({ detail: { success } }) {
    if (success) this.element.removeAttribute("data-turbo-permanent")
  }

  #own({ target }) {
    return target.closest("turbo-frame") === this.element
  }
}
