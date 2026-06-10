---
title: Source & Citation (SOUR)
tags: [domain, entity, evidence]
aliases: [SOUR, Source, Citation, Evidence]
status: draft
---

# Source & Citation (`SOUR`)

Part of [[domain-model]]. A **first-class** citizen — this is what separates a real
genealogy tool from a toy. See [[vision]] principle #4 and [[sources-evidence]].

## Two linked concepts
- **Source** — a record of *where information came from*: a census, a birth certificate, a
  parish register, a book, a website, a family bible. Reusable across many facts.
- **Citation** — a specific *pointer* from one fact to one source: "this birth date is
  supported by **page 3** of **the 1881 census**, and here's the confidence + a quote."

## Why first-class
Genealogy is **claims backed by evidence**, not a tree of asserted names. When two sources
disagree (see [[event]]), citations are how a user judges which to trust. Serious
genealogists will not adopt a tool that treats sources as an afterthought. Gramps gets this
right; many consumer apps don't — it's a differentiator for us.

## Model (sketch)
- `Source`: title, author, publication, repository, type (census/certificate/book/web/…).
- `Citation`: `cites` polymorphic (an [[event]], a name, a [[family]] link…), `source_id`,
  `page`/`detail`, `confidence` (GEDCOM `QUAY` 0–3), `text` (transcribed quote), `date`.
- `Source` has_many [[media]] (the scan of the certificate).
- Optionally a `Repository` (`REPO`) where the source is held (archive, library).

## GEDCOM mapping
Maps cleanly to GEDCOM `SOUR`/`REPO`/`QUAY`/`PAGE` — keep it lossless for [[gedcom]] export.
