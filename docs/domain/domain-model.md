---
title: Domain Model
tags: [moc, domain]
status: draft
---

# Domain Model

> The single most important architectural decision in the app. Get this right and the rest
> follows. See [[vision]] principle #1 and #4.

## The core insight: a family tree is a *graph*, not a tree

A naive "tree" (each node has one parent) cannot represent reality: people have two parents,
multiple marriages, children across unions, adoptions, unknown parents. Every mature system
(webtrees, Gramps, GEDCOM itself) solves this the same way — via an intermediate
**[[family]]** record:

```
[[person]] ──(as partner)──► [[family]] ◄──(as partner)── [[person]]
                                  │
                            (as child)
                                  ▼
                              [[person]]
```

So relationships are **derived through Family records**, not stored as direct person→person
edges. This is the GEDCOM model and it makes [[gedcom]] import/export natural. See
[[relationship]] for how we expose convenient derived relationships on top.

## Entities

| Entity | GEDCOM | Role | Note |
|--------|--------|------|------|
| [[person]] | `INDI` | A human being | The vertex |
| [[family]] | `FAM` | Links partners + children | The structural hub |
| [[relationship]] | — | Derived/typed edges | Convenience over Family |
| [[event]] | `EVEN` | Birth, death, marriage… | Time + place + sources |
| [[source-citation]] | `SOUR` | Evidence for claims | First-class, not optional |
| [[place]] | `PLAC` | Normalized location | Hierarchical |
| [[media]] | `OBJE` | Photos, scans, docs | Active Storage |

## Modeling principles

- **GEDCOM-shaped, not GEDCOM-bound.** Our schema mirrors GEDCOM's structure so interop is
  lossless, but uses idiomatic Rails (real FKs, polymorphic associations, enums) internally.
- **Events over columns.** Don't put `birth_date`/`death_date` columns on Person. Model them
  as [[event]] rows. This handles "approx 1850", "before 1900", multiple conflicting sources,
  and uncommon events without schema churn. (Gramps does this; it's the right call.)
- **Every fact can cite a source.** A birth date is a *claim*; it links to [[source-citation]].
- **Soft, additive schema.** Genealogy data is messy and incomplete by nature. Nullable,
  tolerant, never lose imported data even if we don't fully understand it yet.

## Open questions (to resolve in Phase 1)

- Same-table vs polymorphic for events on Person vs Family? (Lean: polymorphic `eventable`.)
- How to store fuzzy/partial dates? (Lean: store raw GEDCOM date string + parsed range.)
- Gender/sex modeling to stay GEDCOM-compatible yet respectful. See [[person]].
