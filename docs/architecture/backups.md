---
title: Backups & restore
tags: [architecture, operations, reliability]
status: draft
---

# Backups & restore

Losing one family's tree once loses their trust forever. Gates the paid launch ([[launch-ru]]).
Adapted from once-campfire's `script/admin/prepare-backup` (SQLite online backup API), with what
a hosted service adds: off-site copies, verification of every copy, a written restore drill.

## What is backed up
- **The primary database** (`storage/production.sqlite3`) — every tree, person, edit, user.
  Cache, queue and cable databases are disposable and are not backed up.
- **Photos and uploads** (Active Storage). On the hosted service they live in S3-compatible
  object storage in Russia (`STORAGE_*` env → the `object_storage` service), with bucket
  versioning on — durability is the provider's job and a deleted file is recoverable from a
  version. A self-hoster on the `local` disk service backs up the `storage/` volume themselves.

## How (`Backup`)
`Backup.create` (Solid Queue recurring, every 6 hours, `config/recurring.yml`):
1. Snapshot the primary database with `SQLite3::Backup` — consistent while the app writes.
2. **Verify** the snapshot: `PRAGMA integrity_check` is `ok` and it holds as many users,
   trees and people as the live database. A snapshot that fails raises, so the job fails loudly
   instead of keeping a bad copy.
3. Gzip it to `storage/backups/heartwood-<UTC timestamp>.sqlite3.gz`.
4. If off-site is configured (`BACKUP_BUCKET`), upload it through the Active Storage `backups`
   service (S3 adapter, `aws-sdk-s3`; the hosted service uses Timeweb Cloud S3).
5. Prune local snapshots older than `Backup::LOCAL_RETENTION` (7 days).

Off-site copies expire through a **bucket lifecycle rule of 30 days** (set once in the provider's
console) — matching the 30-day promise in the privacy policy ([[accounts-and-legal]]).

## Configuration (hosted, Kamal secrets)
`BACKUP_BUCKET`, `BACKUP_ENDPOINT`, `BACKUP_REGION`, `BACKUP_ACCESS_KEY_ID`,
`BACKUP_SECRET_ACCESS_KEY`; the same set with the `STORAGE_` prefix for photos. The hosted service
runs on a Timeweb Cloud VPS with Timeweb S3: endpoint `https://s3.twcstorage.ru`, region `ru-1`
(the default; check both on the bucket's page). Endpoint and region aren't secret, so they sit in
`env.clear` in `config/deploy.yml`.

Both services set `request_checksum_calculation`/`response_checksum_validation` to
`when_required`: since aws-sdk-s3 1.178 the SDK adds CRC32 checksums to every upload, and
S3-compatible providers that don't implement them reject the request. Use a separate bucket and key for backups, with write-only rights
if the provider allows, so a leaked app key can't delete the backups.

## Restore drill
1. `bin/kamal app stop`
2. Fetch the snapshot (from `storage/backups/` or the bucket) onto the server's volume.
3. `bin/kamal app exec "bin/rails backup:restore FILE=storage/backups/<file>.sqlite3.gz"` —
   decompresses into place, removes stale `-wal`/`-shm`, then verifies the result.
4. `bin/kamal app boot`, open the app, spot-check a tree.

Run the drill on a staging server at least once a quarter; a backup nobody has restored is a
hope, not a backup. `test/models/backup_test.rb` restores into a scratch path on every CI run.

## Deferred
- Alerting when a backup job fails (today: failed jobs in Solid Queue; add Mission Control or
  an email to the operator).
- Client-side encryption of off-site snapshots (today: provider-side encryption at rest).
