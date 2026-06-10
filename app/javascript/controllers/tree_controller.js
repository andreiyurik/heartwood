import { Controller } from "@hotwired/stimulus"

// Node dimensions and spacing (pixels).
const NODE_W  = 160
const NODE_H  = 64
const COL_GAP = 64   // horizontal gap between generation columns
const ROW_GAP = 16   // vertical gap between nodes in the same column
const COL_W   = NODE_W + COL_GAP

export default class extends Controller {
  static targets = ["inner", "svg", "node"]
  static values  = { graph: Object, mode: String }

  connect() {
    this._pan   = { x: 40, y: 40 }
    this._scale = 1
    this._layout()
    this._bindPanZoom()
  }

  disconnect() {
    window.removeEventListener("pointermove", this._boundMove)
    window.removeEventListener("pointerup",   this._boundUp)
  }

  // --- Layout -----------------------------------------------------------------

  _layout() {
    const { nodes, edges } = this.graphValue
    if (!nodes.length) return

    // Group and sort nodes by generation, then by server-assigned order.
    const byGen = new Map()
    for (const n of nodes) {
      if (!byGen.has(n.generation)) byGen.set(n.generation, [])
      byGen.get(n.generation).push(n)
    }
    for (const gs of byGen.values()) gs.sort((a, b) => a.order - b.order)

    // Total canvas height = tallest column, vertically centred.
    const maxCount = Math.max(...[...byGen.values()].map(g => g.length))
    const canvasH  = Math.max(maxCount * (NODE_H + ROW_GAP) - ROW_GAP, NODE_H)
    const maxGen   = Math.max(...nodes.map(n => n.generation))

    // Assign pixel positions.
    this._pos = {}
    for (const [gen, gs] of byGen) {
      const totalH = gs.length * NODE_H + (gs.length - 1) * ROW_GAP
      const startY = (canvasH - totalH) / 2
      gs.forEach((n, i) => {
        this._pos[n.id] = {
          x: gen * COL_W,
          y: startY + i * (NODE_H + ROW_GAP)
        }
      })
    }

    const totalW = (maxGen + 1) * COL_W - COL_GAP
    this._resize(totalW, canvasH)
    this._placeNodes()
    this._drawEdges(edges)
    this._applyTransform()
  }

  _resize(w, h) {
    const pad = 80
    this.innerTarget.style.width  = `${w + pad}px`
    this.innerTarget.style.height = `${h + pad}px`
    this.svgTarget.setAttribute("width",  w + pad)
    this.svgTarget.setAttribute("height", h + pad)
  }

  _placeNodes() {
    for (const el of this.nodeTargets) {
      const pos = this._pos[+el.dataset.treeNodeId]
      if (!pos) continue
      el.style.transform = `translate(${pos.x}px, ${pos.y}px)`
    }
  }

  _drawEdges(edges) {
    const NS  = "http://www.w3.org/2000/svg"
    const svg = this.svgTarget
    svg.innerHTML = ""

    for (const e of edges) {
      const src = this._pos[e.from_id]
      const tgt = this._pos[e.to_id]
      if (!src || !tgt) continue

      // Bezier from right-middle of source to left-middle of target.
      const x1 = src.x + NODE_W
      const y1 = src.y + NODE_H / 2
      const x2 = tgt.x
      const y2 = tgt.y + NODE_H / 2
      const mx  = (x1 + x2) / 2

      const path = document.createElementNS(NS, "path")
      path.setAttribute("d",     `M${x1},${y1} C${mx},${y1} ${mx},${y2} ${x2},${y2}`)
      path.setAttribute("class", "tree-edge")
      svg.appendChild(path)
    }
  }

  // --- Pan & zoom -------------------------------------------------------------

  _bindPanZoom() {
    this._boundMove = this._onMove.bind(this)
    this._boundUp   = this._onUp.bind(this)
    this.element.addEventListener("pointerdown", this._onDown.bind(this))
    this.element.addEventListener("wheel",       this._onWheel.bind(this), { passive: false })
    window.addEventListener("pointermove",       this._boundMove)
    window.addEventListener("pointerup",         this._boundUp)
  }

  _onDown(e) {
    if (e.target.closest("a")) return   // let link clicks through
    e.preventDefault()
    this._drag = { x0: e.clientX - this._pan.x, y0: e.clientY - this._pan.y }
  }

  _onMove(e) {
    if (!this._drag) return
    this._pan.x = e.clientX - this._drag.x0
    this._pan.y = e.clientY - this._drag.y0
    this._applyTransform()
  }

  _onUp() { this._drag = null }

  _onWheel(e) {
    e.preventDefault()
    this._scale = Math.max(0.2, Math.min(4, this._scale * (e.deltaY < 0 ? 1.1 : 0.9)))
    this._applyTransform()
  }

  _applyTransform() {
    this.innerTarget.style.transformOrigin = "0 0"
    this.innerTarget.style.transform =
      `translate(${this._pan.x}px, ${this._pan.y}px) scale(${this._scale})`
  }
}
