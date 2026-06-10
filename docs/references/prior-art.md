---
title: Prior Art — what we learn & borrow
tags: [reference, research]
status: stable
---

# Prior Art — what we learn from, and exactly what we take

We don't copy code (licenses differ; stacks differ). We **borrow proven design**. Honest map
of who does what well. Ties into [[features-index]].

## Genealogy domain & UX (study the model, not the code)
- **webtrees** (PHP) — the gold standard of web genealogy. **Take:** collaboration model,
  the excellent **privacy/living-person system** ([[privacy-access]]), full GEDCOM handling,
  statistics. The bar for features.
- **Gramps / Gramps Web** (Python) — best desktop data model. **Take:** evidence-first design —
  sources/citations/confidence as first-class ([[sources-evidence]], [[source-citation]]),
  events-over-columns ([[event]]).
- **GeneWeb** (OCaml) — **Take:** relationship-calculator / relationship-graph ideas
  ([[relationship]]).
- **Liberu Genealogy** (Laravel/PHP) — **Take:** sanity-check on a modern MVC implementation
  of the same domain.

## Tree rendering (the JS we'll wrap in Stimulus — see [[tree-rendering]])
- **donatso/family-chart** (d3, MIT, vanilla JS) — **Take:** interaction model (zoom/pan,
  node styling); closest to drop-in for our [[adr/0005-tree-rendering-svg-stimulus]] approach.
- **PeWu/topola** (d3, TS) — **Take:** the chart-type taxonomy (ancestors / descendants /
  hourglass / relatives) for [[family-tree-view]]; proven on real trees (webtrees addon).
- **BenPortner/js_family_tree** (d3-dag) — **Take:** handling genealogy as a true multi-parent
  DAG.

## Rails / Hotwire / SaaS patterns (architecture, not domain)
- **Writebook** (37signals) — **Take:** the *taste* of a canonical small Rails 8 app
  (controllers, current-user auth, CSS organization). Our baseline style — at `~/dhh-references/writebook`.
- **Maybe** (`maybe-finance`, MIT) — **Take:** modern, complex Rails+Hotwire patterns. ⚠️ Uses
  Tailwind + Postgres — ignore those; we stay vanilla ([[stack]]).
- **Solidus / Spree** — **Take:** open-core **Rails Engine** modularity for our [[open-core]]
  split.
- **Bullet Train** — **Take:** SaaS infra patterns — teams, roles, billing, [[multi-tenancy]].

## Honest note
No single project is a "complex Writebook for genealogy." Most large Rails apps use
Tailwind/Postgres/JS-frameworks; our pure-vanilla stack ([[adr/0001-vanilla-rails-stack]]) means
we borrow *ideas* widely but trailblaze the *implementation*.
