---
title: ADR 0006 — Hotwire-Native-ready, no separate SPA
tags: [adr, architecture, mobile]
status: accepted
---

# ADR 0006 — Hotwire-Native-ready; no separate SPA or mobile codebase

**Status:** Accepted · **Date:** 2026-06-10

## Context
We want an SPA-like web experience and future iOS/Android apps, while keeping the vanilla
[[stack]] ([[adr/0001-vanilla-rails-stack]]). The industry default would be a separate JS SPA
and/or separate native apps. See [[hotwire-native]].

## Decision
- **No separate SPA.** SPA-feel comes from Hotwire (Turbo morphing + Frames/Streams).
- **No separate mobile codebase.** Mobile comes later from **Hotwire Native** wrapping the same
  server-driven HTML; promote individual screens to native only when justified.
- Build now in a **screen-oriented, server-driven, morphing-first** style with predictable,
  Path-Configuration-friendly URLs.

## Consequences
- ➕ One codebase powers web + iOS + Android. Maximal leverage of Rails 8 ([[rails8-features]]).
- ➕ Forces clean, URL-addressable screens — good architecture regardless.
- ➖ Requires discipline now: minimize JS-only client state; the [[tree-rendering]] view stays
  isolated (one Stimulus controller) and may need a Bridge Component / native screen on mobile.
- ➖ Native is web-first: poor HTML/morphing discipline today = poor native UX later.
