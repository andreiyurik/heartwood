import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog", "zoomedImage", "caption" ]

  open(event) {
    event.preventDefault()

    this.zoomedImageTarget.src = event.currentTarget.href
    this.captionTarget.textContent = event.params.caption || ""
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  dismiss(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }

  reset() {
    this.zoomedImageTarget.src = ""
  }
}
