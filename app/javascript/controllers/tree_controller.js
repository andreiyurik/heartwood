import { Controller } from "@hotwired/stimulus"

// A vertical tidy tree (Reingold–Tilford in spirit, written by hand — no d3/dagre).
// Generations are horizontal rows; within a row, X comes from a post-order pass so
// parents sit centred over their children and sibling subtrees never overlap.
//
// The layout works on *units*: a couple (two partner cards joined by a short
// connector) or a lone person. Without `unions` every unit is a singleton, so this
// is a plain tidy tree; with `unions`, couples lay out as one block of two cards.
//
// On top of the layout: collapse/expand of branches and a search box that flies the
// camera to a person (expanding the path to them first). Units are built once; a
// collapse/expand only re-runs the cheap positioning pass.

const NODE_W      = 210   // card width (keep in sync with .tree-node in application.css)
const NODE_H      = 88    // card height (name wrapping to 2 lines + surname + dates)
const MIN_FIT     = 0.35  // fit-to-view floor — below this a huge tree is confetti
const PAIR_GAP    = 20    // gap between the two cards of a couple
const SIBLING_GAP = 40    // gap between adjacent units in a row
const ROW_GAP     = 64    // vertical gap between generation rows
const ROW_H       = NODE_H + ROW_GAP
const PAD         = 60    // breathing room around the laid-out tree

export default class extends Controller {
  static targets = ["inner", "svg", "node", "searchInput", "searchResults"]
  static values  = {
    graph:         Object,
    mode:          String,
    expandLabel:   String,
    collapseLabel: String
  }

  connect() {
    this._scale     = 1
    this._collapsed = new Set()   // ids of units whose children are folded away
    this._build()
    if (!this._units.length) return

    this._toggleLayer = document.createElement("div")
    this._toggleLayer.className = "tree-toggles"
    this.innerTarget.appendChild(this._toggleLayer)

    this._relayout()
    this._fitToView()
    this._bindPanZoom()
  }

  disconnect() {
    window.removeEventListener("pointermove", this._boundMove)
    window.removeEventListener("pointerup",   this._boundUp)
  }

  // --- Build the unit tree (once) ---------------------------------------------

  _build() {
    const { nodes, edges, focus_id } = this.graphValue
    const unions = this.graphValue.unions || []
    if (!nodes.length) { this._units = []; return }

    const { units, unitOf, nodeById } = this._buildUnits(nodes, unions)
    this._linkUnits(units, unitOf, edges, nodeById)

    this._units    = units
    this._unitOf   = unitOf
    this._nodeById = nodeById
    this._root     = unitOf.get(focus_id)
    for (const u of units) this._countSubtree(u)
  }

  // Group people into units. A union with two visible partners becomes a couple;
  // everyone else is a singleton. Partners are ordered male-left for a calm,
  // conventional read; ties fall back to id so layout is deterministic.
  _buildUnits(nodes, unions) {
    const nodeById = new Map(nodes.map(n => [n.id, n]))
    const unitOf   = new Map()
    const units    = []

    const make = (memberIds) => {
      const members = memberIds.slice().sort((a, b) =>
        this._sexRank(nodeById.get(a)) - this._sexRank(nodeById.get(b)) || a - b)
      const unit = { id: units.length, members, children: [], parent: null, cx: 0, y: 0 }
      units.push(unit)
      members.forEach(id => unitOf.set(id, unit))
      return unit
    }

    for (const u of unions) {
      const ids = (u.partner_ids || []).filter(id => nodeById.has(id)).slice(0, 2)
      if (ids.length === 2 && ids.every(id => !unitOf.has(id))) make(ids)
    }
    for (const n of nodes) if (!unitOf.has(n.id)) make([n.id])

    return { units, unitOf, nodeById }
  }

  // Lift the person edges (from = layout-parent, to = layout-child, in both modes)
  // onto units. First edge into a unit wins, so a person reached twice via pedigree
  // collapse is placed once. Children are ordered by the server's `order`.
  _linkUnits(units, unitOf, edges, nodeById) {
    for (const e of edges) {
      const pu = unitOf.get(e.from_id)
      const cu = unitOf.get(e.to_id)
      if (!pu || !cu || pu === cu || cu.parent) continue
      cu.parent = pu
      pu.children.push(cu)
    }
    const orderOf = u => Math.min(...u.members.map(id => nodeById.get(id).order))
    for (const u of units) u.children.sort((a, b) => orderOf(a) - orderOf(b))
  }

  // People strictly below a unit — shown on its collapsed badge ("+N").
  _countSubtree(u) {
    if (u.subtreeCount != null) return u.subtreeCount
    let n = 0
    for (const c of u.children) n += c.members.length + this._countSubtree(c)
    return u.subtreeCount = n
  }

  // --- Positioning (re-run on every collapse/expand) --------------------------

  _relayout() {
    this._markVisible()
    this._assignX(this._root)
    this._assignY()
    this._pos = this._placeCards()
    this._resize()
    this._placeNodes()
    this._drawEdges()
    this._drawToggles()
  }

  // A unit is visible if every ancestor is expanded; a collapsed unit is itself
  // visible (it carries the "+N" badge) but its descendants are not.
  _markVisible() {
    for (const u of this._units) u.visible = false
    const walk = (u) => {
      u.visible = true
      if (this._collapsed.has(u.id)) return
      for (const c of u.children) walk(c)
    }
    walk(this._root)
  }

  // Post-order X: leaves take successive slots; a parent is centred over its
  // children. A collapsed unit is treated as a leaf. When a parent is wider than
  // its children's span (a couple over a single child), shift the children to keep
  // the block centred and nothing overlapping. Correct first, tidy second.
  _assignX(root) {
    const place = (u, left) => {
      const w    = this._unitWidth(u)
      const kids = this._collapsed.has(u.id) ? [] : u.children
      if (!kids.length) { u.cx = left + w / 2; return w }

      let cursor = left
      for (const c of kids) cursor += place(c, cursor) + SIBLING_GAP
      const childrenW = cursor - SIBLING_GAP - left
      const center    = (kids[0].cx + kids[kids.length - 1].cx) / 2

      if (childrenW >= w) { u.cx = center; return childrenW }
      this._shift(kids, (w - childrenW) / 2)
      u.cx = left + w / 2
      return w
    }
    place(root, 0)
  }

  _shift(children, dx) {
    for (const c of children) { c.cx += dx; this._shift(c.children, dx) }
  }

  // Rows from generation, over the visible units only — folding a deep branch
  // compacts the tree vertically. Descendants grow down, ancestors grow up.
  _assignY() {
    const vis    = this._units.filter(u => u.visible)
    const maxGen = Math.max(...vis.map(u => this._gen(u)))
    for (const u of vis) {
      const g = this._gen(u)
      u.y = (this.modeValue === "ancestors" ? maxGen - g : g) * ROW_H
    }
  }

  _gen(u)        { return this._nodeById.get(u.members[0]).generation }
  _unitWidth(u)  { return u.members.length === 2 ? NODE_W * 2 + PAIR_GAP : NODE_W }

  // Resolve visible units into per-card top-left positions, then normalise so the
  // tree starts at (PAD, PAD) — unit centres can go negative after shifts.
  _placeCards() {
    const pos = {}
    const vis = this._units.filter(u => u.visible)
    for (const u of vis) {
      if (u.members.length === 2) {
        const off = (NODE_W + PAIR_GAP) / 2
        pos[u.members[0]] = { cx: u.cx - off, y: u.y }
        pos[u.members[1]] = { cx: u.cx + off, y: u.y }
      } else {
        pos[u.members[0]] = { cx: u.cx, y: u.y }
      }
    }

    const cards = Object.values(pos)
    const minX  = Math.min(...cards.map(p => p.cx - NODE_W / 2))
    const minY  = Math.min(...vis.map(u => u.y))
    const dx = PAD - minX, dy = PAD - minY
    for (const p of cards) { p.cx += dx; p.x = p.cx - NODE_W / 2; p.y += dy }
    for (const u of vis)   { u.cx += dx; u.y += dy }
    return pos
  }

  _resize() {
    const cards = Object.values(this._pos)
    const maxX  = Math.max(...cards.map(p => p.x + NODE_W))
    const maxY  = Math.max(...this._units.filter(u => u.visible).map(u => u.y)) + NODE_H
    const w = maxX + PAD, h = maxY + PAD
    this.innerTarget.style.width  = `${w}px`
    this.innerTarget.style.height = `${h}px`
    this.svgTarget.setAttribute("width",  w)
    this.svgTarget.setAttribute("height", h)
  }

  _placeNodes() {
    for (const el of this.nodeTargets) {
      const pos = this._pos[+el.dataset.treeNodeId]
      if (pos) {
        el.style.display   = ""
        el.style.transform = `translate(${pos.x}px, ${pos.y}px)`
      } else {
        el.style.display = "none"   // inside a folded branch
      }
    }
  }

  // --- Edges & toggles --------------------------------------------------------

  _drawEdges() {
    this.svgTarget.innerHTML = ""
    for (const u of this._units) {
      if (!u.visible) continue
      if (u.members.length === 2) this._connector(u)
      if (this._collapsed.has(u.id)) continue
      for (const c of u.children) this._link(u, c)
    }
  }

  // Short horizontal line joining the two partner cards of a couple — drawn thicker
  // than descent edges so marriage reads differently from parent-child.
  _connector(u) {
    const [a, b] = u.members
    const x1 = this._pos[a].cx + NODE_W / 2
    const x2 = this._pos[b].cx - NODE_W / 2
    const y  = u.y + NODE_H / 2
    this._path(`M${x1},${y} L${x2},${y}`, "tree-edge tree-edge--bond")
  }

  // Vertical bézier from a parent unit to a child unit, in the growth direction.
  _link(parent, child) {
    const px = parent.cx, cx = child.cx
    const dir = Math.sign((child.y + NODE_H / 2) - (parent.y + NODE_H / 2)) || 1
    const y1  = parent.y + NODE_H / 2 + dir * NODE_H / 2
    const y2  = child.y  + NODE_H / 2 - dir * NODE_H / 2
    const my  = (y1 + y2) / 2
    this._path(`M${px},${y1} C${px},${my} ${cx},${my} ${cx},${y2}`)
  }

  _path(d, cls = "tree-edge") {
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
    path.setAttribute("d", d)
    path.setAttribute("class", cls)
    this.svgTarget.appendChild(path)
  }

  // A small button at each branchable unit's growth-facing edge: "−" to fold,
  // "+N" (N = hidden people) to unfold.
  _drawToggles() {
    this._toggleLayer.innerHTML = ""
    const dir = this.modeValue === "ancestors" ? -1 : 1

    for (const u of this._units) {
      if (!u.visible || !u.children.length) continue
      const collapsed = this._collapsed.has(u.id)

      const btn = document.createElement("button")
      btn.type      = "button"
      btn.className = `tree-toggle${collapsed ? " tree-toggle--collapsed" : ""}`
      btn.textContent = collapsed ? `+${u.subtreeCount}` : "−"
      const label = collapsed ? this.expandLabelValue : this.collapseLabelValue
      btn.setAttribute("aria-label", label)
      btn.title = label
      btn.style.left = `${u.cx}px`
      btn.style.top  = `${u.y + NODE_H / 2 + dir * (NODE_H / 2 + 12)}px`
      btn.addEventListener("click", (e) => { e.stopPropagation(); this._toggle(u.id) })
      this._toggleLayer.appendChild(btn)
    }
  }

  // Fold/unfold a branch, keeping the focus card pinned on screen so the view
  // doesn't jump as the tree re-flows.
  _toggle(id) {
    const anchor = this._anchorScreen()
    this._collapsed.has(id) ? this._collapsed.delete(id) : this._collapsed.add(id)
    this._relayout()
    this._restoreAnchor(anchor)
    this._applyTransform()
  }

  // --- Search & fly-to --------------------------------------------------------

  search() {
    if (!this.hasSearchResultsTarget) return
    const q    = this.searchInputTarget.value.trim().toLowerCase()
    const list = this.searchResultsTarget
    list.innerHTML = ""

    const matches = q
      ? this.graphValue.nodes
          .filter(n => !n.living && n.name && n.name.toLowerCase().includes(q))
          .slice(0, 8)
      : []

    if (!matches.length) { list.hidden = true; return }
    for (const m of matches) {
      const li = document.createElement("li")
      li.textContent = m.name
      li.tabIndex = 0
      li.addEventListener("click", () => this._flyTo(m.id))
      li.addEventListener("keydown", (e) => { if (e.key === "Enter") this._flyTo(m.id) })
      list.appendChild(li)
    }
    list.hidden = false
  }

  searchKeys(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      this.searchResultsTarget.querySelector("li")?.click()
    } else if (e.key === "Escape") {
      this._clearSearch()
    }
  }

  _flyTo(id) {
    this._reveal(id)            // unfold the path so the person is on screen
    this._relayout()
    this._scale = 1
    const p = this._pos[id]
    if (p) this._panTo(p.cx, p.y + NODE_H / 2, true)
    this._flash(id)
    this._clearSearch()
  }

  // Expand every ancestor of the person's unit (the unit itself may stay folded —
  // the person is still one of its visible cards).
  _reveal(id) {
    let u = this._unitOf.get(id)?.parent
    while (u) { this._collapsed.delete(u.id); u = u.parent }
  }

  _flash(id) {
    const el = this.nodeTargets.find(e => +e.dataset.treeNodeId === id)
    if (!el) return
    el.classList.add("tree-node--found")
    setTimeout(() => el.classList.remove("tree-node--found"), 1600)
  }

  _clearSearch() {
    if (!this.hasSearchInputTarget) return
    this.searchInputTarget.value = ""
    this.searchResultsTarget.hidden = true
    this.searchResultsTarget.innerHTML = ""
  }

  _sexRank(node) { return node?.sex === "M" ? 0 : node?.sex === "F" ? 1 : 2 }

  // --- Camera (pan & zoom) ----------------------------------------------------

  // Initial camera: zoom out (never in) until the whole tree fits the canvas,
  // floored at MIN_FIT. If even that can't contain it, fall back to centring the
  // focus card — panning beats a confetti-scale overview.
  _fitToView() {
    const vw  = this.element.clientWidth,     vh = this.element.clientHeight
    const w   = this.innerTarget.offsetWidth, h  = this.innerTarget.offsetHeight
    const fit = Math.min(vw / w, vh / h, 1)
    this._scale = Math.max(fit, MIN_FIT)
    if (fit >= MIN_FIT) {
      this._pan = { x: (vw - w * this._scale) / 2, y: (vh - h * this._scale) / 2 }
      this._applyTransform()
    } else {
      this._centerOn(this.graphValue.focus_id)
    }
  }

  _centerOn(focusId, animate = false) {
    const p = this._pos[focusId]
    if (p) this._panTo(p.cx, p.y + NODE_H / 2, animate)
  }

  // Place a tree-space point at the centre of the viewport.
  _panTo(cx, cy, animate = false) {
    this._pan = {
      x: this.element.clientWidth  / 2 - cx * this._scale,
      y: this.element.clientHeight / 2 - cy * this._scale
    }
    this._applyTransform(animate)
  }

  // Screen position of the focus card, captured before a re-flow so we can pin it.
  _anchorScreen() {
    const p = this._pos[this.graphValue.focus_id]
    if (!p) return null
    return { sx: this._pan.x + p.cx * this._scale, sy: this._pan.y + (p.y + NODE_H / 2) * this._scale }
  }

  _restoreAnchor(a) {
    if (!a) return
    const p = this._pos[this.graphValue.focus_id]
    if (!p) return
    this._pan = { x: a.sx - p.cx * this._scale, y: a.sy - (p.y + NODE_H / 2) * this._scale }
  }

  _bindPanZoom() {
    this._boundMove = this._onMove.bind(this)
    this._boundUp   = this._onUp.bind(this)
    this.element.addEventListener("pointerdown", this._onDown.bind(this))
    this.element.addEventListener("wheel",       this._onWheel.bind(this), { passive: false })
    window.addEventListener("pointermove",       this._boundMove)
    window.addEventListener("pointerup",         this._boundUp)
  }

  _onDown(e) {
    if (e.target.closest("a, button, .tree-search")) return   // let controls through
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

  // Zoom anchored at the cursor: the tree-space point under the pointer stays put.
  _onWheel(e) {
    e.preventDefault()
    const rect = this.element.getBoundingClientRect()
    const mx   = e.clientX - rect.left, my = e.clientY - rect.top
    const next = Math.max(0.2, Math.min(4, this._scale * (e.deltaY < 0 ? 1.1 : 0.9)))
    const k    = next / this._scale
    this._pan.x = mx - (mx - this._pan.x) * k
    this._pan.y = my - (my - this._pan.y) * k
    this._scale = next
    this._applyTransform()
  }

  _applyTransform(animate = false) {
    const inner = this.innerTarget
    inner.style.transformOrigin = "0 0"
    inner.style.transition = animate ? "transform .45s ease" : ""
    inner.style.transform =
      `translate(${this._pan.x}px, ${this._pan.y}px) scale(${this._scale})`
  }
}
