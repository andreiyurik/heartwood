---
title: ADR 0001 — Canonical vanilla Rails 8 stack
tags: [adr, architecture]
status: accepted
---

# ADR 0001 — Canonical vanilla Rails 8 stack

**Status:** Accepted · **Date:** 2026-06-10

## Context
We are building a reference-quality ("эталонное") Rails 8 app ([[vision]]) that ordinary
people can self-host for years. The dominant industry default is a JS-framework SPA + API.

## Decision
Build a **canonical vanilla Rails 8.1 app**: Hotwire, vanilla CSS, Propshaft + importmap,
**no Node, no Tailwind, no Redis, no RSpec**. See [[stack]] for the full list.

## Consequences
- ➕ Dramatically simpler to self-host and keep alive long-term; one cohesive codebase.
- ➕ Faster perceived UX than typical SPAs for this content-heavy, form-driven domain.
- ➕ Legible to humans *and* AI agents — fewer layers.
- ➖ Few large public reference apps use this exact purity; we're partly trailblazing
  (see [[prior-art]] honest note).
- ➖ The [[family-tree-view]] needs a JS exception — sanctioned and confined
  ([[adr/0005-tree-rendering-svg-stimulus]]).
- Any deviation requires a new ADR.
