---
title: Event & Fact (EVEN)
tags: [domain, entity]
aliases: [EVEN, Fact, Attribute]
status: draft
---

# Event & Fact (`EVEN`)

Part of [[domain-model]]. The reason we **don't** use date columns on [[person]].

## Concept
Anything that happened (or any attribute that holds) is an Event/Fact row attached
polymorphically to a [[person]] **or** a [[family]] (`eventable`).

- **Events** have a date and/or place: birth `BIRT`, death `DEAT`, baptism `BAPM`,
  burial `BURI`, marriage `MARR`, divorce `DIV`, immigration `IMMI`, census `CENS`…
- **Facts/Attributes** describe a state: occupation `OCCU`, religion `RELI`, education
  `EDUC`, nationality `NATI`, physical description `DSCR`.

## Why model it this way
- Handles **fuzzy dates** ("ABT 1850", "BEF 1900", "BET 1830 AND 1840") — store the raw
  GEDCOM date string **plus** a parsed sortable range. See [[domain-model]] open questions.
- Handles **conflicting claims**: two birth dates from two sources, each with its own
  [[source-citation]]. The tree shows the best-supported one; the rest are preserved.
- Add new event types without schema migrations.

## Key fields (sketch)
- `eventable_type` / `eventable_id` (Person or Family)
- `kind` (enum/string, GEDCOM tag e.g. `BIRT`)
- `date_raw` (original string), `date_start`, `date_end` (parsed range), `date_precision`
- `place_id` → [[place]]
- `value` (for facts: the occupation text, etc.)
- has_many [[source-citation]]

## Notes
- This single model + a `kind` enum keeps the schema tiny while covering the entire GEDCOM
  event/attribute vocabulary. Gramps and the GEDCOM spec both work this way.
