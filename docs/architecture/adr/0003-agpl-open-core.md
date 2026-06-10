---
title: ADR 0003 — AGPL-3.0 open core
tags: [adr, business, license]
status: accepted
---

# ADR 0003 — AGPL-3.0 + open-core model

**Status:** Accepted · **Date:** 2026-06-10

## Context
We want a genuinely open, self-hostable core ([[vision]]) **and** a sustainable paid hosted
business ([[pricing-hosting]]). A permissive license (MIT) would let a competitor host our
exact app as a closed SaaS and capture the hosting revenue.

## Decision
- License the **core** under **AGPL-3.0**: free to use, modify, self-host; anyone running a
  modified version as a network service must share their changes.
- Keep **paid/hosted-only** capabilities (billing, advanced multi-tenant ops) in a **private
  Rails Engine** layered on top — the open-core split. See [[open-core]].

## Consequences
- ➕ Protects the hosting business while staying truly open for self-hosters.
- ➕ Engine boundary forces clean modularity (learn from Solidus — [[prior-art]]).
- ➖ AGPL deters some corporate adopters; acceptable for a consumer/prosumer product.
- ➖ Must keep a disciplined boundary so AGPL core ≠ proprietary Engine bleed. Consider a CLA
  if external contributions arrive.
