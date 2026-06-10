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
