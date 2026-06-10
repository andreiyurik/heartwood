---
title: MVP & Growth Plan
tags: [planning, roadmap, mvp, research]
status: draft
---

# MVP & Growth Plan

Research-backed feature blocks for a **public, hosted SaaS** launch. This is the
"what now / what next / what's optional" companion to the phase-based [[roadmap]].
Feature selection is grounded in a study of the leading apps (Ancestry, MyHeritage,
FamilySearch, Findmypast, WikiTree, Gramps, webtrees, Heredis, MacFamilyTree) and
what users actually ask for and complain about on r/Genealogy and project forums.
See also [[features-index]] and [[prior-art]].

**Guiding filter** (from [[vision]]): *own your roots*, *boringly solid*,
*for real people*, *honest about evidence*. We do **not** reinvent UX — where an
industry pattern is settled (Ancestry/FamilySearch hints, webtrees privacy), we
adopt it.

## How to read this

Each feature carries **Demand** (H/M/L — how broadly users want it) and **Effort**
(H/M/L — cost in our vanilla Rails 8 stack). Blocks are ordered by what must ship
to launch responsibly, then by retention value. Dependencies are called out so we
don't build out of order.

Constraints (non-negotiable, from [[stack]]): vanilla Rails 8.1, SQLite + Solid
stack (no Redis), Hotwire/Turbo/Stimulus (no SPA), Active Storage for media,
Action Mailer for email. External paid APIs may be **optional**, never required.
AGPL open-core preserved.

---

## Current state (done)

- ✅ Domain: [[person]], [[family]] (+ FamilyPartner/FamilyChild), [[event]] (polymorphic);
  [[relationship]] derived. Relationship is modelled **only** through `Family` —
  no person→person edges. This is the right GEDCOM-native base; most features below
  map onto it cleanly.
- ✅ Rails 8 native auth (sessions, password reset). No Devise.
- ✅ Person/Event/relatives CRUD via Hotwire (Turbo Frames → Turbo Streams).
- ✅ [[gedcom]] **import** (5.5.1 + 7.0) via `Gedcom::Parser` + `Gedcom::Mapper`.
- ✅ Tree rendering engine: `tree_controller.js` (SVG layout, pan/zoom), server-rendered nodes.
- ✅ i18n en/ru.

---

## ⚠️ Launch blocker: no tenancy yet

For a **public** SaaS this is the single most important gap and is **not** in the
current [[roadmap]] until Phase 6.

- `Person`, `Family`, `Event` have **no owner**. `people#index` lists *every* person
  in the database to *any* logged-in user. There is no data isolation between accounts.
- Therefore **Block 0 below leads with tenancy + privacy**, ahead of any user-facing
  polish. Nothing else in the MVP is safe to expose publicly without it.

---

## Block 0 — MVP (launch-blocking for public SaaS)

The smallest set we can responsibly put in front of paying strangers.

### 0.1 Tenancy & data ownership — Demand H · Effort M · **blocker**
Each account owns one or more trees; data is isolated per tree. Introduce a `Tree`
(or `Account`) model; `Person/Family/Event/Source/...` belong to a `Tree`; every
query is scoped (`Current.tree`, default_scope or explicit scopes). Membership join
(`TreeMembership` with role) sets up [[collaboration]] later without rework.
→ See [[multi-tenancy]]. **Do this first — everything else scopes through it.**

> **Decision to make first: tree architecture.** There is a verified fork in the
> industry (research, 3-0): **per-user private trees with in-tree collaboration**
> (Ancestry, MyHeritage, webtrees, Gramps Web) vs. a **single shared global tree**
> anyone can edit (FamilySearch, >1B names). Most SaaS and self-hosted apps use
> per-tree-with-collaboration; it is the more organic default for open-core and the
> one assumed here. This choice drives privacy, roles, and hints — pick it before
> designing 0.1/0.2. Sources: familysearch.org/en/blog/online-family-tree,
> webtrees.net/features.

### 0.2 Privacy of living people — Demand H · Effort M · **gate**
People with no death event and within a recency window are "possibly living" and
hidden from non-owners / public/share views. Extend the existing `Person#living?`;
add `Person#visible_to?(user)`. Enforce in the **data layer** (scopes/service), so
it also covers the tree graph, [[gedcom]] export, and search — not view-by-view.
Industry default in webtrees/WikiTree/FamilySearch; legally expected (GDPR).
→ See [[privacy-access]]. *Depends on 0.1.*

### 0.3 Interactive tree view (finish + ship) — Demand H · Effort M
The signature UI. Engine exists (`tree_controller.js`); finish pedigree +
descendancy, click-to-refocus, photo in node. This is *the product* — a genealogy
SaaS without a polished tree view does not launch.
→ See [[family-tree-view]], [[tree-rendering]].

### 0.4 GEDCOM export — Demand H · Effort M
"Take your tree anywhere." Mirror of the existing importer: `Gedcom::Writer` over
`Person→Event` and `Family→partners/children`; reuse stored `gedcom_raw`/`gedcom_xref`
for round-trip fidelity. Round-trip test (import→export→re-import stable). Data
lock-in is the #1 complaint about Ancestry; export is our trust/positioning play.
→ See [[import-export]].

### 0.5 Search & filter — Demand H · Effort M
Type-ahead search by name + filters (surname, years, sex). SQLite FTS5 (native, no
new infra) or `LIKE` to start. Turbo Frame + debounced Stimulus input. Becomes the
primary navigation once a tree passes ~200 people.

### 0.6 Photos / avatars (basic) — Demand H · Effort M
Upload a profile photo per person (Active Storage + `image_processing`, both already
present); avatar shows in the tree node and lists. The emotional hook that retains
non-professional users (FamilySearch Memories, MyHeritage). Full gallery → Block 1.
→ See [[media]].

### 0.7 Minimal sources on facts — Demand H · Effort M
Attach a source (title + URL/citation text) to a fact/[[event]]; show a "sourced"
badge. Even a minimal version delivers the *"honest about evidence"* pillar and
separates us from unsourced beginner trees. Full source model → Block 1.
→ See [[source-citation]], [[sources-evidence]].

### 0.8 Tabbed person profile (structure) — Demand H · Effort L
Adopt the **verified industry-standard profile layout** (research, 3-0): the four
biggest platforms independently converged on a tabbed person page. FamilySearch uses
six tabs — **About / Details / Sources / Collaborate / Memories / Timeline**; Ancestry
four (LifeStory / Facts / Gallery / Hints); MyHeritage and WikiTree similar. This is
the scaffold the other MVP features hang off — *Details* = structured vitals (the
[[person]] + [[event]] inline editor), *Sources* = 0.7, *Memories* = 0.6 photos,
*Timeline* = the Block-1 timeline. Build it as Turbo Frames (one lazy-loaded frame per
tab) so each section ships independently. **We adopt this layout rather than invent our
own** — users already know it. Sources:
familysearch.org/en/help/helpcenter/article/what-is-included-on-the-person-page-in-family-tree.

**MVP-optional (can launch a free beta without these):** billing/subscriptions
(private Rails Engine per [[open-core]]/[[pricing-hosting]]) — needed before
monetizing, not before launching.

---

## Block 1 — Early growth (credibility & retention)

Ship right after launch; these deepen trust and daily usefulness.

| Feature | Demand | Effort | Notes |
|---|:--:|:--:|---|
| **Sources & citations — full model** ([[source-citation]]) | H | M | `Source` + polymorphic `Citation` on events/people; confidence, page, quote. Builds on 0.7. The spine of serious genealogy (Gramps/WikiTree). |
| **Timeline view** | H | L | Person's events + interleaved family events, with computed age. Pure read over `Event`; cheap, high perceived value (Ancestry/MyHeritage). |
| **Media gallery + tagging** ([[media]]) | H | M | Multiple photos, captions, one photo → many people (group shots). Extends 0.6. |
| **Notes & research log / to-do** | M | L | Polymorphic `Note` + `ResearchTask` (status: open/in-progress/blocked/done; priority: low/med/high). Key pattern (Gramps Web, verified 3-0): **the task lives inside the genealogical data, linked to a person/source — not in an external Trello**. Attachments via Active Storage, status toggle via Turbo Streams. |
| **Relationship calculator** | H | M | "How am I related to X?" BFS over existing `Family`-derived parents/children → relationship term (RU/EN i18n). Viral moment; webtrees/Gramps staple. |
| **Integrity checks** | M | L | Born-after-parent-death, impossible dates, orphan persons. `IntegrityChecker` service, Solid Queue. Feels "smart"; cheap. |

---

## Block 2 — Growth (depth & collaboration)

| Feature | Demand | Effort | Notes |
|---|:--:|:--:|---|
| **Places as entities + normalization** ([[place]]) | M | M | `Place` with hierarchy + optional coords; migrate `Event#value` place strings. Fixes spelling chaos; enables geography. |
| **Place maps (optional layer)** | M | M | Leaflet + OpenStreetMap (no paid API). Isolated Stimulus controller, like the tree. *Depends on Place coords.* |
| **More chart types: fan / hourglass / bow-tie** | M | M | Reuse `tree_controller.js` layout. Standard set (FamilySearch 5 views, webtrees ~12, Gramps Web fan/hourglass — verified 3-0). **Fan chart: default 4–7 generations, radial** (take FamilySearch's range, don't invent). Add **color-by-modes** as a Stimulus param — esp. *color by source count* to surface data gaps (verified FamilySearch pattern); ties directly to the 0.7/Block-1 source model. |
| **Collaborative editing + roles** ([[collaboration]]) | M | H | Multiple editors, live updates via Turbo Streams over Solid Cable. *Depends on 0.1 tenancy + 0.2 privacy.* |
| **Share links** ([[privacy-access]]) | M | M | Public/unlisted read-only tree links honoring living-person privacy. *Depends on 0.2.* |
| **Custom events/facts** | M | L | Arbitrary event types beyond the GEDCOM tag set. |
| **Statistics dashboard** | L | L | Counts, date span, surnames, places. Cheap delight. |

---

## Block 3 — Optional / integrations (never a hard dependency)

Per the constraint: the core must work with **none** of these. Build as opt-in
plugins/engines.

| Feature | Demand | Effort | Notes |
|---|:--:|:--:|---|
| **Hints / record matching** | H | H | Against open datasets or other local trees. Always *suggest → user confirms → source auto-attached*. Never one-click-accept (the Ancestry anti-pattern that pollutes trees). |
| **Reports & charts (PDF / book)** | M | H | Printable pedigree/descendancy, family group sheets, narrative. Gramps/Heredis strength. |
| **Photo restoration (colorize/enhance/animate)** | M | H | MyHeritage "Deep Nostalgia"-style. External model/API — optional. |
| **DNA matching** | M | H | Ancestry ThruLines / MyHeritage Theory of Relativity. Niche, heavy — explicitly Won't-yet for core. |

---

## Demand × Effort summary (all features)

| Feature | Block | Demand | Effort |
|---|:--:|:--:|:--:|
| Tenancy & ownership | 0 | H | M |
| Living-person privacy | 0 | H | M |
| Tree view (finish) | 0 | H | M |
| GEDCOM export | 0 | H | M |
| Search & filter | 0 | H | M |
| Photos/avatars (basic) | 0 | H | M |
| Minimal sources on facts | 0 | H | M |
| Sources & citations (full) | 1 | H | M |
| Timeline | 1 | H | L |
| Media gallery | 1 | H | M |
| Notes / research log | 1 | M | L |
| Relationship calculator | 1 | H | M |
| Integrity checks | 1 | M | L |
| Places + normalization | 2 | M | M |
| Place maps | 2 | M | M |
| Fan / hourglass charts | 2 | M | M |
| Collaboration + roles | 2 | M | H |
| Share links | 2 | M | M |
| Custom events/facts | 2 | M | L |
| Statistics dashboard | 2 | L | L |
| Hints / matching | 3 | H | H |
| Reports / PDF | 3 | M | H |
| Photo restoration | 3 | M | H |
| DNA matching | 3 | M | H |

---

## Divergence from the phase-based [[roadmap]]

The "public SaaS MVP" target pulls three things **earlier** than the existing roadmap:

| Feature | roadmap.md says | This plan says | Why |
|---|---|---|---|
| Multi-tenancy / ownership | Phase 6 (Hosted SaaS) | **MVP (0.1)** | No public multi-user product is safe without per-account data isolation. Currently absent entirely. |
| Living-person privacy | Phase 5 | **MVP (0.2)** | Legal/ethical gate for exposing real people publicly. |
| Search | "Should", unsequenced | **MVP (0.5)** | Primary navigation once trees grow; cheap. |
| Sources | Phase 4 | **Minimal in MVP (0.7)**, full in Block 1 | Vision pillar "honest about evidence"; differentiator vs Ancestry. |
| GEDCOM export | Phase 2 | **MVP (0.4)** | Unchanged in spirit — stays a moat-completing must. |

These are re-sequencing decisions, not new scope vs. [[features-index]]. If we instead
launched a **self-use** first release, 0.1/0.2 would move to Block 1 and the MVP would
shrink accordingly.

---

## Dependency map (build order)

```
0.1 Tenancy ──┬─→ 0.2 Privacy ──→ 2: Collaboration, Share links
              └─→ everything (all data scoped through Tree)
0.7 Minimal sources ──→ 1: Sources & citations (full) ──→ sources in GEDCOM export
Places (2) ──→ Integrity checks benefit ──→ Place maps
tree_controller.js (done) ──→ 0.3 Tree view, 0.6 photo-in-node, 2: fan/hourglass
Event (done) ──→ 1: Timeline (read-only, cheapest win)
```

## UX principles to bake in from day one

Condensed; these prevent expensive rework. Full rationale in the research notes.

1. **Data freedom is positioning** — import/export prominent, no paywall on your own data.
2. **Every fact can carry a source, and it's visible** — leave a citation slot in every
   fact card now, even when empty.
3. **No irreversible actions without confirm + ideally undo** — especially merges (the
   most-hated Ancestry/FamilySearch failure mode). Prefer soft-delete / versioning.
4. **Fuzzy dates are first-class** — "ABT 1685", "BEF 1700"; never lose `date_precision`.
5. **Complex families are normal** — adoption, remarriage, co-parents, unknown parent,
   same-sex. The `Family` + `FamilyChild.pedigree` model already allows this; don't hard-code
   "one mum + one dad" in the UI.
6. **Living-person privacy by default**, enforced in the data layer. webtrees offers
   privacy configurable at site / tree / user / record / fact level (verified 3-0);
   we don't need all five at launch, but put privacy flags in the **schema from day
   one** — retrofitting privacy is expensive and dangerous.
7. **Hints suggest, users confirm** — never one-click-accept without a source.
8. **Speed via Turbo, not SPA** — type-ahead, inline add, toggles via Frames/Streams.
   One Stimulus controller per island (like the tree) is the allowed exception.
9. **The tree is a map, not a table** — click-to-refocus, photos in nodes, switch
   pedigree↔descendancy↔fan in place.
10. **Progressive disclosure** — simple for newcomers (name/dates/photo), deep for
    researchers (sources/confidence/notes/log). Simple like Ancestry, deep like Gramps.
11. **Adopt the tabbed profile, don't invent one** — see 0.8. Four major platforms
    converged on it independently (verified); users already know the pattern.

---

## Appendix — Research basis & sources

This plan's feature claims were produced by a multi-source, adversarially-verified
research pass (5 angles → 23 sources fetched → 91 claims → 25 verified by 3-vote
panel; 23 confirmed, 2 refuted). Confirmed findings used above:

- **Tabbed person profile is the industry standard** (3-0) — FamilySearch (About/
  Details/Sources/Collaborate/Memories/Timeline), Ancestry, MyHeritage, WikiTree.
  → 0.8. *Source: familysearch.org help center (primary).*
- **Sources attached to facts via a dedicated tab** (3-0) — records + uploaded docs +
  external URLs. → 0.7 / Block 1. *Source: FamilySearch (primary).*
- **Multiple tree views are standard, not one layout** (3-0) — FamilySearch 5 views,
  webtrees ~12, Gramps Web fan/hourglass. → 0.3 / Block 2. *Sources: FamilySearch,
  grampsweb.org/features, webtrees.net/features (primary).*
- **Fan chart 4–7 generations with color-by-modes incl. by source count** (3-0) →
  Block 2. *Source: FamilySearch fan-chart help (primary).*
- **GEDCOM is the mandatory baseline; deviating from the standard causes lasting
  migration pain** (3-0) → 0.4. *Sources: gramps-project.org wiki, webtrees issue
  #2279, en.wikipedia.org/wiki/GEDCOM.*
- **Granular multi-level privacy (site/tree/user/record/fact)** (3-0) → 0.2 / UX #6.
  *Sources: webtrees.net/features, grampsweb.org/features (primary).*
- **Collaborative multi-user editing is the open-source selling point** (3-0) →
  Block 2. *Sources: webtrees.net/features, ithy.com self-hosted comparison.*
- **Research tasks live inside the data (status/priority), not an external tool** (3-0)
  → Block 1. *Source: grampshub.com, grampsweb.org/user-guide/tasks (primary).*
- **Record hints = killer SaaS feature; suggest, never auto-accept** (3-0) → Block 3.
  *Sources: support.ancestry.com/articles/Ancestry-Hints; critique: genealogybargains.com
  "drowning in hints".*
- **AI photo (colorize/enhance/repair) = MyHeritage paid differentiator → optional
  only** (3-0) → Block 3. *Source: education.myheritage.com (primary).*

**Caveats (from the research pass — read before locking the roadmap):**
- **H/M/L demand and effort/time estimates are interpretive** engineering judgment
  against the current Heartwood stack, not derived from sources — calibrate on the
  real code.
- **The "what users request / what annoys them" angle is the weakest-verified.** Hint
  inaccuracy is well-documented, but a systematic Reddit/forum review was not
  completed — a focused follow-up on r/Genealogy and webtrees/Gramps forums is worth
  doing before committing Block 2/3 priorities.
- **Vendor specifics are time-sensitive** (MyHeritage 2024 redesign, FamilySearch
  Portrait view 2025, pricing) — re-verify exact numbers before relying on them.
- **Two claims were refuted and excluded:** the exact GEDCOM surname/given-name
  reversal mechanism in webtrees #2279 (the *principle* of standard-adherence still
  holds), and the exact four-role set in Gramps Web (roles exist; the specific
  owner/editor/contributor/member names were not verified).

Open questions the research could not settle: (1) per-user vs shared-tree architecture
(see 0.1); (2) whether self-hosted record-hints matching scales on SQLite + Solid Queue
or needs a search index; (3) an AGPL-friendly self-hostable path for AI photo work.
