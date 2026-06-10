---
title: GEDCOM — the exchange format
tags: [interop, gedcom, moat]
status: draft
---

# GEDCOM — the accepted exchange format

> Interop is our **moat** (see [[vision]] principle #1). The reason people will trust
> Heartwood is that they can always leave — and the reason they'll *come* is that they can
> bring their whole tree from Ancestry / MyHeritage / Gramps / FamilySearch.

## What GEDCOM is
**GE**nealogical **D**ata **COM**munication — the de-facto standard text format for exchanging
family-tree data. A GEDCOM file is line-oriented records (`0 @I1@ INDI`, `1 BIRT`, `2 DATE …`).
Our [[domain-model]] is deliberately GEDCOM-shaped so mapping is near-lossless.

## Versions — what we support

| Version | Year | Our stance |
|---------|------|-----------|
| **GEDCOM 5.5.1** | 2019 (long de-facto) | **Import (tolerant).** What almost every legacy app exports. Must read it well. |
| **GEDCOM 7.0** | 2021+, by FamilySearch | **Native import + export.** The modern spec (UTF-8, structured, versioned). Our canonical output. |
| **GEDCOM X** | FamilySearch | *Could*, later. A JSON/XML API model, not a file format — different use case. |
| **GEDZIP** | part of v7 | Support — bundles the GEDCOM + media into one `.gz`/`.zip`. Great for full backups. |

**Decision:** export **7.0** (with GEDZIP for media), import **both 5.5.1 and 7.0** tolerantly.
See [[adr/0004-gedcom-interop]].

## Hard truths (be honest about these)
- GEDCOM interop is **never perfectly lossless in practice** — vendors add custom tags
  (`_CUSTOM`), encodings vary (ANSEL in old files!), and structure differs. Our rule:
  **never drop data.** Unknown tags get preserved in a raw/`extra` store and surfaced, not
  discarded. A user must never lose information by importing into Heartwood.
- Keep original `@xref@` ids (`gedcom_xref` fields across the [[domain-model]]) so a
  round-trip import → export → import is **stable**. This is a Phase-2 acceptance test.

## Implementation notes
- Lean on a Ruby GEDCOM parsing gem if a maintained one fits the vanilla-stack rule; otherwise
  a small hand-written line parser is very doable (the grammar is simple). Evaluate in Phase 2.
- The whole pipeline (upload → parse → map → report) is described in [[import-export]].

## Related
- [[import-export]] · [[domain-model]] · [[source-citation]] · [[media]] · [[adr/0004-gedcom-interop]]
