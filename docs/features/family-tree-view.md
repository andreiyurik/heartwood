---
title: Family Tree View
tags: [feature, ui, hard]
status: draft
---

# Family Tree View

The signature UI and the **one genuinely hard part**. Part of [[features-index]] (Must).
Implementation approach: [[tree-rendering]].

## Chart types (borrowed from Topola — see [[prior-art]])
- **Pedigree / ancestors** — parents, grandparents… of a focus person.
- **Descendancy** — children, grandchildren…
- **Hourglass** — ancestors + descendants of one person at once.
- **Relatives / fan chart** — later.

## Interactions (must feel effortless)
- Pan & zoom, click a node → its [[person-profile]] (loaded into a Turbo Frame side panel).
- Re-center on any person. Expand/collapse branches.
- Add a relative directly from a node (opens an edit frame).

## The honest constraint
Hotwire does not draw graphs. Genealogy layout is a real algorithm (it's a graph — see
[[domain-model]]). So this view = **SVG + a layout engine** (elkjs/dagre/d3) wrapped in **one
Stimulus controller**; nodes are **server-rendered HTML partials** placed via Turbo Frames.
This keeps data + interactivity on Rails and confines JS to the math. Full rationale and
options in [[tree-rendering]] and [[adr/0005-tree-rendering-svg-stimulus]].

## Performance note
Large trees (10k+ people) need a cached adjacency/snapshot — see [[relationship]] "when we do
materialize." Don't build it until the tree view needs it (Phase 3, [[roadmap]]).
