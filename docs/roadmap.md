---
title: Roadmap
tags: [planning, roadmap]
status: draft
---

# Roadmap

Sequenced so each phase ships something real and testable. Priorities use MoSCoW
(Must / Should / Could / Won't-yet). Tie-ins to [[features-index]].

## Phase 0 — Foundation ✅ (done)
- Canonical Rails 8.1 skeleton, AGPL, README, this docs vault. See [[stack]].

## Phase 1 — Domain & first vertical slice (Must)
- ✅ Core entities: [[person]], [[family]] (+ FamilyPartner/FamilyChild), [[event]];
  [[relationship]] derived (parents/children/siblings/partners). TDD, green.
- ✅ Built-in Rails 8 authentication (no Devise).
- ✅ Person CRUD + list, vanilla CSS, morphing-first nav.
- ✅ Minitest from day one (36 tests, 106 assertions).
- ⏭️ Remaining slice: **add relatives & events via the UI** (inline "add parent/child/spouse",
  birth/death forms) — the next natural step before Phase 2.

## Phase 2 — Interop (Must — this is the moat)
- [[gedcom]] **import** (tolerant 5.5.1 + 7) via Active Storage → Solid Queue → Turbo Streams progress.
- [[gedcom]] **export** (7.0). Round-trip test: import → export → re-import is stable.
- See [[import-export]].

## Phase 3 — The tree view (Must)
- [[family-tree-view]]: pedigree + descendancy, SVG + layout engine in one Stimulus
  controller. Nodes are server-rendered partials in Turbo Frames. See [[tree-rendering]].

## Phase 4 — Evidence & media (Should)
- [[source-citation]] as first-class. [[media]] via Active Storage. [[place]] normalization.

## Phase 5 — Collaboration & privacy (Should)
- [[collaboration]]: multiple editors, live updates via Turbo Streams over Solid Cable.
- [[privacy-access]]: living-person privacy, per-record visibility, share links.

## Phase 6 — Hosted SaaS layer (Should)
- [[multi-tenancy]], [[pricing-hosting]], billing as a private Rails Engine. See [[open-core]].

## Later / Could
- Smart hints & matching across trees, search ranking, reports/PDF, place maps, timeline view.

## Won't-yet
- DNA analysis, mobile native apps, real-time chat.
