---
title: Media (OBJE)
tags: [domain, entity]
aliases: [OBJE, Multimedia, Photos, Documents]
status: draft
---

# Media (`OBJE`)

Part of [[domain-model]]. Photos, document scans, audio, video — via **Active Storage**.

## Rails 8.1 fit
- **Active Storage** for uploads + variants (thumbnails) — `image_processing` gem.
- Storage backend differs by deployment: local disk for self-host (zero config), S3-compatible
  for the hosted plan. Same code — see [[multi-tenancy]].
- Background variant generation via **Solid Queue** (no Redis). See [[import-export]] for the
  same pipeline pattern.

## Model (sketch)
- `Media` belongs_to an owner polymorphically (`attachable`: a [[person]], [[family]],
  [[event]], or [[source-citation]] — e.g. the scan of a birth certificate).
- `title`, `caption`, `taken_on` (date), `place_id` → [[place]].
- `gedcom_xref` for round-trip.
- A person's **primary photo** flag for tree-node avatars in [[family-tree-view]].

## What is built: a person's photo album
- `Photo` belongs to a [[person]] (and its tree), has one attached `image`, a `caption` and a free-text
  `taken` ("1954", "лето 1961") — the same free text the event dates accept, because nobody
  remembers the day an old print was made.
- The profile's "Memories" section is the album: a grid of prints with their captions, opened
  full-size in a `<dialog>` lightbox (adapted from Campfire). Editors add several files at once
  and caption each in place; the portrait stays a separate, single `avatar`.
- Round-trip: the archive writes every photo as a non-primary `OBJE` with `TITL` = caption; importing
  an archive turns non-primary `OBJE` files back into photos. Plain `.ged` keeps only the references.
- Privacy: photos are reached only through their person, so living people's photos follow
  [[privacy-access]] — a view-only link never renders them for the living.
- Not built yet: photos on families, events and citations (the polymorphic `Media` sketch above),
  people tagged inside a photo, albums across people.

## Notes
- On [[gedcom]] import, GEDCOM `OBJE` references file paths/URLs — import what we can, flag
  what we can't fetch, never lose the reference.
- Respect [[privacy-access]]: photos of living people inherit privacy settings.
