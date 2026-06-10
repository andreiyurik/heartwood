---
title: Vision & Principles
tags: [vision, principles]
status: stable
---

# Vision & Principles

## The bet

Family history is too important to rent. People pour years into their family trees inside
walled gardens (Ancestry, MyHeritage) and can never truly take their data and leave.
**Heartwood** is the opposite: an open core you own and can self-host forever, with an
*optional* paid hosted plan for people who'd rather not run a server.

We also make a technical bet: that a **canonical, boring, vanilla Rails 8 app** — SQLite,
Hotwire, vanilla CSS, no Node — can deliver a family-tree experience that feels *more*
cohesive and faster than a typical React SPA, while being dramatically easier to self-host
and keep alive for decades. See [[stack]] and [[adr/0001-vanilla-rails-stack]].

## Principles

1. **Own your roots.** Data portability is a feature, not an afterthought. You can always
   leave — via [[gedcom]] export — which is exactly why people will stay. Interop is our moat.
2. **Boringly solid.** Every dependency must justify itself against the vanilla-Rails goal.
   Longevity beats novelty. A self-hosted instance should still run in 10 years.
3. **For real people.** Intuitive enough for a grandparent to add a cousin; powerful enough
   for a serious genealogist (sources, evidence, GEDCOM). See [[features-index]].
4. **Honest about evidence.** Genealogy is about *claims backed by sources*, not just a tree
   of names. We model [[source-citation]] as a first-class citizen, like [[prior-art|Gramps]].
5. **One codebase, two deployments.** The same open core powers both self-host and our
   hosted SaaS. The paid layer is additive, never a fork. See [[open-core]], [[multi-tenancy]].
6. **Docs are the source of truth.** This vault (read by humans *and* AI agents) is where
   decisions live — Karpathy-style legible context. Chat is ephemeral; the vault is durable.

## What success looks like

- A genealogist can `git clone`, `bin/setup`, import their existing GEDCOM, and be browsing
  their tree in under 10 minutes.
- A non-technical user can sign up on the hosted plan and add three generations without a
  manual.
- Another developer reads this repo and thinks: *"this is how you build a Rails 8 app."*

## Non-goals (for now)

- DNA matching / ethnicity estimates (huge, data-heavy; maybe far future).
- Being a social network. We connect *families*, not strangers.
- Supporting every legacy GEDCOM quirk perfectly on day one — we import tolerantly and
  improve. See [[gedcom]].
