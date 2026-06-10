---
title: ADR 0004 — GEDCOM interop strategy
tags: [adr, interop]
status: accepted
---

# ADR 0004 — GEDCOM interop strategy

**Status:** Accepted · **Date:** 2026-06-10

## Context
Data portability is the moat ([[vision]] #1). Users arrive from Ancestry / MyHeritage /
Gramps / FamilySearch and must be able to leave too. Format landscape in [[gedcom]].

## Decision
- **Export:** GEDCOM **7.0**, plus **GEDZIP** (tree + [[media]]) for full portable backups.
- **Import:** tolerant parsing of **both 5.5.1 and 7.0** (5.5.1 is what most legacy apps emit).
- **Never drop data:** unknown/custom tags are preserved in a raw store and surfaced, not
  discarded.
- **Stable round-trip:** preserve original `@xref@` ids (`gedcom_xref` across the
  [[domain-model]]); import→export→import must be stable — a Phase-2 acceptance test.

## Consequences
- ➕ Frictionless onboarding from competitors; credible exit builds trust.
- ➕ Showcases the vanilla [[stack]] (Active Storage → Solid Queue → Turbo Streams) — see
  [[import-export]].
- ➖ Perfect losslessness is impossible (vendor quirks, ANSEL, custom tags); we mitigate with
  the never-drop-data rule, not by promising perfection.
