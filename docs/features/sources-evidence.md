---
title: Sources & Evidence
tags: [feature, evidence, differentiator]
status: draft
---

# Sources & Evidence

What separates a credible genealogy tool from a name-collector. Part of [[features-index]]
(Must). Borrowed from Gramps' evidence-centric design (see [[prior-art]]). Backed by the
[[source-citation]] entity.

## The idea
Every fact is a **claim** that should point to **evidence**. The UI makes this natural, not
a chore:
- Attach a [[source-citation]] to any [[event]] or name while editing.
- See, on the [[person-profile]], which facts are well-sourced vs unsupported (a subtle
  confidence indicator).
- When two sources disagree (two birth dates), show both and let the user mark the preferred —
  never silently overwrite. See [[event]].

## Why it's a differentiator
Consumer apps (Ancestry-lite clones) treat sources as optional metadata. Genealogists care
deeply about provenance. Doing this well — without making casual users feel burdened — is a
real wedge for a paid product. See [[vision]] principle #4.

## UX balance
- **Casual users**: never forced to add a source; gentle nudges only.
- **Serious users**: full source/citation/repository/confidence model, lossless through
  [[gedcom]] (`SOUR`/`PAGE`/`QUAY`/`REPO`).
