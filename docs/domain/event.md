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

## Dates (`FuzzyDate`)
People type dates the way they say them; the app keeps that text in `date_raw` and derives the
rest. `FuzzyDate.parse(date_raw)` understands GEDCOM and the Russian way of writing it:

| Typed | GEDCOM | Range (`date_start`…`date_end`) | `date_precision` |
|---|---|---|---|
| `14 мая 1781`, `14 МАЙ 1781`, `14.05.1781`, `14 MAY 1781` | `14 MAY 1781` | that day | `day` |
| `май 1781`, `MAY 1781` | `MAY 1781` | the month | `month` |
| `1781`, `1781 г.` | `1781` | the year | `year` |
| `ок. 1696`, `около 1696`, `ABT 1696` (also `CAL`, `EST`) | `ABT 1696` | the year | `about` |
| `до 1900`, `BEF 1900` | `BEF 1900` | …end of 1899 (start empty) | `before` |
| `после 1900`, `AFT 1900` | `AFT 1900` | start of 1901… (end empty) | `after` |
| `между 1830 и 1840`, `BET 1830 AND 1840` | `BET 1830 AND 1840` | 1830…1840 | `between` |
| `с 1830 по 1840`, `1830–1840`, `FROM 1830 TO 1840` | `FROM 1830 TO 1840` | 1830…1840 | `between` |

- The range is recomputed whenever `date_raw` changes; sorting, the living-person rule, the
  duplicate finder and the tree's root pick all read it.
- Screens show `date_label`: the parsed date in the reader's language (`14 мая 1781`,
  `ок. 1696`), or the typed text when it can't be parsed.
- Export writes the GEDCOM form; a date we can't parse goes out as a date phrase `(весна 1812)`,
  and import unwraps the parentheses again.
- Life years show the bare year only for a known day/month/year; a fuzzy date shows its label
  (`ок. 1696 – 1781`).

## Notes
- This single model + a `kind` enum keeps the schema tiny while covering the entire GEDCOM
  event/attribute vocabulary. Gramps and the GEDCOM spec both work this way.
