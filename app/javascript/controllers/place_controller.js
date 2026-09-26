import { Controller } from "@hotwired/stimulus"
import { loadLeaflet, osmTiles, escapeHtml } from "maps"

// Leaflet is imported lazily so a blocked CDN never stops autocomplete and the button from working.
let groupId = 0

export default class extends Controller {
  static targets = ["input", "suggestions", "candidates", "map", "lat", "lng"]
  static values = { searchUrl: String, geocodeUrl: String, noMatch: String }

  connect() {
    this._timer = null
    this._map = null
    this._marker = null
    this._group = `place-candidate-${++groupId}`
  }

  disconnect() {
    clearTimeout(this._timer)
    this._map?.remove()
  }

  search() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.suggest(), 250)
  }

  async suggest() {
    const query = this.inputTarget.value.trim()
    if (query.length < 2) return (this.suggestionsTarget.innerHTML = "")

    const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
      headers: { Accept: "text/html" }
    })
    this.suggestionsTarget.innerHTML = response.ok ? await response.text() : ""
  }

  chooseSuggestion(event) {
    const option = event.target.closest("[data-place-name]")
    if (!option) return

    event.preventDefault()
    this.inputTarget.value = option.dataset.placeName
    this.suggestionsTarget.innerHTML = ""
  }

  async locate() {
    const query = this.inputTarget.value.trim()
    if (!query) return

    clearTimeout(this._timer)
    this.suggestionsTarget.innerHTML = ""
    this.candidatesTarget.innerHTML = ""

    let candidates = []
    try {
      const response = await fetch(`${this.geocodeUrlValue}?q=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json" }
      })
      if (response.ok) candidates = await response.json()
    } catch (error) {
      console.error("Place lookup failed:", error)
    }

    if (!candidates.length) {
      this.candidatesTarget.innerHTML = `<p class="muted place-no-match">${escapeHtml(this.noMatchValue)}</p>`
      return
    }

    this.renderCandidates(candidates)
    this.select(candidates[0])
  }

  renderCandidates(candidates) {
    this.candidatesTarget.innerHTML = candidates
      .map((c, i) => `
        <label class="place-candidate">
          <input type="radio" name="${this._group}" value="${i}" ${i === 0 ? "checked" : ""}>
          <span>${escapeHtml(c.display_name)}</span>
        </label>`)
      .join("")

    this.candidatesTarget.querySelectorAll("input").forEach((input, i) => {
      input.addEventListener("change", () => this.select(candidates[i]))
    })
  }

  select(candidate) {
    this.setCoords(candidate.lat, candidate.lng)
    this.showMap(candidate.lat, candidate.lng)
  }

  async showMap(lat, lng) {
    const L = await loadLeaflet()
    if (!L) return

    this.mapTarget.hidden = false

    if (!this._map) {
      this._map = L.map(this.mapTarget).setView([lat, lng], 11)
      osmTiles(L, this._map)

      this._marker = L.marker([lat, lng], { draggable: true }).addTo(this._map)
      this._marker.on("dragend", () => {
        const point = this._marker.getLatLng()
        this.setCoords(point.lat, point.lng)
      })
      // The container was hidden until now; Leaflet must recompute its size.
      setTimeout(() => this._map.invalidateSize(), 0)
    } else {
      this._map.setView([lat, lng], 11)
      this._marker.setLatLng([lat, lng])
      this._map.invalidateSize()
    }
  }

  setCoords(lat, lng) {
    this.latTarget.value = lat
    this.lngTarget.value = lng
  }
}
