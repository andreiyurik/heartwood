import { Controller } from "@hotwired/stimulus"

// Ticks stay in the reader's own browser; the server never learns what they have done.
export default class extends Controller {
  static targets = [ "item", "count" ]
  static values = { key: String }

  connect() {
    const done = this.#stored
    for (const item of this.itemTargets) item.checked = done.includes(item.value)
    this.#count()
  }

  save() {
    const kept = this.#stored.filter(value => !this.itemTargets.some(item => item.value == value))
    const done = this.itemTargets.filter(item => item.checked).map(item => item.value)
    try { localStorage.setItem(this.#name, JSON.stringify([ ...kept, ...done ])) } catch {}
    this.#count()
  }

  #count() {
    if (!this.hasCountTarget) return
    const done = this.itemTargets.filter(item => item.checked).length
    this.countTarget.hidden = done == 0
    this.countTarget.textContent = this.countTarget.dataset.template.replace("%{done}", done).replace("%{total}", this.itemTargets.length)
  }

  get #stored() {
    try { return JSON.parse(localStorage.getItem(this.#name)) || [] } catch { return [] }
  }

  get #name() {
    return `heartwood:checklist:${this.keyValue}`
  }
}
