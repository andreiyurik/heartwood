---
title: ADR 0005 — Tree rendering via SVG + Stimulus
tags: [adr, architecture, frontend]
status: accepted
---

# ADR 0005 — Tree rendering via SVG + one Stimulus controller

**Status:** Accepted · **Date:** 2026-06-10

## Context
The [[family-tree-view]] is the signature UI and the only part needing real graph-layout
computation. The vanilla-Rails thesis ([[adr/0001-vanilla-rails-stack]]) forbids a JS-framework
SPA. Genealogy is a graph ([[domain-model]]).

## Decision
Render the tree as **SVG**, with a **single Stimulus controller** running a **layout engine**
(elkjs / dagre / d3-dag — chosen in Phase 3) for positioning + pan/zoom. Tree **nodes are
server-rendered HTML partials** placed via Turbo Frames; clicking a node loads the
[[person-profile]] into a side frame. Full design: [[tree-rendering]].

## Alternatives rejected
- **Ready-made React/JS family-tree component** — drags in a build pipeline (breaks
  [[stack]]) and detaches nodes from Turbo (loses inline edit + live updates).
- **Server-only SVG (no JS)** — can't do smooth pan/zoom/expand interactions users expect.

## Consequences
- ➕ JS confined to layout math; data/content/interactivity stay on Rails + Hotwire.
- ➕ Nodes remain real DOM → inline editing and [[collaboration]] live updates work.
- ➖ One nontrivial Stimulus controller to own and test; layout engine choice is a Phase-3
  spike. Reference renderers in [[prior-art]] de-risk it.
