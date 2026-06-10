---
title: ADR 0002 — SQLite in production
tags: [adr, architecture, database]
status: accepted
---

# ADR 0002 — SQLite in production

**Status:** Accepted (with a hosted-scale review point) · **Date:** 2026-06-10

## Context
Rails 8.1 hardened SQLite for production (WAL, tuned defaults, Solid adapters on SQLite).
Our primary deployment is **single-family self-host** ([[multi-tenancy]]).

## Decision
Use **SQLite in development and production**. For self-host it is ideal: zero external
services, the DB is a single file (trivial backup, and a natural complement to [[gedcom]]
export).

## Consequences
- ➕ Zero-ops self-host; "the database is a file."
- ➕ Solid Queue/Cache/Cable all run on it — no Redis ([[stack]]).
- ➖ The **hosted, multi-tenant** plan may need a different strategy — SQLite-per-tenant or
  Postgres. **Open** until Phase 6; see [[multi-tenancy]]. This ADR covers self-host + early
  hosted; revisit before scaling the SaaS.
