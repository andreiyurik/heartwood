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
- **Родовое древо (whole clan)** — the full descendancy from the род's progenitor; the
  one "entire family at once" view that stays a clean tree. See below.
- **Hourglass** — ancestors + descendants of one person at once. *Later.*
- **Relatives / fan chart** — later.

## Родовое древо — the whole-clan view (`/tree`, `ClanTreesController`)

A whole род is really a *graph* (marriages join lines, remarriage and cousin marriage make
diamonds), so there is no single tidy layout for "everyone at once". The honest, intuitive
answer is to render the **full descendancy from one progenitor** — the one case where the род
*is* a tree — and lean on navigation (click-to-refocus, depth, pan/zoom) for the rest.

- **Progenitor** = `Tree#root_person`: the parentless ancestor with the most descendants
  (ties → earliest birth → id). Computed, not stored, so it tracks the data. From any person
  you can still open their own ancestors/descendants; the clan view is the shared landing.
- **Layout** reuses `descendant_graph` + `unions` at a generous fixed depth (`CLAN_DEPTH`),
  so couples and married-in spouses render exactly as in the descendants view.
- **Trade-offs (deliberate v1 scope):** only the largest line from the top progenitor is
  shown — disconnected components and in-law branches aren't merged into one picture; a manual
  progenitor override and multi-line/forest rendering are future work.

## Navigation: collapse/expand & search-fly

Both live in `tree_controller.js` and work in every tree view (person and clan), since they
operate on the already-loaded graph — no extra requests.

- **Collapse / expand.** Each branchable unit shows a small pill at its growth-facing edge:
  `−` folds the branch, `+N` (N = hidden people) unfolds it. Folding treats the unit as a leaf
  in the tidy pass and hides its descendant cards, so a big род stays readable. The focus card
  is pinned on screen across the re-flow, so the view doesn't jump. State is per-session
  (client-only); the graph itself is unchanged.
- **Search-fly.** A floating "Find a person…" box filters the loaded nodes by name; picking a
  result expands the path to that person (in case they were folded away), centres the camera on
  their card with a smooth pan, and flashes it briefly. Living/redacted nodes are excluded from
  results (they have no real name to match).

At very large scale (10k+ people, [[roadmap]] Phase 3) the next step is *server-side* depth
windowing / lazy "load more" so the client isn't shipped the whole graph at once — "don't build
it until the tree view needs it".

## Interactions (must feel effortless)
- Pan & zoom, click a node → its [[person-profile]] (loaded into a Turbo Frame side panel).
- Re-center on any person. Expand/collapse branches.
- Add a relative directly from a node (opens an edit frame).

## The honest constraint
Hotwire does not draw graphs. Genealogy layout is a real algorithm (it's a graph — see
[[domain-model]]). So this view = **SVG edges + a hand-written layout engine** wrapped in **one
Stimulus controller** (`tree_controller.js`); nodes are **server-rendered HTML partials**
(`trees/_node`) positioned by the controller. This keeps data + interactivity on Rails and
confines JS to the math. We deliberately use **no layout library** (no d3/dagre/elkjs): the
importmap/no-build constraint means the tidy-tree algorithm is written by hand, compact and
dependency-free. Full rationale in [[tree-rendering]] and [[adr/0005-tree-rendering-svg-stimulus]].

## Layout model (current)

A **vertical tidy tree** (Reingold–Tilford in spirit). Generations are horizontal rows; X
within a row comes from a post-order pass so a parent sits centred over its children and
sibling subtrees never overlap.

- **Orientation.** Descendants: focus on top, generations grow downward (`y = gen·ROW_H`).
  Ancestors: focus at the bottom, generations grow upward (`y = (maxGen − gen)·ROW_H`) so the
  oldest generation is on top — the genealogical "top-down" read.
- **Units, not people.** The layout works on *units*: a **couple** (two partner cards joined by
  a short horizontal connector) or a **single** person. The tidy pass treats a unit as one
  block of width 1 or 2 cards. When a parent unit is wider than its children's span (a couple
  over a lone child), the children are shifted to stay centred — correctness (no overlap) first,
  aesthetics second.
- **Hierarchy from `edges`, grouping from `unions`.** The parent→child structure is the
  server's `edges` (`from_id` = layout-parent/focus-side, `to_id` = layout-child, in both
  modes) lifted onto units; `unions` only decide which cards sit side-by-side. First edge into
  a unit wins, so a person reached twice via pedigree collapse is placed once (spanning tree).
- **Edges.** Vertical béziers from a parent unit's centre to each child unit's centre, drawn in
  the growth direction. A couple's two cards are joined by a short horizontal connector; their
  children descend from the connector's midpoint.
- **Viewport.** Pan/zoom live in the controller; on load the view centres on the focus card.

## Couples model (`unions`)

`Person#collect_unions` derives couples from `Family` (the source of truth on pairs and
children) and adds them to the graph as
`unions: [{ partner_ids: [a, b], child_ids: [...] }]`. Only people present in the current
traversal appear; partner ordering on screen is male-left then by id (calm, deterministic).
Privacy is unchanged — a living partner renders as a redacted "Living" card like any other node.

Edge cases (handled explicitly):

- **Ancestors.** Both parents of a node are already in the graph (the `parents` neighbour
  returns both), so the union is essentially free — they're paired over their child.
- **Descendants — married-in spouse.** A spouse who married into the line is *not* a blood
  descendant, so the BFS never reaches them. `collect_unions` pulls them in at their partner's
  generation as a leaf (no ancestors on this side) and pairs them. They still respect privacy.
- **Single / unknown parent.** A family with one partner yields no union — a plain single card,
  never a phantom partner.
- **Remarriage.** Each person occupies exactly one couple block: ancestors uses their parents'
  family; descendants uses the marriage that produced the visible descendants
  (`union_family_for`). Children of a *second* marriage still appear (they're blood
  descendants, linked via `edges`) but the additional spouse is not drawn in v1. Multi-union
  blocks are a deliberate future extension, not a bug.
- **DAG / pedigree collapse.** A person reachable by two paths is placed once (spanning tree;
  first parent edge wins).

## Performance note
Large trees (10k+ people) need a cached adjacency/snapshot — see [[relationship]] "when we do
materialize." Don't build it until the tree view needs it (Phase 3, [[roadmap]]).
