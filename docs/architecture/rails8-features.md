---
title: Rails 8.1 features — used to the fullest
tags: [architecture, rails8]
status: stable
---

# Rails 8.1 — used to the fullest

A deliberate map of **each** modern Rails 8 / 8.1 capability → a concrete Heartwood use.
Part of the [[stack]] thesis. If a capability has no use here, that's fine — but most do.

## Creates the "feels like an SPA" experience (no SPA code)
- **Turbo 8 morphing + page refreshes** — list/tree/profile update *in place* with scroll
  preserved. Build with morphing **from day one** (don't retrofit). Core to [[family-tree-view]],
  [[person-profile]]. This is what makes it feel instant without JS.
- **Turbo Frames / Streams** — inline edit, "add relative" without reloads ([[person-profile]]).
- **Solid Cable** — live collaborative updates ([[collaboration]]). No Redis.

## Heavy lifting on the backend
- **ActiveJob Continuations (8.1)** — *resumable* GEDCOM import: survives a Kamal deploy
  (30s shutdown) and continues from the saved cursor instead of restarting. Use for
  [[import-export]] big-tree imports. Steps with cursors over `find_each`.
- **`Rails.event` structured events (8.1)** — live import progress + observability for
  [[import-export]] (pair with Turbo Streams for the progress bar).
- **Recursive CTEs** (`WITH RECURSIVE` on SQLite) — ancestor/descendant traversal at the DB
  level for [[relationship]] and the [[tree-rendering]] sub-graph. Use the DB to the fullest.
- **Solid Queue** — all background work (import/export, [[media]] variants). No Redis.
- **Active Storage** — [[media]], document scans, GEDZIP backups.

## Trust, privacy, correctness
- **Active Record Encryption** — encrypt living-people PII ([[privacy-access]]). Direct fit.
- **Active Record `normalizes`** — normalize names / [[place]] strings on the way in.
- **Rate limiting** (Action Controller, Rails 8) — protect login & public share links.
- **`params.expect`** (Rails 8) — safer strong params.
- **Built-in Authentication generator** (Rails 8) — no Devise. See [[roadmap]] Phase 1.

## Content & ops
- **Action Text (Trix)** — rich [[note|notes]] and stories/narratives ([[features-index]] "stories").
- **Current attributes** — request-scoped user/tenant context ([[multi-tenancy]]).
- **Multiple databases** — SQLite-per-tenant option for the hosted plan ([[multi-tenancy]]).
- **Solid Cache** — cache rendered tree/profile fragments.
- **PWA stubs** (Rails 8 default) — an installable web app *before* native ([[hotwire-native]]).
- **Kamal 2 + Thruster** — one-command deploy for self-host & hosted.
- **Local CI `bin/ci` (8.1)** — run tests/brakeman/rubocop locally; fits our TDD culture
  (see [`AGENTS.md`](../../AGENTS.md)).
- **Propshaft + importmap** — no Node, no build step.

## Honest note
Using a feature must still serve [[vision]] — we don't add complexity for a checkbox. But for
a *reference* Rails 8 app, demonstrating these well **is** part of the value.
