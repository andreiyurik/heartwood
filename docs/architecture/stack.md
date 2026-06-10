---
title: Stack & Constraints
tags: [architecture, stack]
status: stable
---

# Stack & Constraints

The canonical **vanilla Rails 8.1** stack — chosen on purpose. The constraints *are* the
product thesis (see [[vision]], [[adr/0001-vanilla-rails-stack]]). Agents must respect the
hard rules in [`AGENTS.md`](../../AGENTS.md).

## The stack
| Layer | Choice | Why |
|-------|--------|-----|
| Framework | **Rails 8.1** (Ruby 4.0.x) | The whole point |
| DB | **SQLite** (dev + prod) | Zero-ops self-host — [[adr/0002-sqlite-production]] |
| Interactivity | **Hotwire** (Turbo + Stimulus) | No SPA, server-rendered |
| Assets | **Propshaft + importmap** | No Node, no bundler |
| CSS | **Vanilla CSS** (nesting, custom props) | No Tailwind |
| Jobs | **Solid Queue** | No Redis — powers [[import-export]] |
| Cache | **Solid Cache** | No Redis |
| WebSockets | **Solid Cable** | No Redis — powers [[collaboration]] live updates |
| Files | **Active Storage** | [[media]], import uploads |
| Tests | **Minitest** (omakase) | No RSpec |
| Deploy | **Kamal + Thruster** | One-command self-host & hosted |

## The one sanctioned exception
The [[family-tree-view]] graph layout needs real JavaScript (a layout algorithm). It is
confined to **one Stimulus controller** over SVG, with nodes as server partials. Everything
else stays vanilla. See [[tree-rendering]], [[adr/0005-tree-rendering-svg-stimulus]].

## Used to the fullest
See [[rails8-features]] for how each Rails 8/8.1 capability maps to a concrete Heartwood use,
and [[hotwire-native]] for the one-codebase web + mobile strategy.

## Decision filter
Before adding any gem/lib/tool, ask: *does this break the vanilla-Rails thesis?* If yes, the
default answer is **no** — find the Rails-native way. Record exceptions as an ADR.
