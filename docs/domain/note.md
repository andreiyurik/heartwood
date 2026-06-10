---
title: Note (NOTE)
tags: [domain, entity]
aliases: [NOTE, Annotation]
status: draft
---

# Note (`NOTE`)

Part of [[domain-model]]. Free-text annotation attachable to most records.

## Concept
A Note is human prose attached to a [[person]], [[family]], [[event]], [[source-citation]],
or [[media]] — research notes, anecdotes, reasoning behind a conclusion, transcriptions.

## Model (sketch)
- `notable` polymorphic owner (Person / Family / Event / Source / Media).
- `body` (rich-ish text; keep it Markdown-friendly and Hotwire-editable inline).
- `gedcom_xref` for round-trip; GEDCOM allows both inline and shared (`@N1@`) notes.

## Notes
- Distinct from [[source-citation]]: a Note is commentary; a Citation is evidence. Don't
  conflate them.
- Honors [[privacy-access]] — a note on a living person inherits its visibility.
- The longer "stories / narratives" feature in [[features-index]] (Could) may grow out of
  Notes into first-class prose attached to people.
