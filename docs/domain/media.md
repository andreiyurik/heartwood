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

## Notes
- On [[gedcom]] import, GEDCOM `OBJE` references file paths/URLs — import what we can, flag
  what we can't fetch, never lose the reference.
- Respect [[privacy-access]]: photos of living people inherit privacy settings.
