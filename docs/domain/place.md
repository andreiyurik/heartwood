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

## Map tiles and geocoding are settings
The browser fetches map tiles and the server asks a geocoder for coordinates; both are third
parties that see a request (the tile server sees the viewer's IP). So they come from the
environment, like the operator details ([[accounts-and-legal]]):
- `MAP_TILES_URL` — a Leaflet URL template, default the OpenStreetMap tile server;
  `MAP_TILES_ATTRIBUTION` — its credit line, default «© OpenStreetMap contributors».
- `GEOCODER_URL` — a Nominatim-compatible `/search` endpoint, default
  `nominatim.openstreetmap.org`.

Set either to an empty string to turn it off. Without tiles there is no map: the Map tab, the
person's map block and the place picker's map are hidden and `/map` is 404. Without a geocoder
the «find on the map» button is hidden and imported places stay without coordinates. The
hosted service in Russia keeps both off until it has a Russian provider: the OSM servers are
abroad, and the policy promises no cross-border transfer ([[legal-ru]] п. 1).

## Notes
- On import, store the raw string immediately; normalize lazily/optionally. Never block
  import on geocoding.
- Historical places change names and borders over time — keep it tolerant, don't over-engineer
  a temporal gazetteer in v1.
