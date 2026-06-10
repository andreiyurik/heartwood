---
title: Heartwood — Documentation Home
tags: [moc, home]
status: stable
---

# 🌳 Heartwood — Documentation Home

> The living core of your family tree — open, yours, built to last generations.

This is the **Map of Content (MOC)** for the Heartwood vault. It is written to be read by
**both humans and AI agents** (single source of truth, Markdown, interlinked). If you are an
agent, also read [`AGENTS.md`](../AGENTS.md) at the repo root.

## Start here

- [[vision]] — why Heartwood exists, the principles, the bet
- [[glossary]] — domain vocabulary (GEDCOM-aligned)
- [[roadmap]] — what we build, in what order

## The four pillars

### 1. Domain — what we model
- [[domain-model]] — the heart of the app: people as a *graph*, not a tree
- Entities: [[person]] · [[family]] · [[relationship]] · [[event]] · [[source-citation]] · [[place]] · [[media]]

### 2. Features — what users do
- [[features-index]] — curated & prioritized feature catalog (borrowed from the best)

### 3. Interop — getting data in & out (our moat)
- [[gedcom]] — the accepted exchange format (GEDCOM 7 + 5.5.1)
- [[import-export]] — strategy, Rails 8.1 pipeline, other formats

### 4. Architecture — how it's built
- [[stack]] — canonical vanilla Rails 8.1 stack & constraints
- [[rails8-features]] — each Rails 8/8.1 capability → a concrete use (used to the fullest)
- [[tree-rendering]] — the one hard part, the Hotwire way
- [[hotwire-native]] — one codebase → web + iOS + Android (SPA-feel, no SPA)
- [[multi-tenancy]] — self-host vs hosted on one codebase
- Decisions: `architecture/adr/` — [[adr/0001-vanilla-rails-stack|0001]] · [[adr/0002-sqlite-production|0002]] · [[adr/0003-agpl-open-core|0003]] · [[adr/0004-gedcom-interop|0004]] · [[adr/0005-tree-rendering-svg-stimulus|0005]] · [[adr/0006-hotwire-native-ready|0006]]

## Business
- [[open-core]] — what's free vs paid, the AGPL + Engine split
- [[pricing-hosting]] — the hosted plan

## Learning from others
- [[prior-art]] — webtrees, Gramps, GeneWeb, family-chart, Topola, Maybe, Solidus — and exactly what we take from each

---
*Vault conventions: atomic notes, `[[wikilinks]]`, YAML frontmatter. Edit the vault, not chat — it is the source of truth.*
