---
title: Place (PLAC)
tags: [domain, entity]
aliases: [PLAC, Location]
status: draft
---

# Place (`PLAC`)

Part of [[domain-model]]. Normalized, ideally hierarchical locations attached to [[event]]s.

## Why normalize
GEDCOM stores places as free text ("Boston, Suffolk, Massachusetts, USA"). If we keep only
the string, we can't: group events by place, draw a map, or handle "the same town spelled
five ways." So we keep the raw string **and** a normalized, hierarchical Place.

## Model (sketch)
- `name` (display), `hierarchy` (city → county/region → country), optional `parent_id` for a
  place tree.
- `latitude` / `longitude` (optional; enables a future map view — a "Could" in [[roadmap]]).
- `gedcom_raw` — original `PLAC` string for lossless [[gedcom]] round-trip.

## Notes
- On import, store the raw string immediately; normalize lazily/optionally. Never block
  import on geocoding.
- Historical places change names and borders over time — keep it tolerant, don't over-engineer
  a temporal gazetteer in v1.
