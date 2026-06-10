---
title: Multi-tenancy (self-host vs hosted)
tags: [architecture, saas]
status: draft
---

# Multi-tenancy — one codebase, two deployments

How the same open core powers both free self-host and the paid hosted plan, without forking.
See [[open-core]], [[pricing-hosting]], [[vision]] principle #5.

## Two deployment modes
| | **Self-host** | **Hosted (paid)** |
|--|--------------|-------------------|
| Tenancy | Single-tenant (one family/instance) | Multi-tenant (many accounts) |
| DB | One **SQLite** file | SQLite-per-tenant *or* shared Postgres — decide in Phase 6 |
| Storage | Local disk | S3-compatible |
| Billing | none | private Engine — see [[open-core]] |
| Ops | the user | us |

## Design rule: tenancy is a thin, additive layer
- The core models (the [[domain-model]]) carry no tenancy assumptions in single-tenant mode.
- The hosted layer adds an `Account`/tenant scope and request-time tenant resolution, as a
  **private Rails Engine** mounted on top — never a change to core semantics.
- **SQLite-per-tenant** is attractive and very on-brand (each family = one file, easy backup &
  export, strong isolation). Evaluate against operational complexity at scale in Phase 6;
  Rails 8.1 multi-DB + Solid Queue make per-tenant DBs viable.

## Why this matters now
Even though tenancy is Phase 6 ([[roadmap]]), we must **not** bake single-tenant assumptions
so deep that adding the hosted layer means a rewrite. Keep tenant resolution at the edge;
keep core code tenant-agnostic.
