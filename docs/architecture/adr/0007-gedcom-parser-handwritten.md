---
title: ADR 0007 — Hand-written GEDCOM line parser
tags: [adr, interop, gedcom]
status: accepted
---

# ADR 0007 — Hand-written GEDCOM line parser

**Status:** Accepted · **Date:** 2026-06-10

## Context

Phase 2 requires parsing GEDCOM 5.5.1 and 7.0 files (see [[gedcom]], [[adr/0004-gedcom-interop]]).
We evaluated available Ruby gems before deciding:

- **`ruby-gedcom`** — unmaintained (last commit 2014), no GEDCOM 7 support.
- **`gedcom-ruby`** — covers 5.5.1 but no 7.0; callback-based API that doesn't fit our pipeline.
- **`ged_com`** — tiny, incomplete, no active development.

None fit the [[stack]] vanilla rule: "before adding any dependency, check it against these rules."
Adding an unmaintained gem for a core feature that forms our [[moat]] is unacceptable.

## Decision

Write a **small hand-written line parser** (`Gedcom::Parser`) in ~60–80 lines of plain Ruby.

GEDCOM's line grammar is trivially regular:
```
LEVEL [XREF] TAG [VALUE]
```
where `LEVEL` is a single digit (0–9, or two digits in 7.0), `XREF` is `@...@`, and `VALUE`
is everything after TAG to end-of-line. No backtracking, no nesting rules at the lexer level —
the hierarchy is implicit in level numbers and is resolved in a second pass into a record tree.

## Consequences

- ➕ **Zero gem dependencies** — stays 100% vanilla.
- ➕ **Full control** — tolerant parsing (warn & continue on bad lines) and GEDCOM 7.0 header
  handling implemented exactly as our pipeline needs.
- ➕ **Testable in isolation** — pure Ruby, no Rails required.
- ➖ We own the parser code. Mitigation: GEDCOM line grammar is stable and well-documented;
  the parser is intentionally small and covered by exhaustive unit tests.
