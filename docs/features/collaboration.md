---
title: Collaboration
tags: [feature, realtime]
status: draft
---

# Collaboration

Families build trees together. Part of [[features-index]] (Should). Borrowed from webtrees'
collaborative model (see [[prior-art]]).

## What it enables
- Multiple members edit one tree, each with a role (owner / editor / viewer).
- **Live updates**: when Aunt Maria adds a cousin, everyone viewing sees it appear — via
  **Turbo Streams over Solid Cable** (no Redis). A near-free Rails 8.1 superpower.
- Optional change history / "who edited what" (audit trail) — a later refinement.

## Roles & permissions
- Tie into [[privacy-access]] for *what* each role can see, separate from *what* they can edit.
- On the hosted plan, collaboration is per-tenant — see [[multi-tenancy]].

## Notes
- Start simple: roles + live updates. Defer real-time co-editing conflict resolution; trees
  are append-heavy and rarely edit the same field simultaneously.
