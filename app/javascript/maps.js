// Leaflet is imported lazily and configured once per page; if it fails to load, callers get null and degrade.
// Every marker is the CSS pin (.map-pin), so no marker images are needed.
let leaflet

export async function loadLeaflet() {
  if (leaflet !== undefined) return leaflet
  try {
    const L = await import("leaflet")
    L.Marker.prototype.options.icon = L.divIcon({ className: "map-pin", iconSize: [20, 20], iconAnchor: [10, 10], popupAnchor: [0, -12] })
    leaflet = L
  } catch (error) {
    console.error("Leaflet failed to load:", error)
    leaflet = null
  }
  return leaflet
}

// The tile server is the installation's setting (layout meta tags); the credit line is
// kept free of Leaflet's bundled Ukrainian-flag prefix.
export function addTiles(L, map) {
  map.attributionControl.setPrefix(
    '<a href="https://leafletjs.com" title="A JavaScript library for interactive maps">Leaflet</a>')
  L.tileLayer(metaContent("map-tiles"), {
    attribution: escapeHtml(metaContent("map-tiles-attribution")),
    maxZoom: 19
  }).addTo(map)
}

function metaContent(name) {
  return document.querySelector(`meta[name="${name}"]`)?.content ?? ""
}

export function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  })[c])
}
