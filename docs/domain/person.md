---
title: Person (INDI)
tags: [domain, entity]
aliases: [Individual, INDI]
status: draft
---

# Person (`INDI`)

The vertex of the graph: one human being. Part of [[domain-model]].

## Responsibilities
- Hold identity: names (possibly several over a life — birth name, married name).
- Anchor [[event]] records (birth, death, …) and facts (occupation, religion).
- Participate in [[family]] records as a **partner** and/or as a **child**.
- Carry privacy state for living people — see [[privacy-access]].

## Key fields (sketch — finalize in Phase 1)
- `given_names`, `surname`, `name_prefix`, `name_suffix`, plus `nicknames`.
  - Consider a separate `Name` model if multiple names per person are needed (GEDCOM allows it).
- `sex` — GEDCOM uses `M`/`F`/`U`/`X`. Store the GEDCOM code for interop; present respectfully.
- `living` (boolean/derived) — drives [[privacy-access]] defaults.
- `gedcom_xref` — original `@I123@` id, kept for stable round-trip [[gedcom]] export.
- `biography` — rich-text life story via Action Text, edited with Lexxy
  (see [[adr/0008-action-text-lexxy]]). Prose, not structured facts; maps to a GEDCOM `NOTE`.

## Associations
- has_many [[event]] (polymorphic `eventable`)
- has_many [[media]] (attachments + linked OBJE)
- partner in many [[family]] (the unions they formed)
- child in at most one (usually) [[family]] (their parents' union) — but allow more for
  adoption/foster; GEDCOM `PEDI` pedigree type on the child link.
- [[relationship]] — derived helpers (parents, children, siblings, spouses) computed via Family.

## Notes
- **Do not** store `birth_date`/`death_date` as columns — they are [[event]] rows. See
  [[domain-model]] "Events over columns."
- Names are culturally diverse: support patronymics, multiple surnames, non-Latin scripts.
  Don't assume "First Last."
