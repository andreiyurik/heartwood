import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Renders a Leaflet map and drops a marker per geolocated event fetched from a
// JSON endpoint. No markers → a calm world view, never an error.
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.map = L.map(this.element)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "© OpenStreetMap contributors",
      maxZoom: 19
    }).addTo(this.map)

    this.loadMarkers()
  }

  disconnect() {
    this.map?.remove()
  }

  async loadMarkers() {
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

  popup(m) {
    const lines = [m.kind, m.date, m.place].filter(Boolean).map(esc).join(" · ")
    const who = m.person ? `<a href="${esc(m.person.url)}">${esc(m.person.name)}</a><br>` : ""
    return `${who}${lines}`
  }
}

function esc(value) {
  return String(value).replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  })[c])
}
