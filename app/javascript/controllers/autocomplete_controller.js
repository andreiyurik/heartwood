import { Controller } from "@hotwired/stimulus"
import { debounce } from "helpers/timing_helpers"

export default class extends Controller {
  initialize() {
    this.search = debounce(() => this.element.requestSubmit(), 300)
  }

  disconnect() {
    this.search.cancel()
  }
}
