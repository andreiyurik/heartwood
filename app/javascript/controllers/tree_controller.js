import { Controller } from "@hotwired/stimulus"

// Tidy-tree layout written by hand (no d3/dagre): a post-order pass centres parents over children.
// It works on *units*: a couple (two cards joined by a bond) or a lone person (a circle).

// Sizes must match tree.css (.tree-node--card and .tree-node--circle).
const CARD_W      = 210   // .tree-node--card width
const CARD_H      = 100   // .tree-node--card height (band + name + dates)
const CIRC_D      = 160   // .tree-node--circle diameter
const MIN_FIT     = 0.35  // fit-to-view floor — below this a huge tree is confetti
const PAIR_GAP    = 26    // gap between the two cards of a couple (fits the ♥)
const SIBLING_GAP = 40    // gap between adjacent units in a row
const ROW_GAP     = 70    // vertical gap between generation rows
const PAD         = 60    // breathing room around the laid-out tree
const SVG_NS      = "http://www.w3.org/2000/svg"

// Above this many people the far branches load folded, so a huge род opens readable.
const AUTO_COLLAPSE_MIN = 60
const AUTO_ROWS         = 3

export default class extends Controller {
  static targets = ["inner", "svg", "node", "searchInput", "searchResults", "minimap"]
  static values  = {
    graph:         Object,
    mode:          String,
    depth:         Number,
    expandLabel:   String,
    collapseLabel: String
  }

  connect() {
    this._scale     = 1
    this._collapsed = new Set()   // ids of units whose children are folded away
    this._pointers  = new Map()   // active pointers, for one-finger pan / two-finger pinch
    this._build()
    if (!this._units.length) return

    this._toggleLayer = document.createElement("div")
    this._toggleLayer.className = "tree-toggles"
    this.innerTarget.appendChild(this._toggleLayer)

    const saved = this._loadState()
    if (saved) this._restoreCollapsed(saved.collapsed)
    else       this._autoCollapse()
    this._relayout()
    if (saved?.camera) {
      this._scale = saved.camera.scale
      this._pan   = { x: saved.camera.x, y: saved.camera.y }
      this._applyTransform()
    } else {
      this._fitToView()
    }
    this._bindPanZoom()
  }

  disconnect() {
    clearTimeout(this._persistT)
    window.removeEventListener("pointermove",   this._boundMove)
    window.removeEventListener("pointerup",     this._boundUp)
    window.removeEventListener("pointercancel", this._boundUp)
  }

  // A saved view is dropped when the graph changed, so a stale view never hides fresh data.
  _stateKey() {
    return `heartwood:tree:${this.graphValue.focus_id}:${this.modeValue}:${this.depthValue}`
  }

  _unitKey(u) { return u.members.slice().sort((a, b) => a - b).join("+") }

  _loadState() {
    try {
      const raw = localStorage.getItem(this._stateKey())
      if (!raw) return null
      const state = JSON.parse(raw)
      return state.n === this.graphValue.nodes.length ? state : null
    } catch { return null }
  }

  _restoreCollapsed(keys) {
    if (!keys?.length) return
    const byKey = new Map(this._units.map(u => [ this._unitKey(u), u.id ]))
    for (const k of keys) if (byKey.has(k)) this._collapsed.add(byKey.get(k))
  }

  _autoCollapse() {
    const people = this.graphValue.nodes.filter(n => !n.ghost).length
    if (people <= AUTO_COLLAPSE_MIN) return
    const walk = (u, row) => {
      if (row >= AUTO_ROWS && u.children.length && this._countSubtree(u)) {
        this._collapsed.add(u.id)
        return
      }
      for (const c of u.children) walk(c, row + 1)
    }
    walk(this._root, 0)
  }

  _persist() {
    clearTimeout(this._persistT)
    this._persistT = setTimeout(() => {
      try {
        localStorage.setItem(this._stateKey(), JSON.stringify({
          n:         this.graphValue.nodes.length,
          collapsed: [ ...this._collapsed ].map(id => this._unitKey(this._units[id])),
          camera:    { x: this._pan.x, y: this._pan.y, scale: this._scale }
        }))
      } catch {}   // storage full or unavailable — the view just won't be remembered
    }, 300)
  }

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

  // Partners are ordered male-left; ties fall back to id so the layout is deterministic.
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

  // First edge into a unit wins, so a person reached twice via pedigree collapse is placed once.
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

  // Ghost add-relative slots don't count: they aren't people.
  _countSubtree(u) {
    if (u.subtreeCount != null) return u.subtreeCount
    let n = 0
    for (const c of u.children) {
      n += c.members.filter(id => !this._nodeById.get(id).ghost).length + this._countSubtree(c)
    }
    return u.subtreeCount = n
  }

  _relayout() {
    this._markVisible()
    this._assignX(this._root)
    this._assignY()
    this._pos = this._placeCards()
    this._resize()
    this._placeNodes()
    this._drawEdges()
    this._drawToggles()
    this._drawMiniMap()
  }

  _markVisible() {
    for (const u of this._units) u.visible = false
    const walk = (u) => {
      u.visible = true
      if (this._collapsed.has(u.id)) return
      for (const c of u.children) walk(c)
    }
    walk(this._root)
  }

  // A collapsed unit is a leaf. A parent wider than its children's span shifts them to stay centred.
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

  _assignY() {
    const vis    = this._units.filter(u => u.visible)
    const maxGen = Math.max(...vis.map(u => this._gen(u)))
    const rowOf  = u => this.modeValue === "ancestors" ? maxGen - this._gen(u) : this._gen(u)

    const rowH = []
    for (const u of vis) {
      u.h = this._unitHeight(u)
      const r = rowOf(u)
      rowH[r] = Math.max(rowH[r] || 0, u.h)
    }

    const rowY = []
    let y = 0
    for (let r = 0; r < rowH.length; r++) { rowY[r] = y; y += (rowH[r] || 0) + ROW_GAP }

    for (const u of vis) {
      const r = rowOf(u)
      u.y = rowY[r] + (rowH[r] - u.h) / 2
    }
  }

  _gen(u)        { return this._nodeById.get(u.members[0]).generation }
  _unitWidth(u)  { return u.members.length === 2 ? CARD_W * 2 + PAIR_GAP : CIRC_D }
  _unitHeight(u) { return u.members.length === 2 ? CARD_H : CIRC_D }

  _placeCards() {
    const pos = {}
    const vis = this._units.filter(u => u.visible)
    for (const u of vis) {
      if (u.members.length === 2) {
        const off = (CARD_W + PAIR_GAP) / 2
        pos[u.members[0]] = { cx: u.cx - off, y: u.y, w: CARD_W, h: CARD_H }
        pos[u.members[1]] = { cx: u.cx + off, y: u.y, w: CARD_W, h: CARD_H }
      } else {
        pos[u.members[0]] = { cx: u.cx, y: u.y, w: CIRC_D, h: CIRC_D }
      }
    }

    const cards = Object.values(pos)
    const minX  = Math.min(...cards.map(p => p.cx - p.w / 2))
    const minY  = Math.min(...vis.map(u => u.y))
    const dx = PAD - minX, dy = PAD - minY
    for (const p of cards) { p.cx += dx; p.x = p.cx - p.w / 2; p.y += dy }
    for (const u of vis)   { u.cx += dx; u.y += dy }
    return pos
  }

  _resize() {
    const cards = Object.values(this._pos)
    const maxX  = Math.max(...cards.map(p => p.x + p.w))
    const maxY  = Math.max(...this._units.filter(u => u.visible).map(u => u.y + u.h))
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
        el.style.display = "none"
      }
    }
  }

  _drawEdges() {
    this.svgTarget.innerHTML = ""
    for (const u of this._units) {
      if (!u.visible) continue
      if (u.members.length === 2) this._connector(u)
      if (this._collapsed.has(u.id)) continue
      for (const c of u.children) this._link(u, c)
    }
  }

  _connector(u) {
    const [a, b] = u.members
    const x1 = this._pos[a].cx + this._pos[a].w / 2
    const x2 = this._pos[b].cx - this._pos[b].w / 2
    const y  = u.y + u.h / 2
    this._path(`M${x1},${y} L${x2},${y}`, "tree-edge tree-edge--bond")
    this._heart(u.cx, y)
  }

  _heart(x, y) {
    const bg = document.createElementNS(SVG_NS, "circle")
    bg.setAttribute("cx", x)
    bg.setAttribute("cy", y)
    bg.setAttribute("r", 10)
    bg.setAttribute("class", "tree-heart-bg")
    const glyph = document.createElementNS(SVG_NS, "text")
    glyph.setAttribute("x", x)
    glyph.setAttribute("y", y)
    glyph.setAttribute("class", "tree-heart")
    glyph.textContent = "♥"
    this.svgTarget.append(bg, glyph)
  }

  _link(parent, child) {
    const px = parent.cx, cx = child.cx
    const py = parent.y + parent.h / 2, cy = child.y + child.h / 2
    const dir  = Math.sign(cy - py) || 1
    const edge = py + dir * parent.h / 2
    const y1   = parent.members.length === 2 ? py : edge
    const y2   = cy - dir * child.h / 2
    const my   = (edge + y2) / 2
    this._path(`M${px},${y1} L${px},${my} L${cx},${my} L${cx},${y2}`)
  }

  _path(d, cls = "tree-edge") {
    const path = document.createElementNS(SVG_NS, "path")
    path.setAttribute("d", d)
    path.setAttribute("class", cls)
    this.svgTarget.appendChild(path)
  }

  _drawToggles() {
    this._toggleLayer.innerHTML = ""
    const dir = this.modeValue === "ancestors" ? -1 : 1

    for (const u of this._units) {
      // No toggle when only ghost slots are below.
      if (!u.visible || !u.children.length || !this._countSubtree(u)) continue
      const collapsed = this._collapsed.has(u.id)

      const btn = document.createElement("button")
      btn.type      = "button"
      btn.className = `tree-toggle${collapsed ? " tree-toggle--collapsed" : ""}`
      btn.textContent = collapsed ? `+${u.subtreeCount}` : "−"
      const label = collapsed ? this.expandLabelValue : this.collapseLabelValue
      btn.setAttribute("aria-label", label)
      btn.title = label
      btn.style.left = `${u.cx}px`
      btn.style.top  = `${u.y + u.h / 2 + dir * (u.h / 2 + 14)}px`
      btn.addEventListener("click", (e) => { e.stopPropagation(); this._toggle(u.id) })
      this._toggleLayer.appendChild(btn)
    }
  }

  // Keeps the focus card pinned on screen so the view doesn't jump on re-flow.
  _toggle(id) {
    const anchor = this._anchorScreen()
    this._collapsed.has(id) ? this._collapsed.delete(id) : this._collapsed.add(id)
    this._relayout()
    this._restoreAnchor(anchor)
    this._applyTransform()
  }

  search() {
    if (!this.hasSearchResultsTarget) return
    const q    = this.searchInputTarget.value.trim().toLowerCase()
    const list = this.searchResultsTarget
    list.innerHTML = ""

    const found = q
      ? this.graphValue.nodes
          .filter(n => !n.living && !n.ghost && n.name && n.name.toLowerCase().includes(q))
      : []

    this._dimExcept(q ? new Set(found.map(n => n.id)) : null)

    const matches = found.slice(0, 8)
    if (!matches.length) { list.hidden = true; return }
    for (const m of matches) {
      const li = document.createElement("li")
      const name = document.createElement("span")
      name.textContent = m.name
      li.appendChild(name)
      if (m.years) {
        const years = document.createElement("span")
        years.className = "tree-search-years"
        years.textContent = m.years
        li.appendChild(years)
      }
      li.tabIndex = 0
      li.addEventListener("click", () => this._flyTo(m.id))
      li.addEventListener("keydown", (e) => { if (e.key === "Enter") this._flyTo(m.id) })
      list.appendChild(li)
    }
    list.hidden = false
  }

  _dimExcept(matchIds) {
    for (const el of this.nodeTargets) {
      const id = +el.dataset.treeNodeId
      el.classList.toggle("tree-node--dim", !!matchIds && !matchIds.has(id))
    }
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
    this._reveal(id)
    this._relayout()
    this._scale = 1
    const p = this._pos[id]
    if (p) this._panTo(p.cx, p.y + p.h / 2, true)
    this._flash(id)
    this._clearSearch()
  }

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
    this._dimExcept(null)
  }

  _sexRank(node) { return node?.sex === "M" ? 0 : node?.sex === "F" ? 1 : 2 }

  print() {
    const restore = { pan: { ...this._pan }, scale: this._scale }
    const after = () => {
      window.removeEventListener("afterprint", after)
      this.element.classList.remove("tree-canvas--print")
      this._pan   = restore.pan
      this._scale = restore.scale
      this._applyTransform()
    }
    window.addEventListener("afterprint", after)

    this.element.classList.add("tree-canvas--print")
    const pageWidth = 720
    this._scale = Math.min(1, pageWidth / this.innerTarget.offsetWidth)
    this._pan   = { x: 0, y: 0 }
    this._applyTransform()
    this.element.style.setProperty("--print-h", `${this.innerTarget.offsetHeight * this._scale}px`)
    window.print()
  }

  keydown(e) {
    if (e.target.closest("input, textarea, select, [contenteditable]")) return
    if (e.key === "+" || e.key === "=") { e.preventDefault(); return this.zoomIn() }
    if (e.key === "-")                  { e.preventDefault(); return this.zoomOut() }
    if (![ "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Enter" ].includes(e.key)) return
    e.preventDefault()

    if (!this._kb) this._kb = this._kbStart()
    if (e.key === "Enter") { this._kbEl()?.querySelector("a")?.click(); return }

    const next = this._kbNext(e.key)
    if (next) this._kb = next
    this._kbHighlight()
  }

  _kbStart() {
    const u = this._unitOf.get(this.graphValue.focus_id) || this._root
    return { u, m: Math.max(0, u.members.indexOf(this.graphValue.focus_id)) }
  }

  // Spatially honest steps: in ancestors mode the layout's "children" sit above.
  _kbNext(key) {
    const { u, m } = this._kb
    const upIsChild = this.modeValue === "ancestors"
    const toParent  = () => u.parent?.visible ? { u: u.parent, m: 0 } : null
    const toChild   = () => {
      if (this._collapsed.has(u.id)) return null
      const c = u.children.find(c => c.visible)
      return c ? { u: c, m: 0 } : null
    }

    switch (key) {
      case "ArrowUp":   return upIsChild ? toChild()  : toParent()
      case "ArrowDown": return upIsChild ? toParent() : toChild()
      case "ArrowLeft":
      case "ArrowRight": {
        const dir = key === "ArrowLeft" ? -1 : 1
        if (u.members.length === 2 && (m + dir === 0 || m + dir === 1)) return { u, m: m + dir }
        const sibs = u.parent ? u.parent.children.filter(c => c.visible) : [ u ]
        const next = sibs[sibs.indexOf(u) + dir]
        return next ? { u: next, m: dir === -1 ? next.members.length - 1 : 0 } : null
      }
    }
  }

  _kbEl() {
    const id = this._kb.u.members[this._kb.m]
    return this.nodeTargets.find(el => +el.dataset.treeNodeId === id)
  }

  _kbHighlight() {
    for (const el of this.nodeTargets) el.classList.remove("tree-node--kb")
    const el = this._kbEl()
    if (!el) return
    el.classList.add("tree-node--kb")

    const id = this._kb.u.members[this._kb.m]
    const p  = this._pos[id]
    if (!p) return
    const sx = this._pan.x + p.cx * this._scale
    const sy = this._pan.y + (p.y + p.h / 2) * this._scale
    const vw = this.element.clientWidth, vh = this.element.clientHeight
    if (sx < 60 || sx > vw - 60 || sy < 60 || sy > vh - 60) {
      this._panTo(p.cx, p.y + p.h / 2, true)
    }
  }

  // Falls back to centring the focus card when even MIN_FIT can't contain the tree.
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
    if (p) this._panTo(p.cx, p.y + p.h / 2, animate)
  }

  _panTo(cx, cy, animate = false) {
    this._pan = {
      x: this.element.clientWidth  / 2 - cx * this._scale,
      y: this.element.clientHeight / 2 - cy * this._scale
    }
    this._applyTransform(animate)
  }

  _anchorScreen() {
    const p = this._pos[this.graphValue.focus_id]
    if (!p) return null
    return { sx: this._pan.x + p.cx * this._scale, sy: this._pan.y + (p.y + p.h / 2) * this._scale }
  }

  _restoreAnchor(a) {
    if (!a) return
    const p = this._pos[this.graphValue.focus_id]
    if (!p) return
    this._pan = { x: a.sx - p.cx * this._scale, y: a.sy - (p.y + p.h / 2) * this._scale }
  }

  _bindPanZoom() {
    this._boundMove = this._onMove.bind(this)
    this._boundUp   = this._onUp.bind(this)
    this.element.addEventListener("pointerdown", this._onDown.bind(this))
    this.element.addEventListener("wheel",       this._onWheel.bind(this), { passive: false })
    window.addEventListener("pointermove",       this._boundMove)
    window.addEventListener("pointerup",         this._boundUp)
    window.addEventListener("pointercancel",     this._boundUp)
  }

  _onDown(e) {
    if (e.target.closest("a, button, .tree-search, .tree-drawer, .tree-minimap")) return
    e.preventDefault()
    this._pointers.set(e.pointerId, { x: e.clientX, y: e.clientY })
    if (this._pointers.size === 2) {
      this._drag  = null
      this._pinch = this._pinchStart()
    } else if (this._pointers.size === 1) {
      this._drag = { x0: e.clientX - this._pan.x, y0: e.clientY - this._pan.y }
    }
  }

  _onMove(e) {
    if (!this._pointers.has(e.pointerId)) return
    this._pointers.set(e.pointerId, { x: e.clientX, y: e.clientY })

    if (this._pinch && this._pointers.size >= 2) {
      // Keep the point grabbed at pinch start pinned to the moving midpoint.
      const { dist, mid } = this._pinchNow()
      const next = this._clampScale(this._pinch.scale0 * dist / this._pinch.dist0)
      this._scale = next
      this._pan   = { x: mid.x - this._pinch.p0.x * next, y: mid.y - this._pinch.p0.y * next }
      this._applyTransform()
    } else if (this._drag) {
      this._pan.x = e.clientX - this._drag.x0
      this._pan.y = e.clientY - this._drag.y0
      this._applyTransform()
    }
  }

  _onUp(e) {
    this._pointers.delete(e.pointerId)
    if (this._pointers.size < 2) this._pinch = null
    if (this._pointers.size === 1) {
      // Hand the camera to the remaining finger without a jump.
      const p = this._pointers.values().next().value
      this._drag = { x0: p.x - this._pan.x, y0: p.y - this._pan.y }
    } else if (!this._pointers.size) {
      this._drag = null
    }
  }

  _pinchStart() {
    const { dist, mid } = this._pinchNow()
    return {
      dist0:  dist,
      scale0: this._scale,
      p0:     { x: (mid.x - this._pan.x) / this._scale, y: (mid.y - this._pan.y) / this._scale }
    }
  }

  _pinchNow() {
    const [ a, b ] = [ ...this._pointers.values() ]
    const rect = this.element.getBoundingClientRect()
    return {
      dist: Math.hypot(a.x - b.x, a.y - b.y) || 1,
      mid:  { x: (a.x + b.x) / 2 - rect.left, y: (a.y + b.y) / 2 - rect.top }
    }
  }

  _onWheel(e) {
    e.preventDefault()
    const rect = this.element.getBoundingClientRect()
    this._zoomAt(e.clientX - rect.left, e.clientY - rect.top,
                 this._scale * (e.deltaY < 0 ? 1.1 : 0.9))
  }

  zoomIn()  { this._zoomBy(1.2) }
  zoomOut() { this._zoomBy(1 / 1.2) }
  zoomFit() { this._fitToView() }

  _zoomBy(k) {
    this._zoomAt(this.element.clientWidth / 2, this.element.clientHeight / 2, this._scale * k)
  }

  _zoomAt(mx, my, scale) {
    const next = this._clampScale(scale)
    const k    = next / this._scale
    this._pan.x = mx - (mx - this._pan.x) * k
    this._pan.y = my - (my - this._pan.y) * k
    this._scale = next
    this._applyTransform()
  }

  _clampScale(s) { return Math.max(0.2, Math.min(4, s)) }

  _applyTransform(animate = false) {
    const inner = this.innerTarget
    inner.style.transformOrigin = "0 0"
    inner.style.transition = animate ? "transform .45s ease" : ""
    inner.style.transform =
      `translate(${this._pan.x}px, ${this._pan.y}px) scale(${this._scale})`
    this._persist()
    this._drawMiniMap()
  }

  // Only shown while the tree overflows the canvas; otherwise it would repeat the picture.
  _drawMiniMap() {
    if (!this.hasMinimapTarget || !this._pos || !this._pan) return
    const mm = this.minimapTarget
    const vw = this.element.clientWidth,     vh = this.element.clientHeight
    const tw = this.innerTarget.offsetWidth, th = this.innerTarget.offsetHeight
    const fits = tw * this._scale <= vw + 1 && th * this._scale <= vh + 1
    mm.classList.toggle("tree-minimap--hidden", fits)
    if (fits) return

    const dpr  = window.devicePixelRatio || 1
    const cssW = mm.offsetWidth, cssH = mm.offsetHeight
    mm.width  = cssW * dpr
    mm.height = cssH * dpr
    const ctx = mm.getContext("2d")
    ctx.scale(dpr, dpr)
    ctx.clearRect(0, 0, cssW, cssH)

    const k = Math.min(cssW / tw, cssH / th)
    this._mmScale = k

    const rootStyle = getComputedStyle(document.documentElement)
    const inkEdge   = rootStyle.getPropertyValue("--tree-edge").trim() || "#b3a695"
    const inkAccent = rootStyle.getPropertyValue("--accent").trim()    || "#5a7d4f"

    for (const [ id, p ] of Object.entries(this._pos)) {
      const node = this._nodeById.get(+id)
      if (node?.ghost) continue
      ctx.fillStyle = +id === this.graphValue.focus_id ? inkAccent : inkEdge
      ctx.fillRect(p.x * k, p.y * k, Math.max(p.w * k, 2), Math.max(p.h * k, 2))
    }

    ctx.strokeStyle = inkAccent
    ctx.lineWidth   = 1.5
    ctx.strokeRect(-this._pan.x / this._scale * k, -this._pan.y / this._scale * k,
                   vw / this._scale * k, vh / this._scale * k)
  }

  minimapJump(e) {
    if (!this._mmScale) return
    const rect = this.minimapTarget.getBoundingClientRect()
    this._panTo((e.clientX - rect.left) / this._mmScale,
                (e.clientY - rect.top)  / this._mmScale)
  }
}
