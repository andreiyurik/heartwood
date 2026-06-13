import { Controller } from "@hotwired/stimulus"
import { loadLeaflet, osmTiles, escapeHtml } from "maps"

// Renders a Leaflet map and drops a marker per geolocated event fetched from a
// JSON endpoint. Leaflet is imported lazily so a blocked CDN shows a clear
// message instead of leaving the controller unregistered and the box blank.
export default class extends Controller {
  static values = { url: String, unavailable: String }

  async connect() {
    const L = await loadLeaflet()
    if (!L) return this.showUnavailable()

    this.map = L.map(this.element)
    osmTiles(L, this.map)
    this.loadMarkers(L)
  }

  disconnect() {
    this.map?.remove()
  }

  async loadMarkers(L) {
    const markers = await this.fetchMarkers()
    const points = []

    for (const m of markers) {
      L.marker([m.lat, m.lng]).addTo(this.map).bindPopup(this.popup(m))
      points.push([m.lat, m.lng])
    }

    if (points.length) {
      this.map.fitBounds(points, { padding: [30, 30], maxZoom: 12 })
    } else {
      this.map.setView([20, 0], 1)
      this.element.classList.add("map-canvas--empty")
    }
  }

  async fetchMarkers() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      return response.ok ? await response.json() : []
    } catch {
      return []
    }
  }

  showUnavailable() {
    this.element.classList.add("map-canvas--empty")
    this.element.textContent = this.unavailableValue || ""
  }

  popup(m) {
    const lines = [m.kind, m.date, m.place].filter(Boolean).map(escapeHtml).join(" · ")
    const who = m.person ? `<a href="${escapeHtml(m.person.url)}">${escapeHtml(m.person.name)}</a><br>` : ""
    return `${who}${lines}`
  }
}
