---
title: Change history & undo
tags: [feature, collaboration, trust]
status: draft
---

# Change history & undo

When a whole family edits one tree, mistakes happen: an aunt deletes the wrong great-grandfather,
a cousin overwrites a name. People only invite relatives into a tree they can't break, so
**every change is visible and reversible**. Part of [[collaboration]]; gates the paid launch
([[launch-ru]]). Echoes [[positioning]] "Forgiving by default".

## What users see
- **History** page (`/edits`, linked from the account menu next to Members): newest first,
  one row per change — avatar of who made it · what happened · one muted line with details and
  time. Rows, not cards ([[design-system]]).
- An editor or the owner can press **Undo** on a row (**Restore** for a deletion). Viewers see
  history but can't undo.
- After deleting a person the flash offers **Undo** right away (the toast stays 10s and pauses
  on hover/focus; under reduced motion it stays still instead of vanishing).
- Copy avoids gendered Russian verbs («Изменено», «Удалено»), since we don't know the
  author's gender.

## Model
`Edit` (named after Writebook's `Edit`; `changes` is taken by Active Record dirty tracking) belongs to a tree, the user who made it, and a polymorphic `subject`; `person_id`
points at the person it concerns (for filtering and links). `action` is
`added` / `edited` / `removed`. `particulars` (JSON) keeps what's needed after the fact:
- `name` — the subject's display label at the time;
- `before` / `after` — changed attributes, for updates;
- `snapshot` — for a deleted person: their attributes, events (with citations) and family
  links, so a restore brings back the whole person with the same id (SQLite `AUTOINCREMENT`
  never reuses ids, so links and URLs keep working).

Tracked: `Person`, `Event`, `FamilyChild`, `FamilyPartner` (via the `Editable` concern). Only
edits made by a signed-in person are recorded (`Current.user`); a GEDCOM import is one bulk
action and is not logged row by row. Records destroyed through a parent
(`destroyed_by_association`) are part of the parent's snapshot, not separate rows.

## Undo semantics (`Edit#revert`)
- `edited` → put back the `before` values, but only for attributes nobody has changed since
  (current value still equals `after`); never clobbers a later edit.
- `added` → destroy the subject (that destroy is itself a change, so it can be restored).
- `removed` → recreate from `particulars`; for a person, also their events, citations and
  family links (if the family still exists).
- The change is stamped `reverted_at` / `reverted_by`; the inverse operation is recorded as a
  new change, so history stays append-only.

## Deferred
- Biography (Action Text) revisions — Writebook-style `Edit` versions.
- Photos of a deleted person: the avatar is kept (`dependent: false`) so a restore re-links it;
  pruning old changes and their orphaned photos is a later job.
- Per-person history tab on the profile.
- Retention / pruning policy; the page shows the latest 200 rows (pagination later).
- Restoring a person past the free plan's people limit fails with a flash alert, not silently.
