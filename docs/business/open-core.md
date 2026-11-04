---
title: Open Core model
tags: [business, license]
status: draft
---

# Open Core model

How "free & self-hostable" and "paid hosted" coexist in one codebase. Decision:
[[adr/0003-agpl-open-core]]. Mechanics: [[multi-tenancy]].

## The split
```
┌─────────────────────────────────────────────┐
│  Heartwood Core  (AGPL-3.0, public)          │
│  domain model, tree view, GEDCOM, profiles,  │
│  sources, media, collaboration, privacy       │
│  → fully usable self-hosted, forever, free    │
└─────────────────────────────────────────────┘
              ▲ mounts on top
┌─────────────────────────────────────────────┐
│  Heartwood Cloud  (private Rails Engine)     │
│  billing, plan limits, multi-tenant ops,     │
│  hosted onboarding, managed backups           │
│  → powers our paid SaaS only                  │
└─────────────────────────────────────────────┘
```

## Rules that keep it honest
- **The core is genuinely complete.** Self-hosters get the whole genealogy product, not a
  crippled demo. We do **not** paywall core genealogy features.
- **Paid = convenience & operations, not capability.** People pay us to *not run a server*,
  not to unlock their own family's data. This matches [[vision]] ("own your roots").
- **Engine boundary is clean.** The private Engine only adds tenancy/billing/ops; it never
  changes core semantics. Learn modular Engine design from **Solidus/Spree** ([[prior-art]]).
- **AGPL** protects this: a competitor can't legally run a closed SaaS on our core
  ([[adr/0003-agpl-open-core]]).

## What lives where (initial cut)
| Capability | Core (AGPL) | Cloud (private) |
|-----------|:----------:|:---------------:|
| Tree, profiles, events, sources, media | ✅ | |
| GEDCOM import/export | ✅ | |
| Collaboration & privacy | ✅ | |
| Multi-tenant accounts, billing | | ✅ |
| Managed backups, support SLAs | | ✅ |

## How the Engine plugs in
The Engine is the private gem `heartwood_cloud` (repo `heartwood-cloud`). The hosted build
clones it into `vendor/cloud` (git-ignored) and bundles with `BUNDLE_GEMFILE=Gemfile.cloud`,
which is the core `Gemfile` plus that one gem — so the public `Gemfile.lock` never mentions it.
`bin/kamal deploy -d hosted` builds from the working directory (`config/deploy.hosted.yml`) so
the untracked engine is in the image. See [[deployment]].

The core knows nothing about billing. It exposes **cloud slots**: `cloud_slot "name"` renders
the partial `cloud/_name` when one exists and nothing otherwise. Self-hosters have no such
partials; the Engine ships them. Current slots:

| Slot | Where | Locals |
|---|---|---|
| `family_price` | landing pricing card, in place of "Soon" | — |
| `tree_plan` | tree's people & sharing page, owner only | `tree` |
| `legal_links` | landing footer, after the terms | — |
| `privacy_processors` | privacy policy, after the list of processors | — |
| `landing_analytics` | end of the landing page — the only page analytics may run on | — |

A new slot is added to the core only when the Engine needs one — keep the list short.

Run the core suite with the plain `Gemfile`: under `Gemfile.cloud` the real engine fills the
slots and the core's "no engine" assertions fail by design. The engine's own suite is
`BUNDLE_GEMFILE=Gemfile.cloud bin/rails test vendor/cloud/test`.
