---
title: Import / Export pipeline
tags: [interop, rails8, pipeline]
status: draft
---

# Import / Export pipeline

How data gets in and out — and a showcase of **modern Rails 8.1** doing real work with zero
extra infrastructure. Format details live in [[gedcom]].

## Why this is a first-class feature, not a utility
- It's the **moat** ([[vision]] #1): frictionless migration *in* from competitors and a
  credible exit *out* builds the trust a paid product needs.
- It's the cleanest demonstration that the vanilla [[stack]] handles heavy lifting: big file
  upload, long-running parse, live progress — all without Node or Redis.

## Import pipeline (the Rails 8.1 showcase)

```
User uploads .ged / .gedzip
        │  Active Storage (disk on self-host, S3 on hosted — see [[multi-tenancy]])
        ▼
   ImportJob enqueued
        │  Solid Queue  (DB-backed jobs, NO Redis)
        ▼
   Parse GEDCOM → map to [[domain-model]]
        │  stream records; preserve unknown tags (see [[gedcom]] "never drop data")
        ▼
   Live progress to the browser
        │  Turbo Streams over Solid Cable  (NO Redis)
        ▼
   Import report: created N people, M families, K warnings
```

Every arrow is a stock Rails 8.1 capability. This is the canonical demo of the thesis in
[[adr/0001-vanilla-rails-stack]]. See [[rails8-features]] for the full capability map.

**Use ActiveJob Continuations (Rails 8.1)** for the import job: split into `step`s with a
cursor over `find_each`, so a Kamal deploy (30s shutdown) or crash resumes from the last saved
record instead of restarting. Emit progress via **`Rails.event`** + Turbo Streams.

## Design rules
- **Idempotent & resumable** where feasible; a failed import must not leave half-state — wrap
  in transactions per record-batch, record progress.
- **Dry-run / preview** before commit ("we found 1,204 people, 312 families — import?").
- **Warnings, not failures**: malformed or unknown data is reported and preserved, never fatal.
- **Per-tenant isolation**: an import only ever touches the importing account. See [[multi-tenancy]].

## Export
- **GEDCOM** (`.ged`) — one click, generated in the request; text only.
- **Archive with photos** (`.zip`, the GEDCOM 7 GEDZIP layout) — the full portable backup:
  `gedcom.ged` at the root and every photo under `media/` (the person's photo and the pictures in
  the biography), each referenced by an `OBJE` record with a relative `FILE` path; the person's
  photo carries `_PRIM Y`. We name it `.zip`, not `.gdz`: a family member must be able to open
  it with a double click. Built by `Archive#build` in `ArchiveJob` (photos may sit in S3, so
  never inside a request); the archive page refreshes itself when it's ready and offers the
  download. An archive is personal data, so only its creator can open it, and it is purged
  after `Archive::RETENTION` (24 hours, hourly recurring job). Unzipped, the folder opens in
  Gramps with the photos in place.
- Importing a `.zip`/`.gdz` brings the photos back: the `OBJE` marked `_PRIM Y` (else the
  first one not marked `_PRIM N`) becomes the person's photo, if it is an allowed image under
  the photo size limit; every other `OBJE` stays in the raw store. Files are read straight from
  the archive by name, never extracted to disk.
- **Self-host bonus:** the whole SQLite DB *is* a backup — but GEDCOM export is the portable,
  vendor-neutral one users can take anywhere.
- **The flagship round-trip: cloud collaboration in Heartwood ↔ deep local editing in Gramps.**
  Several relatives fill in the tree together in Heartwood, export to GEDCOM, do
  power-user work in Gramps (reports, DNA tools, custom filters), then re-import — see
  [[gedcom]] "The Gramps round-trip" for why this is named and tested deliberately, not just
  an incidental side effect of generic GEDCOM support.

## Future formats (Could)
- CSV import for simple lists. GEDCOM X / FamilySearch API sync. See [[gedcom]] version table.
