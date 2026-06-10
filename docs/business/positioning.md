---
title: Positioning
tags: [business, positioning, strategy, ux]
status: draft
---

# Positioning

Who Heartwood is for, who we compete with (and who we don't), and why we win. Flows
from [[vision]]; informs every feature decision in [[mvp-and-growth]]. When a feature
doesn't serve this positioning, cut it.

## One-line position

**The modern, open, privacy-first family-tree platform you actually own** — self-host
it forever under AGPL, or let us host it. A FamilySearch-grade interface on a
webtrees-grade openness.

## The market has three camps — we only fight one

| Camp | Examples | Their moat | Our stance |
|---|---|---|---|
| **Record-data SaaS** | Ancestry, MyHeritage, FamilySearch, Findmypast | Billions of digitized records, DNA databases, hints against archives | **Don't compete.** This is a *data* moat, unbeatable with code. We interoperate (GEDCOM), we don't out-archive them. |
| **Self-hosted OSS** | webtrees, Gramps Web, PhpGedView, GeneWeb | Free, open, private, collaborative | **This is our fight.** We win on UX and modern stack. |
| **Desktop** | Heredis, MacFamilyTree, Gramps | Power, offline | Adjacent; desktop is declining. We offer the web/managed alternative. |

**The unoccupied corner we own:** *"webtrees that doesn't look and feel like webtrees."*
The open-source genealogy tools are powerful but dated (PHP-era UIs, engineering-grade
UX). The polished tools (Ancestry/FamilySearch) are closed and rent-seeking. Nobody owns
**modern UX + open + self-hostable + managed-optional** all at once. We do.

## Who it's for

Primary: **people who already have data or want to research and own it** —
- the genealogist migrating off a walled garden who refuses lock-in;
- the privacy-conscious family historian who wants living relatives protected by default;
- the self-hoster who wants an open tool that doesn't look like 2010;
- the family "keeper" who wants relatives to collaborate on one private tree.

Not primarily for: the casual user who wants ancestors *found for them* with zero input.
That need is served by the record-data SaaS's data, not by software — and we say so.

## Why we win (defensible edges)

1. **UX as the moat.** In our actual fight (vs OSS), interface quality *is* the
   differentiator — see below. This is the edge we must never concede.
2. **Own your data, by principle.** No-paywall GEDCOM export, strict standard adherence.
   Directly answers the #1 complaint about Ancestry (lock-in). Per [[vision]] §1.
3. **Open-core + managed in one codebase.** Self-host under AGPL *or* pay us to not run a
   server — a combination the closed SaaS and the OSS projects each only offer half of.
   See [[open-core]], [[pricing-hosting]].
4. **Privacy-first from the schema up.** Living people hidden by default, granular
   controls — a standout that OSS users prize and closed SaaS do grudgingly.

## UX is the product — the intuitiveness commitment

Because our differentiation **is** the interface, "extremely convenient and intuitive"
is not a nicety — it's the strategy. Operational commitments:

- **Borrow the familiar, never invent.** Where an industry pattern is settled (tabbed
  person profile, fan/pedigree views, the "sourced" badge), we adopt the exact pattern
  users already know (research-verified). Novelty in core navigation is a bug.
- **Grandparent-simple, genealogist-deep — same screen.** Progressive disclosure: a
  newcomer sees name/dates/photo; a researcher expands sources/confidence/notes. Per
  [[vision]] §3. Neither audience is made to feel the other's complexity.
- **No dead ends, no manuals.** A non-technical user adds three generations without
  reading docs ([[vision]] success criteria). Every primary action is reachable in ≤2
  clicks from the profile or tree.
- **Fast and seamless, not flashy.** Turbo Frames/Streams: inline edits, no full reloads,
  no spinners-as-UX. Speed reads as "polished" to ordinary users. ([[stack]])
- **The tree is the home, not a report.** Click-to-navigate, photos in nodes, switch
  views in place. People think in trees; the UI should too.
- **Forgiving by default.** Confirm + undo on destructive actions (esp. merges — the
  most-hated failure mode of Ancestry/FamilySearch). Mistakes never punish the user.
- **It feels alive with little data.** Empty and sparse states are designed, not blank —
  a one-person tree still looks intentional and invites the next step.

### The bar we hold ourselves to
- A non-technical user signs up and adds three generations **without a manual**.
- A migrant imports their GEDCOM and is **browsing their tree in under 10 minutes**
  ([[vision]]).
- Any core action (add relative, add event, attach source, switch tree view) is **≤2
  clicks** and needs **no page reload**.
- First-time users are **never** shown an empty/blank screen with no next step.

## Honest non-goals (so we don't dilute the position)

- **Not an archive.** We will not chase record collections or DNA databases — that's the
  data moat we explicitly cede. We interoperate instead.
- **Not a social network.** We connect *families*, not strangers ([[vision]]).
- **Not feature-parity with Gramps.** Depth where it serves real users; we cut niche
  power-features that would tax the UX. Convenience beats completeness when they conflict.

## How to use this doc

Every feature and design choice should pass: *does it strengthen "modern UX + open +
private + owned", in our fight against self-hosted OSS — without dragging us into the
record-data arms race?* If not, reconsider. UX intuitiveness wins ties.
