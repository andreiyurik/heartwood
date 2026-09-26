import { Controller } from "@hotwired/stimulus"

// Closing empties the frame so re-clicking the same person reloads it (a frame keeps its src).
export default class extends Controller {
  static targets = ["frame"]

  #onLoad

  connect() {
    this.#onLoad = () => this.open()
    this.frameTarget.addEventListener("turbo:frame-load", this.#onLoad)
  }

  disconnect() {
    this.frameTarget.removeEventListener("turbo:frame-load", this.#onLoad)
  }

  open() {
    this.element.classList.add("tree-drawer--open")
  }

  close() {
    this.element.classList.remove("tree-drawer--open")
    this.frameTarget.removeAttribute("src")
    this.frameTarget.innerHTML = ""
  }
}
