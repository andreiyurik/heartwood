---
title: Privacy & Access Control
tags: [feature, privacy, security]
status: draft
---

# Privacy & Access Control

A standout feature of mature genealogy software, and an ethical necessity. Part of
[[features-index]] (Should). Borrowed from webtrees' well-regarded privacy model.

## Why it matters
Trees contain **living people's** personal data. Publishing a tree must not expose living
relatives. Serious users expect granular control; getting this right builds trust.

## What we model
- **Living-person privacy**: people without a death [[event]] (and within ~110 years of birth)
  are treated as living → hidden/anonymized from public/viewer roles by default. The `living`
  flag on [[person]] drives this.
- **Per-record visibility**: a [[person]], [[event]], [[media]], or [[note]] can be public /
  members-only / private.
- **Share links**: read-only links for relatives, without an account — see below.
- **Role-based access**: owner / editor / viewer, tying into [[collaboration]].

## Share links (view-only, built)
The owner turns on one **view link** per tree on the Members page: `/shared/<token>`. Whoever
has it — a grandmother without an account, a cousin abroad — sees the tree and the people in
it, read-only, with nothing to sign up for.

- **Its own model**, `ShareLink` (`tree_id` unique, `has_secure_token :token`), never the
  `join_code`: a view link can't grant membership or edit rights, and turning it off doesn't
  touch the invite link. Owner only: create (or make a new one, which kills the old URL) and
  turn off.
- **Shows exactly what an outsider may see**: `Person.visible_to(nil)` — the deceased and
  people born more than 120 years ago who aren't marked private. Living people appear in the
  tree as a nameless «Живой человек» card (keeps the shape of the family, no data), and their
  pages are 404. Same rule the privacy policy promises.
- **Pages**: the whole tree (`Shared::TreesController`) and a read-only person page
  (`Shared::PeopleController`) with dates, places, family, biography, sources and the photo.
  No edit controls, no account chrome — even for a signed-in visitor — and a quiet
  «Создать своё древо» call to action.
- **Not for search engines or other sites**: `X-Robots-Tag: noindex` and
  `Referrer-Policy: no-referrer`, so the secret URL doesn't leak through a clicked link.
- Not yet: a link to one branch or one person only, an expiry date.

## Implementation notes
- Default to **private/safe**: new data is members-only until deliberately published.
- Enforce at the query layer (scopes), not just the view — never leak a hidden living person
  through search, [[gedcom]] export, or the [[family-tree-view]] API.
- GEDCOM export should offer a **"living people excluded/anonymized"** option.
