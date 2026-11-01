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

## Model (implemented)
- `Source`: `title`, `url`, `citation_text` (a general note *about the source itself* — how
  to access it, why it matters — not evidence for any one fact), plus `author`,
  `repository` (free text — where it's held: archive, library, a relative's attic), and
  `source_type` (free string, not a hard enum — census/certificate/book/website/oral
  history/other are offered as suggestions in the form, but GEDCOM source types are
  open-ended and import must never be blocked by an unrecognized one; see
  [[domain-model]] "soft, additive schema").
- `Citation`: `source_id`, `citable` polymorphic (an [[event]] today; a name or [[family]]
  link could join later), `page` (string — "page 3", "line 12"), `text` (the transcribed
  quote/excerpt — evidence for *this one fact*, distinct from `Source#citation_text`
  above), `date` (when the citation/detail was recorded), `confidence`.
- `Source` has_many [[media]] (the scan of the certificate) — not yet built.
- Optionally a `Repository` (`REPO`) where the source is held — currently folded into
  `Source#repository` as a string rather than its own entity; promote to a real model only
  if repositories need to be shared/deduped across sources.

## Confidence — the 5-level scale (borrowed from Gramps)
Gramps' evidence-first design is the reason [[sources-evidence]] is a differentiator, and
its confidence scale is richer than GEDCOM's own 4-level `QUAY` — we use Gramps' 5 levels
verbatim rather than inventing our own:

| Level | Meaning |
|---|---|
| **Very Low** | Unreliable evidence or estimated data |
| **Low** | Questionable reliability (interviews, census, oral genealogies, or potential bias — e.g. an autobiography) |
| **Normal** | The default when a citation is added — no claim either way yet |
| **High** | Secondary evidence, officially recorded sometime after the event |
| **Very High** | Direct/primary evidence, or by preponderance of the evidence |

## GEDCOM mapping
Maps cleanly to GEDCOM `SOUR`/`REPO`/`PAGE` — keep it lossless for [[gedcom]] export.
`QUAY` is the one lossy spot: GEDCOM only has 4 levels (0–3) against our 5. Gramps itself
maps its top level to `QUAY 3` in an idiosyncratic way not strictly matching the GEDCOM
spec's own definition of that level — rather than copy that ambiguity, our export uses a
deliberate, documented collapse: `very_low`/`low` → `QUAY 0`, `normal` → `QUAY 1`,
`high` → `QUAY 2`, `very_high` → `QUAY 3`. On import the reverse is `QUAY 0` → `low`, `1` → `normal`, `2` → `high`,
`3` → `very_high` (see [[gedcom]] "What we write and read").
