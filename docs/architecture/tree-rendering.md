---
title: Tree Rendering
tags: [architecture, hard, hotwire]
status: draft
---

# Tree Rendering

How we draw the [[family-tree-view]] without betraying the vanilla [[stack]]. Decision recorded
in [[adr/0005-tree-rendering-svg-stimulus]].

## The problem
Genealogy is a **graph**, not a simple tree (see [[domain-model]]): two parents, multiple
unions, shared children. Layout (positioning nodes + routing edges) is a genuine algorithm.
Hotwire exchanges HTML; it does not compute graph layouts.

## The approach: SVG + layout engine + one Stimulus controller
```
Rails computes the sub-graph to show (ancestors/descendants of focus person)
        │  derived via [[relationship]] traversal; cached for big trees
        ▼
Server renders node HTML partials (avatar, name, dates)  ──► Turbo Frames
        │
        ▼
One Stimulus controller runs the layout (positions) + pan/zoom on an <svg>/<div> canvas
        │  layout engine: hand-written tidy tree (no library) — see [[family-tree-view]]
        ▼
Click a node → load [[person-profile]] into a side Turbo Frame. Edit → Turbo Stream back.
```
This keeps **data, content, and interactivity on Rails**, and confines JS to **just the math**.

## Library options evaluated (decision: none — hand-written tidy tree, see [[family-tree-view]])
- **elkjs** — powerful general graph layout (good for messy genealogy graphs).
- **dagre** — simpler directed-graph layout.
- **d3-hierarchy / d3-dag** — d3-based; `d3-dag` handles multi-parent DAGs.
- Reference renderers to learn from (not necessarily adopt): **family-chart**, **Topola**,
  **js_family_tree** — see [[prior-art]]. They prove the SVG+d3 path; we wrap the chosen
  approach in Stimulus rather than importing a framework.

## Why not just use a ready React/JS family-tree component?
Because it would drag in a build pipeline and break the thesis ([[adr/0001-vanilla-rails-stack]]),
and detach nodes from Turbo (losing inline edit/live updates). A Stimulus-wrapped layout keeps
nodes as real DOM/Turbo Frames.

## Performance
For 10k+ node trees, precompute and cache adjacency (closure table / snapshot — see
[[relationship]]). Render only the visible sub-graph; expand on demand.
