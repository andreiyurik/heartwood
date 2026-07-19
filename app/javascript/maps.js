// Shared Leaflet helpers for the map controllers. Leaflet is imported lazily and
// configured once per page: a blocked CDN resolves to null (callers degrade)
// rather than throwing, and the default marker points at our self-hosted images
// in public/leaflet — the CDN paths it can't resolve when vendored.
let leaflet

export async function loadLeaflet() {
  if (leaflet !== undefined) return leaflet
  try {
    const L = await import("leaflet")
    delete L.Icon.Default.prototype._getIconUrl
    L.Icon.Default.mergeOptions({
      iconUrl: "/leaflet/marker-icon.png",
      iconRetinaUrl: "/leaflet/marker-icon-2x.png",
      shadowUrl: "/leaflet/marker-shadow.png"
    })
    leaflet = L
  } catch (error) {
    console.error("Leaflet failed to load:", error)
    leaflet = null
  }
  return leaflet
}

// The standard OpenStreetMap tile layer, with a credit line free of Leaflet's
// bundled Ukrainian-flag prefix.
export function osmTiles(L, map) {
  map.attributionControl.setPrefix(
    '<a href="https://leafletjs.com" title="A JavaScript library for interactive maps">Leaflet</a>')
  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: "© OpenStreetMap contributors",
    maxZoom: 19
  }).addTo(map)
}

export function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  })[c])
}
