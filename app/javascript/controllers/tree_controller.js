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

  #boundMove
  #boundUp
  #collapsed
  #drag
  #kb
  #mmScale
  #nodeById
  #pan
  #persistT
  #pinch
  #pointers
  #pos
  #root
  #scale
  #toggleLayer
  #unitOf
  #units

  connect() {
    this.#scale     = 1
    this.#collapsed = new Set()   // ids of units whose children are folded away
    this.#pointers  = new Map()   // active pointers, for one-finger pan / two-finger pinch
    this.#build()
    if (!this.#units.length) return

    this.#toggleLayer = document.createElement("div")
    this.#toggleLayer.className = "tree-toggles"
    this.innerTarget.appendChild(this.#toggleLayer)

    const saved = this.#loadState()
    if (saved) this.#restoreCollapsed(saved.collapsed)
    else       this.#autoCollapse()
    this.#relayout()
    if (saved?.camera) {
      this.#scale = saved.camera.scale
      this.#pan   = { x: saved.camera.x, y: saved.camera.y }
      this.#applyTransform()
    } else {
      this.#fitToView()
    }
    this.#bindPanZoom()
  }

  disconnect() {
    clearTimeout(this.#persistT)
    window.removeEventListener("pointermove",   this.#boundMove)
    window.removeEventListener("pointerup",     this.#boundUp)
    window.removeEventListener("pointercancel", this.#boundUp)
  }

  // A saved view is dropped when the graph changed, so a stale view never hides fresh data.
  #stateKey() {
    return `heartwood:tree:${this.graphValue.focus_id}:${this.modeValue}:${this.depthValue}`
  }

  #unitKey(u) { return u.members.slice().sort((a, b) => a - b).join("+") }

  #loadState() {
    try {
      const raw = localStorage.getItem(this.#stateKey())
      if (!raw) return null
      const state = JSON.parse(raw)
      return state.n === this.graphValue.nodes.length ? state : null
    } catch { return null }
  }

  #restoreCollapsed(keys) {
    if (!keys?.length) return
    const byKey = new Map(this.#units.map(u => [ this.#unitKey(u), u.id ]))
    for (const k of keys) if (byKey.has(k)) this.#collapsed.add(byKey.get(k))
  }

  #autoCollapse() {
    const people = this.graphValue.nodes.filter(n => !n.ghost).length
    if (people <= AUTO_COLLAPSE_MIN) return
    const walk = (u, row) => {
      if (row >= AUTO_ROWS && u.children.length && this.#countSubtree(u)) {
        this.#collapsed.add(u.id)
        return
      }
      for (const c of u.children) walk(c, row + 1)
    }
    walk(this.#root, 0)
  }

  #persist() {
    clearTimeout(this.#persistT)
    this.#persistT = setTimeout(() => {
      try {
        localStorage.setItem(this.#stateKey(), JSON.stringify({
          n:         this.graphValue.nodes.length,
          collapsed: [ ...this.#collapsed ].map(id => this.#unitKey(this.#units[id])),
          camera:    { x: this.#pan.x, y: this.#pan.y, scale: this.#scale }
        }))
      } catch {}   // storage full or unavailable — the view just won't be remembered
    }, 300)
  }

  #build() {
    const { nodes, edges, focus_id } = this.graphValue
    const unions = this.graphValue.unions || []
    if (!nodes.length) { this.#units = []; return }

    const { units, unitOf, nodeById } = this.#buildUnits(nodes, unions)
    this.#linkUnits(units, unitOf, edges, nodeById)

    this.#units    = units
    this.#unitOf   = unitOf
    this.#nodeById = nodeById
    this.#root     = unitOf.get(focus_id)
    for (const u of units) this.#countSubtree(u)
  }

  // Partners are ordered male-left; ties fall back to id so the layout is deterministic.
  #buildUnits(nodes, unions) {
    const nodeById = new Map(nodes.map(n => [n.id, n]))
    const unitOf   = new Map()
    const units    = []

    const make = (memberIds) => {
      const members = memberIds.slice().sort((a, b) =>
        this.#sexRank(nodeById.get(a)) - this.#sexRank(nodeById.get(b)) || a - b)
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
  #linkUnits(units, unitOf, edges, nodeById) {
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
  #countSubtree(u) {
    if (u.subtreeCount != null) return u.subtreeCount
    let n = 0
    for (const c of u.children) {
      n += c.members.filter(id => !this.#nodeById.get(id).ghost).length + this.#countSubtree(c)
    }
    return u.subtreeCount = n
  }

  #relayout() {
    this.#markVisible()
    this.#assignX(this.#root)
    this.#assignY()
    this.#pos = this.#placeCards()
    this.#resize()
    this.#placeNodes()
    this.#drawEdges()
    this.#drawToggles()
    this.#drawMiniMap()
  }

  #markVisible() {
    for (const u of this.#units) u.visible = false
    const walk = (u) => {
      u.visible = true
      if (this.#collapsed.has(u.id)) return
      for (const c of u.children) walk(c)
    }
    walk(this.#root)
  }

  // A collapsed unit is a leaf. A parent wider than its children's span shifts them to stay centred.
  #assignX(root) {
    const place = (u, left) => {
      const w    = this.#unitWidth(u)
      const kids = this.#collapsed.has(u.id) ? [] : u.children
      if (!kids.length) { u.cx = left + w / 2; return w }

      let cursor = left
      for (const c of kids) cursor += place(c, cursor) + SIBLING_GAP
      const childrenW = cursor - SIBLING_GAP - left
      const center    = (kids[0].cx + kids[kids.length - 1].cx) / 2

      if (childrenW >= w) { u.cx = center; return childrenW }
      this.#shift(kids, (w - childrenW) / 2)
      u.cx = left + w / 2
      return w
    }
    place(root, 0)
  }

  #shift(children, dx) {
    for (const c of children) { c.cx += dx; this.#shift(c.children, dx) }
  }

  #assignY() {
    const vis    = this.#units.filter(u => u.visible)
    const maxGen = Math.max(...vis.map(u => this.#gen(u)))
    const rowOf  = u => this.modeValue === "ancestors" ? maxGen - this.#gen(u) : this.#gen(u)

    const rowH = []
    for (const u of vis) {
      u.h = this.#unitHeight(u)
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

  #gen(u)        { return this.#nodeById.get(u.members[0]).generation }
  #unitWidth(u)  { return u.members.length === 2 ? CARD_W * 2 + PAIR_GAP : CIRC_D }
  #unitHeight(u) { return u.members.length === 2 ? CARD_H : CIRC_D }

  #placeCards() {
    const pos = {}
    const vis = this.#units.filter(u => u.visible)
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

  #resize() {
    const cards = Object.values(this.#pos)
    const maxX  = Math.max(...cards.map(p => p.x + p.w))
    const maxY  = Math.max(...this.#units.filter(u => u.visible).map(u => u.y + u.h))
    const w = maxX + PAD, h = maxY + PAD
    this.innerTarget.style.width  = `${w}px`
    this.innerTarget.style.height = `${h}px`
    this.svgTarget.setAttribute("width",  w)
    this.svgTarget.setAttribute("height", h)
  }

  #placeNodes() {
    for (const el of this.nodeTargets) {
      const pos = this.#pos[+el.dataset.treeNodeId]
      if (pos) {
        el.style.display   = ""
        el.style.transform = `translate(${pos.x}px, ${pos.y}px)`
      } else {
        el.style.display = "none"
      }
    }
  }

  #drawEdges() {
    this.svgTarget.innerHTML = ""
    for (const u of this.#units) {
      if (!u.visible) continue
      if (u.members.length === 2) this.#connector(u)
      if (this.#collapsed.has(u.id)) continue
      for (const c of u.children) this.#link(u, c)
    }
  }

  #connector(u) {
    const [a, b] = u.members
    const x1 = this.#pos[a].cx + this.#pos[a].w / 2
    const x2 = this.#pos[b].cx - this.#pos[b].w / 2
    const y  = u.y + u.h / 2
    this.#path(`M${x1},${y} L${x2},${y}`, "tree-edge tree-edge--bond")
    this.#heart(u.cx, y)
  }

  #heart(x, y) {
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

  #link(parent, child) {
    const px = parent.cx, cx = child.cx
    const py = parent.y + parent.h / 2, cy = child.y + child.h / 2
    const dir  = Math.sign(cy - py) || 1
    const edge = py + dir * parent.h / 2
    const y1   = parent.members.length === 2 ? py : edge
    const y2   = cy - dir * child.h / 2
    const my   = (edge + y2) / 2
    this.#path(`M${px},${y1} L${px},${my} L${cx},${my} L${cx},${y2}`)
  }

  #path(d, cls = "tree-edge") {
    const path = document.createElementNS(SVG_NS, "path")
    path.setAttribute("d", d)
    path.setAttribute("class", cls)
    this.svgTarget.appendChild(path)
  }

  #drawToggles() {
    this.#toggleLayer.innerHTML = ""
    const dir = this.modeValue === "ancestors" ? -1 : 1

    for (const u of this.#units) {
      // No toggle when only ghost slots are below.
      if (!u.visible || !u.children.length || !this.#countSubtree(u)) continue
      const collapsed = this.#collapsed.has(u.id)

      const btn = document.createElement("button")
      btn.type      = "button"
      btn.className = `tree-toggle${collapsed ? " tree-toggle--collapsed" : ""}`
      btn.textContent = collapsed ? `+${u.subtreeCount}` : "−"
      const label = collapsed ? this.expandLabelValue : this.collapseLabelValue
      btn.setAttribute("aria-label", label)
      btn.title = label
      btn.style.left = `${u.cx}px`
      btn.style.top  = `${u.y + u.h / 2 + dir * (u.h / 2 + 14)}px`
      btn.addEventListener("click", (e) => { e.stopPropagation(); this.#toggle(u.id) })
      this.#toggleLayer.appendChild(btn)
    }
  }

  // Keeps the focus card pinned on screen so the view doesn't jump on re-flow.
  #toggle(id) {
    const anchor = this.#anchorScreen()
    this.#collapsed.has(id) ? this.#collapsed.delete(id) : this.#collapsed.add(id)
    this.#relayout()
    this.#restoreAnchor(anchor)
    this.#applyTransform()
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

    this.#dimExcept(q ? new Set(found.map(n => n.id)) : null)

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
      li.addEventListener("click", () => this.#flyTo(m.id))
      li.addEventListener("keydown", (e) => { if (e.key === "Enter") this.#flyTo(m.id) })
      list.appendChild(li)
    }
    list.hidden = false
  }

  #dimExcept(matchIds) {
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
      this.#clearSearch()
    }
  }

  #flyTo(id) {
    this.#reveal(id)
    this.#relayout()
    this.#scale = 1
    const p = this.#pos[id]
    if (p) this.#panTo(p.cx, p.y + p.h / 2, true)
    this.#flash(id)
    this.#clearSearch()
  }

  #reveal(id) {
    let u = this.#unitOf.get(id)?.parent
    while (u) { this.#collapsed.delete(u.id); u = u.parent }
  }

  #flash(id) {
    const el = this.nodeTargets.find(e => +e.dataset.treeNodeId === id)
    if (!el) return
    el.classList.add("tree-node--found")
    setTimeout(() => el.classList.remove("tree-node--found"), 1600)
  }

  #clearSearch() {
    if (!this.hasSearchInputTarget) return
    this.searchInputTarget.value = ""
    this.searchResultsTarget.hidden = true
    this.searchResultsTarget.innerHTML = ""
    this.#dimExcept(null)
  }

  #sexRank(node) { return node?.sex === "M" ? 0 : node?.sex === "F" ? 1 : 2 }

  print() {
    const restore = { pan: { ...this.#pan }, scale: this.#scale }
    const after = () => {
      window.removeEventListener("afterprint", after)
      this.element.classList.remove("tree-canvas--print")
      this.#pan   = restore.pan
      this.#scale = restore.scale
      this.#applyTransform()
    }
    window.addEventListener("afterprint", after)

    this.element.classList.add("tree-canvas--print")
    const pageWidth = 720
    this.#scale = Math.min(1, pageWidth / this.innerTarget.offsetWidth)
    this.#pan   = { x: 0, y: 0 }
    this.#applyTransform()
    this.element.style.setProperty("--print-h", `${this.innerTarget.offsetHeight * this.#scale}px`)
    window.print()
  }

  keydown(e) {
    if (e.target.closest("input, textarea, select, [contenteditable]")) return
    if (e.key === "+" || e.key === "=") { e.preventDefault(); return this.zoomIn() }
    if (e.key === "-")                  { e.preventDefault(); return this.zoomOut() }
    if (![ "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Enter" ].includes(e.key)) return
    e.preventDefault()

    if (!this.#kb) this.#kb = this.#kbStart()
    if (e.key === "Enter") { this.#kbEl()?.querySelector("a")?.click(); return }

    const next = this.#kbNext(e.key)
    if (next) this.#kb = next
    this.#kbHighlight()
  }

  #kbStart() {
    const u = this.#unitOf.get(this.graphValue.focus_id) || this.#root
    return { u, m: Math.max(0, u.members.indexOf(this.graphValue.focus_id)) }
  }

  // Spatially honest steps: in ancestors mode the layout's "children" sit above.
  #kbNext(key) {
    const { u, m } = this.#kb
    const upIsChild = this.modeValue === "ancestors"
    const toParent  = () => u.parent?.visible ? { u: u.parent, m: 0 } : null
    const toChild   = () => {
      if (this.#collapsed.has(u.id)) return null
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

  #kbEl() {
    const id = this.#kb.u.members[this.#kb.m]
    return this.nodeTargets.find(el => +el.dataset.treeNodeId === id)
  }

  #kbHighlight() {
    for (const el of this.nodeTargets) el.classList.remove("tree-node--kb")
    const el = this.#kbEl()
    if (!el) return
    el.classList.add("tree-node--kb")

    const id = this.#kb.u.members[this.#kb.m]
    const p  = this.#pos[id]
    if (!p) return
    const sx = this.#pan.x + p.cx * this.#scale
    const sy = this.#pan.y + (p.y + p.h / 2) * this.#scale
    const vw = this.element.clientWidth, vh = this.element.clientHeight
    if (sx < 60 || sx > vw - 60 || sy < 60 || sy > vh - 60) {
      this.#panTo(p.cx, p.y + p.h / 2, true)
    }
  }

  // Falls back to centring the focus card when even MIN_FIT can't contain the tree.
  #fitToView() {
    const vw  = this.element.clientWidth,     vh = this.element.clientHeight
    const w   = this.innerTarget.offsetWidth, h  = this.innerTarget.offsetHeight
    const fit = Math.min(vw / w, vh / h, 1)
    this.#scale = Math.max(fit, MIN_FIT)
    if (fit >= MIN_FIT) {
      this.#pan = { x: (vw - w * this.#scale) / 2, y: (vh - h * this.#scale) / 2 }
      this.#applyTransform()
    } else {
      this.#centerOn(this.graphValue.focus_id)
    }
  }

  #centerOn(focusId, animate = false) {
    const p = this.#pos[focusId]
    if (p) this.#panTo(p.cx, p.y + p.h / 2, animate)
  }

  #panTo(cx, cy, animate = false) {
    this.#pan = {
      x: this.element.clientWidth  / 2 - cx * this.#scale,
      y: this.element.clientHeight / 2 - cy * this.#scale
    }
    this.#applyTransform(animate)
  }

  #anchorScreen() {
    const p = this.#pos[this.graphValue.focus_id]
    if (!p) return null
    return { sx: this.#pan.x + p.cx * this.#scale, sy: this.#pan.y + (p.y + p.h / 2) * this.#scale }
  }

  #restoreAnchor(a) {
    if (!a) return
    const p = this.#pos[this.graphValue.focus_id]
    if (!p) return
    this.#pan = { x: a.sx - p.cx * this.#scale, y: a.sy - (p.y + p.h / 2) * this.#scale }
  }

  #bindPanZoom() {
    this.#boundMove = this.#onMove.bind(this)
    this.#boundUp   = this.#onUp.bind(this)
    this.element.addEventListener("pointerdown", this.#onDown.bind(this))
    this.element.addEventListener("wheel",       this.#onWheel.bind(this), { passive: false })
    window.addEventListener("pointermove",       this.#boundMove)
    window.addEventListener("pointerup",         this.#boundUp)
    window.addEventListener("pointercancel",     this.#boundUp)
  }

  #onDown(e) {
    if (e.target.closest("a, button, .tree-search, .tree-drawer, .tree-minimap")) return
    e.preventDefault()
    this.#pointers.set(e.pointerId, { x: e.clientX, y: e.clientY })
    if (this.#pointers.size === 2) {
      this.#drag  = null
      this.#pinch = this.#pinchStart()
    } else if (this.#pointers.size === 1) {
      this.#drag = { x0: e.clientX - this.#pan.x, y0: e.clientY - this.#pan.y }
    }
  }

  #onMove(e) {
    if (!this.#pointers.has(e.pointerId)) return
    this.#pointers.set(e.pointerId, { x: e.clientX, y: e.clientY })

    if (this.#pinch && this.#pointers.size >= 2) {
      // Keep the point grabbed at pinch start pinned to the moving midpoint.
      const { dist, mid } = this.#pinchNow()
      const next = this.#clampScale(this.#pinch.scale0 * dist / this.#pinch.dist0)
      this.#scale = next
      this.#pan   = { x: mid.x - this.#pinch.p0.x * next, y: mid.y - this.#pinch.p0.y * next }
      this.#applyTransform()
    } else if (this.#drag) {
      this.#pan.x = e.clientX - this.#drag.x0
      this.#pan.y = e.clientY - this.#drag.y0
      this.#applyTransform()
    }
  }

  #onUp(e) {
    this.#pointers.delete(e.pointerId)
    if (this.#pointers.size < 2) this.#pinch = null
    if (this.#pointers.size === 1) {
      // Hand the camera to the remaining finger without a jump.
      const p = this.#pointers.values().next().value
      this.#drag = { x0: p.x - this.#pan.x, y0: p.y - this.#pan.y }
    } else if (!this.#pointers.size) {
      this.#drag = null
    }
  }

  #pinchStart() {
    const { dist, mid } = this.#pinchNow()
    return {
      dist0:  dist,
      scale0: this.#scale,
      p0:     { x: (mid.x - this.#pan.x) / this.#scale, y: (mid.y - this.#pan.y) / this.#scale }
    }
  }

  #pinchNow() {
    const [ a, b ] = [ ...this.#pointers.values() ]
    const rect = this.element.getBoundingClientRect()
    return {
      dist: Math.hypot(a.x - b.x, a.y - b.y) || 1,
      mid:  { x: (a.x + b.x) / 2 - rect.left, y: (a.y + b.y) / 2 - rect.top }
    }
  }

  #onWheel(e) {
    e.preventDefault()
    const rect = this.element.getBoundingClientRect()
    this.#zoomAt(e.clientX - rect.left, e.clientY - rect.top,
                 this.#scale * (e.deltaY < 0 ? 1.1 : 0.9))
  }

  zoomIn()  { this.#zoomBy(1.2) }
  zoomOut() { this.#zoomBy(1 / 1.2) }
  zoomFit() { this.#fitToView() }

  #zoomBy(k) {
    this.#zoomAt(this.element.clientWidth / 2, this.element.clientHeight / 2, this.#scale * k)
  }

  #zoomAt(mx, my, scale) {
    const next = this.#clampScale(scale)
    const k    = next / this.#scale
    this.#pan.x = mx - (mx - this.#pan.x) * k
    this.#pan.y = my - (my - this.#pan.y) * k
    this.#scale = next
    this.#applyTransform()
  }

  #clampScale(s) { return Math.max(0.2, Math.min(4, s)) }

  #applyTransform(animate = false) {
    const inner = this.innerTarget
    inner.style.transformOrigin = "0 0"
    inner.style.transition = animate ? "transform .45s ease" : ""
    inner.style.transform =
      `translate(${this.#pan.x}px, ${this.#pan.y}px) scale(${this.#scale})`
    this.#persist()
    this.#drawMiniMap()
  }

  // Only shown while the tree overflows the canvas; otherwise it would repeat the picture.
  #drawMiniMap() {
    if (!this.hasMinimapTarget || !this.#pos || !this.#pan) return
    const mm = this.minimapTarget
    const vw = this.element.clientWidth,     vh = this.element.clientHeight
    const tw = this.innerTarget.offsetWidth, th = this.innerTarget.offsetHeight
    const fits = tw * this.#scale <= vw + 1 && th * this.#scale <= vh + 1
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
    this.#mmScale = k

    const rootStyle = getComputedStyle(document.documentElement)
    const inkEdge   = rootStyle.getPropertyValue("--tree-edge").trim() || "#b3a695"
    const inkAccent = rootStyle.getPropertyValue("--accent").trim()    || "#5a7d4f"

    for (const [ id, p ] of Object.entries(this.#pos)) {
      const node = this.#nodeById.get(+id)
      if (node?.ghost) continue
      ctx.fillStyle = +id === this.graphValue.focus_id ? inkAccent : inkEdge
      ctx.fillRect(p.x * k, p.y * k, Math.max(p.w * k, 2), Math.max(p.h * k, 2))
    }

    ctx.strokeStyle = inkAccent
    ctx.lineWidth   = 1.5
    ctx.strokeRect(-this.#pan.x / this.#scale * k, -this.#pan.y / this.#scale * k,
                   vw / this.#scale * k, vh / this.#scale * k)
  }

  minimapJump(e) {
    if (!this.#mmScale) return
    const rect = this.minimapTarget.getBoundingClientRect()
    this.#panTo((e.clientX - rect.left) / this.#mmScale,
                (e.clientY - rect.top)  / this.#mmScale)
  }
}
