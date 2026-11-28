import { Controller } from "@hotwired/stimulus"

// Draws the crest the tree will get, as its name is typed: the same letter and hue as Tree::Crest.
const LEADING_WORDS = /^(род|семья|древо|family|the)\s+/i

export default class extends Controller {
  static targets = [ "crest", "name", "title" ]

  draw() {
    const name = this.nameTarget.value

    for (const crest of this.crestTargets) {
      const svg = crest.querySelector("svg")
      const letter = svg.querySelector("text")

      if (letter) letter.textContent = (name.replace(LEADING_WORDS, "")[0] || "").toUpperCase()
      svg.style.setProperty("--avatar-hue", crc32(name) % 360)
    }
    for (const title of this.titleTargets) title.textContent = name.trim() || title.dataset.placeholder
  }
}

// Zlib.crc32 over the name's UTF-8 bytes, so the hue here is the hue the tree is saved with.
function crc32(text) {
  let crc = ~0
  for (const byte of new TextEncoder().encode(text)) {
    crc ^= byte
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ (0xEDB88320 & -(crc & 1))
  }
  return (~crc) >>> 0
}
