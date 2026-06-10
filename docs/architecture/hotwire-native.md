---
title: Hotwire Native & SPA strategy
tags: [architecture, mobile, hotwire]
status: draft
---

# Hotwire Native & "SPA" strategy

How we get an SPA-like web app **and** native iOS/Android apps from **one codebase** — the
DHH/37signals strength. Decision: [[adr/0006-hotwire-native-ready]].

## The key realization
We do **not** build a separate SPA or a separate mobile app.
- **SPA feel** comes from **Hotwire** (Turbo morphing + Frames/Streams) — see [[rails8-features]].
- **Mobile apps** come from **Hotwire Native** (Turbo Native + Strada, unified in 2024): it
  wraps the *same* Rails-served HTML in thin native iOS/Android shells (server-driven UI).
  Progressive enhancement — promote specific screens to native Swift/Kotlin only when worth it.

## What this demands of us NOW (so native "just works" later)
1. **Screen-oriented, server-driven HTML** — every screen is a self-contained URL/route that
   renders complete HTML. Avoid client-state that only exists in JS.
2. **Build with Turbo morphing from day one** — native navigation rides on it.
3. **Path-Configuration-friendly, predictable URLs** — Hotwire Native routes by URL patterns.
4. **Keep heavy JS isolated.** The [[tree-rendering]] view is our only heavy JS. It runs in a
   webview fine, but for a premium mobile feel we may later add a **Bridge Component** or a
   **native screen** just for the tree. This is exactly why we confined it to one Stimulus
   controller with a clean boundary ([[adr/0005-tree-rendering-svg-stimulus]]).

## Sequence (see [[roadmap]])
- Now → ship the responsive web app (+ PWA stubs) built the Hotwire way.
- Later → add Hotwire Native iOS/Android shells over the same app; native-ize the tree if needed.

## Honest note
Hotwire Native is genuinely production-grade (37signals ships HEY/Basecamp this way), but it
is *web-first*: the better our server-driven HTML and morphing discipline, the better the
native apps. Sloppy client-state now = pain later.
