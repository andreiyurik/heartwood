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
- One click → **GEDCOM 7.0**, or **GEDZIP** (tree + all [[media]]) for a full portable backup.
- Generated in a Solid Queue job for large trees, delivered via Active Storage download link.
- **Self-host bonus:** the whole SQLite DB *is* a backup — but GEDCOM export is the portable,
  vendor-neutral one users can take anywhere.

## Future formats (Could)
- CSV import for simple lists. GEDCOM X / FamilySearch API sync. See [[gedcom]] version table.
