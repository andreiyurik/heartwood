---
title: Glossary
tags: [reference, glossary]
status: stable
---

# Glossary

Domain vocabulary, aligned with GEDCOM terms where sensible so import/export stays clean.
GEDCOM tag shown in `code` where relevant.

- **Individual / Person** (`INDI`) — one human being. See [[person]].
- **Family** (`FAM`) — a unit linking partners and their children. *Not* a household; a
  structural node connecting people. See [[family]].
- **Relationship** — a typed edge between people (parent–child, partner). We derive most
  relationships *through* [[family]] records, GEDCOM-style. See [[relationship]].
- **Event** (`EVEN`) — something that happened at a time/place: birth (`BIRT`), death
  (`DEAT`), marriage (`MARR`), etc. Attached to a person or a family. See [[event]].
- **Fact / Attribute** — a non-event characteristic: occupation (`OCCU`), religion (`RELI`).
  Modeled alongside events. See [[event]].
- **Source** (`SOUR`) — where information came from (a census, a certificate, a book). See
  [[source-citation]].
- **Citation** — a specific pointer from a fact to a source ("this birth date comes from
  *this* page of *this* census"). The evidence link. See [[source-citation]].
- **Place** (`PLAC`) — a normalized location, ideally hierarchical (city → region → country).
  See [[place]].
- **Media / Multimedia object** (`OBJE`) — a photo, scan, document, audio. See [[media]].
- **Note** (`NOTE`) — free-text annotation attachable to most records.
- **Pedigree chart** — ancestors of one person (parents, grandparents…). A view, see
  [[family-tree-view]].
- **Descendancy chart** — descendants of one person.
- **Hourglass chart** — ancestors *and* descendants of one person at once.
- **GEDCOM** — GEnealogical Data COMmunication, the standard interchange file format. See
  [[gedcom]].
- **Tenant** — one isolated account/space on the hosted plan. See [[multi-tenancy]].
