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
- **Share links**: read-only links to a branch or person for relatives, without an account.
- **Role-based access**: owner / editor / viewer, tying into [[collaboration]].

## Implementation notes
- Default to **private/safe**: new data is members-only until deliberately published.
- Enforce at the query layer (scopes), not just the view — never leak a hidden living person
  through search, [[gedcom]] export, or the [[family-tree-view]] API.
- GEDCOM export should offer a **"living people excluded/anonymized"** option.
