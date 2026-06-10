---
title: Family (FAM)
tags: [domain, entity]
aliases: [FAM, Union]
status: draft
---

# Family (`FAM`)

The structural hub that makes the graph work. Part of [[domain-model]].

> A **Family** is **not** a household — it is a node connecting one or two **partners** and
> their shared **children**. It exists so that [[person]] records never point at each other
> directly; all kinship is derived through Family. This is the GEDCOM model.

## Why it exists
- One person can be in several Family records (remarriage, children with different partners).
- A child links to the Family of their parents, giving them two parents cleanly.
- Marriage/divorce are [[event]] records attached to the **Family**, not a person.

## Key fields (sketch)
- `gedcom_xref` — original `@F45@` id for round-trip [[gedcom]].
- partner links: typically two, but support one-parent families and same-sex unions.

## Associations
- has_many partner links → [[person]] (role: husband/wife/partner; keep flexible)
- has_many child links → [[person]] (with GEDCOM `PEDI`: birth/adopted/foster)
- has_many [[event]] (marriage `MARR`, divorce `DIV`, etc., polymorphic `eventable`)
- has_many [[source-citation]]

## Notes
- Model partner/child links as **join models** (`FamilyPartner`, `FamilyChild`) so we can
  attach metadata (pedigree type, role, ordering of children by birth).
- Children are ordered (usually by birth) — keep an explicit position for display in
  [[family-tree-view]].
