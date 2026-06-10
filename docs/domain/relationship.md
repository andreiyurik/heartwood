---
title: Relationship (derived)
tags: [domain, entity]
status: draft
---

# Relationship (derived)

Part of [[domain-model]]. Convenience layer **on top of** [[family]] — not the source of truth.

## The principle
We do **not** store direct person→person relationship rows as the canonical data (that would
duplicate and desync from [[family]]). Instead we *derive* relationships by traversing Family
records:

- **Parents of P** = partners of the Family where P is a child.
- **Children of P** = children of every Family where P is a partner.
- **Siblings of P** = other children of P's parents' Family.
- **Spouses/partners of P** = other partners of Families where P is a partner.
- **Cousins, ancestors, descendants** = graph traversal from there.

## Why derive instead of store
- Single source of truth → no contradictions (the classic genealogy data bug).
- Lossless [[gedcom]] round-trip (GEDCOM stores it this way too).
- Relationship *calculator* (e.g. "second cousin once removed") is a pure traversal.

## When we *do* materialize
- For **performance** on big trees, cache derived adjacency (e.g. a closure table or a
  cached `tree_snapshot`) — but as a *derived cache*, rebuildable from Family. Decide in
  Phase 3 when [[tree-rendering]] needs it; premature for Phase 1.

## Related
- Powers [[family-tree-view]] traversals and the relationship calculator feature in
  [[features-index]].
