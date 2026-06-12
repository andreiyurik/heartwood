---
title: MVP Implementation Plan
tags: [planning, implementation, mvp, checklist]
status: draft
---

# MVP Implementation Plan (Block 0)

Task-level, checkable breakdown of the **public-SaaS MVP** from [[mvp-and-growth]].
Ordered by dependency: tenancy first (everything scopes through it), then privacy,
then user-facing features. Each workstream lists concrete files, migrations, and a
**Done when** acceptance gate. Keep it TDD per [[stack]] — write the test in the same
step it's listed.

## How to use this checklist

- Tick `- [x]` as you land each step (commit the doc with the code).
- A workstream is shippable only when its **Done when** boxes are all ticked.
- `→ file` marks the file to create (new) or edit (existing).
- Hard ordering: **0.1 → 0.2** are blocking and come before any of 0.3–0.8.
  0.3–0.8 are independent of each other once 0.1 lands.

---

## Phase 0 — decisions to lock before coding

- [x] **Tree architecture chosen**: per-user private trees with in-tree collaboration
      (assumed default) vs single shared tree. See [[mvp-and-growth]] §0.1. *This plan
      assumes per-tree.*
- [x] **Tenant key naming** decided: `Tree` model (recommended) vs `Account`. This plan
      uses `Tree`.
- [x] **Scoping strategy** decided: explicit association-scoping via `Current.tree`
      (recommended — fewer footguns) vs `default_scope`. This plan uses explicit
      association scoping, with a model guard as belt-and-suspenders.

---

## 0.1 — Tenancy & data ownership  ⛔ blocker

Goal: every domain record belongs to a `Tree`; a user only ever reads/writes records
in a tree they're a member of. **Why scoping targets listings + find-by-id:** record
ids are globally unique, and the tree graph traversal follows FKs from an
already-loaded person — so the only cross-tenant leak vectors are *enumerating* queries
(`Person.order` in `index`) and *direct* `Person.find(params[:id])`. Scope those two and
the rest stays in-tree.

### Models & migrations
- [x] `Tree` model + migration → `app/models/tree.rb`, `db/migrate/*_create_trees.rb`
      - columns: `name:string`, `created_at/updated_at`
- [x] `TreeMembership` join model + migration (sets up [[collaboration]] later)
      - columns: `tree_id` (FK), `user_id` (FK), `role:string` (default `"owner"`),
        unique index on `[tree_id, user_id]`
- [x] Migration: add `tree_id` (FK, indexed) to `people`, `families`,
      `family_partners`, `family_children`, `events`
      → `db/migrate/*_add_tree_to_domain_tables.rb`
      - **Backfill**: assign all existing rows to a single bootstrap tree owned by the
        first user (data migration in the same migration or a `rake` task)
      - Set `null: false` on `tree_id` *after* backfill
- [x] Associations:
      - `Tree has_many :people, :families, :events, :tree_memberships, :users (through)`
      - `User has_many :tree_memberships`, `has_many :trees, through:`
      - `Person/Family/Event/FamilyPartner/FamilyChild belongs_to :tree`
- [x] Model guard (belt-and-suspenders): a `BelongsToTree` concern that validates
      `tree_id` presence and (optionally) asserts associated records share the tree
      → `app/models/concerns/belongs_to_tree.rb`

### Request-scoping layer
- [x] Add `attribute :tree` to `Current` → `app/models/current.rb`
- [x] Resolve `Current.tree` per request from the membership (or a session-selected
      tree id) → `app/controllers/concerns/authentication.rb` or a new
      `TenantScoping` concern included in `ApplicationController`
- [x] `PeopleController#index`: `Person.order(...)` → `Current.tree.people.order(...)`
      → `app/controllers/people_controller.rb:7`
- [x] `PeopleController#set_person`: `Person.find` → `Current.tree.people.find`
      → `app/controllers/people_controller.rb:45` (this both scopes and authorizes →
      404 for other tenants)
- [x] `PeopleController#create`: build through `Current.tree.people.new(person_params)`
- [x] `TreesController#find_person`: `Person.find` → `Current.tree.people.find`
      → `app/controllers/trees_controller.rb:16`
- [x] `EventsController` / `RelativesController`: load parent person via
      `Current.tree.people.find`; ensure newly created relatives/events inherit
      `tree_id` (set in `Person#add_parent/add_child/add_partner` and the events build)
      → `app/models/person.rb:102-119`, `app/controllers/events_controller.rb`
- [x] GEDCOM import: `Gedcom::Mapper#import!` assigns `Current.tree` (or a passed-in
      tree) to every created Person/Family/Event → `app/services/gedcom/mapper.rb`

### Tests
- [x] Model: a Person/Family/Event requires a tree; membership uniqueness
- [x] Controller: user A gets 404 on user B's person (`show`, `tree`, `events`)
- [x] Controller: `index` lists only `Current.tree` people
- [x] Integration: GEDCOM import lands all records in the importing user's tree
- [x] Fixtures updated: existing fixtures get a `tree:` association

### Done when
- [x] No controller query reads `Person`/`Family`/`Event` without a tree scope
- [x] Cross-tenant access returns 404, not another tree's data
- [x] Full suite green

---

## 0.2 — Living-person privacy  🔒 gate (depends on 0.1)

Goal: people with no death event and within a recency window are "possibly living" and
hidden from non-members / public views. Enforced in the **data/service layer** so it
also covers tree graph, export, and search.

### Model
- [x] Extend `Person#living?` with a birth-date age cutoff (e.g. born < N years ago and
      no death event) → `app/models/person.rb` (`LIVING_CUTOFF_YEARS = 120`)
- [x] `Person#visible_to?(user)` — owner/member sees all; otherwise living people are
      hidden → `app/models/person.rb`
- [x] `Person.visible_to(user)` scope for list/enumeration paths
- [x] Privacy fields in schema **now** (cheap to add, expensive to retrofit):
      `private:boolean default false` on `people` → migration
- [x] Decide the "living" recency window constant (config) and document it
      (`LIVING_CUTOFF_YEARS = 120` in `Person`)

### Enforcement points (must all honor visibility)
- [x] `PeopleController#index` uses `Person.visible_to(Current.user)`
- [x] `PeopleController#show` redaction for non-members (or 404)
- [x] Tree graph: `ancestor_graph`/`descendant_graph` emit a redacted node ("Living")
      for hidden people instead of name/birth → `app/models/person.rb` `node_data`
- [ ] GEDCOM export (0.4) skips/redacts living people for non-owner exports
- [ ] Search (0.5) excludes hidden people from non-member results

### Tests
- [x] `living?` cutoff logic (born recently / has death / unknown)
- [x] `visible_to?` matrix (member vs guest × living vs deceased)
- [x] Graph redaction: hidden person renders as "Living" node, no birth year
- [ ] Export omits living people for guest-scope export

### Done when
- [x] A guest/non-member never sees a living person's name, dates, or events anywhere
      (profile, tree, export, search)
- [x] Suite green

---

## 0.3 — Interactive tree view (finish + ship)

Engine exists (`tree_controller.js`, pan/zoom, SVG layout). Finish UX.

- [x] Click-to-refocus: clicking a node navigates to that person's tree
      → `app/views/trees/_node.html.erb`, `app/controllers/trees_controller.rb`
- [x] Mode toggle (ancestors ↔ descendants) in the UI, preserving depth
      → `app/views/trees/show.html.erb`
- [ ] Photo-in-node: render avatar `<image>` in the SVG node once 0.6 lands
      (`node_data` already returns `sex`; add `avatar_url`) → `app/models/person.rb:85`
- [x] Honor 0.2 privacy in nodes (redacted "Living" rendering — CSS + partial ready)
- [x] Empty/edge states: single-node tree works (no relatives → focus-only graph)
- [x] Tests: `trees_controller_test` covers refocus + mode + depth clamping

### Done when
- [x] A user can navigate the whole tree by clicking, switch ancestor/descendant, and
      never see a private person — green tests

---

## 0.4 — GEDCOM export

Mirror of the existing importer. **Self-contained, no schema change — good first win.**

- [x] `Gedcom::Writer` service: walk `Person→events`, `Family→partners/children`,
      emit valid 5.5.1/7.0 levels & tags → `app/services/gedcom/writer.rb`
- [x] Reuse stored `gedcom_raw`/`gedcom_xref` for round-trip fidelity of unknown tags
      → `app/models/person.rb`, `event.rb`, `family.rb` (columns already exist, schema.rb:22-23,32-33)
- [x] Strict standard adherence — no custom tags as a hard dependency (research 3-0:
      deviating breaks interop). Unknown data goes back out only from `gedcom_raw`.
- [x] `ExportsController#create` → `send_data writer.to_gedcom, filename: "tree.ged"`,
      scoped to `Current.tree` → `app/controllers/exports_controller.rb`, `config/routes.rb`
- [x] Honor 0.2: living-person redaction for non-owner exports
- [ ] Large trees: wrap in Solid Queue job + Turbo Stream "file ready" (optional for
      MVP; sync send_data acceptable initially)
- [x] i18n strings for the export UI → `config/locales/en.yml`, `ru.yml`

### Tests
- [x] Round-trip: import `minimal_551.ged` → export → re-import → structurally stable
      (use existing fixtures `test/fixtures/gedcom/`)
- [x] Export is tree-scoped (no other tenant's records)
- [x] Living-person redaction in export

### Done when
- [x] Import→export→re-import is stable; export contains only `Current.tree` data; green

---

## 0.5 — Search & filter

- [x] Choose backend: LIKE (FTS5 deferred — requires sqlite3 CLI for structure.sql)
- [x] `Person.search(query, user:)` scope (tree- and visibility-scoped via chain)
      → `app/models/person.rb`
- [x] Search UI: debounced Stimulus input → morph refresh results
      → `app/javascript/controllers/search_controller.js`,
      `app/views/people/index.html.erb`
- [x] Filters (sex) as query params, preserved in the URL → `PeopleController#index`
- [x] Honor 0.1 (tree scope) and 0.2 (hide living from non-members)
- [x] i18n for search/filter labels

### Tests
- [x] `Person.search` returns tree-scoped, visibility-scoped matches
- [x] Controller: search filters results; sex filter narrows results

### Done when
- [x] Search returns correct, scoped results; sex filter works and is shareable via URL; green

---

## 0.6 — Photos / avatars (basic)

Active Storage + `image_processing` already in the Gemfile.

- [x] `Person has_one_attached :avatar` → `app/models/person.rb`
- [ ] Variants via `image_processing` (deferred — requires libvips/ImageMagick not in env)
- [x] Upload UI: standard multipart form field (direct-upload deferred to Block 1)
      → `app/views/people/_form.html.erb`
- [x] Avatar in profile header and people list; Memories tab shows uploaded photo
- [x] Validations: content-type (JPEG/PNG/WebP) + size (5 MB); CSS initials fallback
- [x] i18n strings

### Tests
- [x] Attach avatar; content-type + size validation; fallback (no attachment)

### Done when
- [x] A person can have a photo that shows on profile and lists; green

---

## 0.7 — Minimal sources on facts

Smallest credible version of evidence; full model in [[mvp-and-growth]] Block 1.

- [x] `Source` model + migration: `title:string`, `url:string`, `citation_text:text`,
      `tree_id` (FK) → `app/models/source.rb`
- [x] `Citation` polymorphic join: `belongs_to :source`,
      `belongs_to :citable, polymorphic: true` (attach to `Event`)
      → `app/models/citation.rb`, migration
- [x] "Sourced" badge (✓) on events that have citations → `app/views/events/_event.html.erb`
- [x] Add/attach a source to an event via Turbo Stream (inline form per event)
      → `app/controllers/citations_controller.rb`, `config/routes.rb`
- [x] Tree-scoped (0.1) — `CitationsController` scopes through `Current.tree`
- [x] Sources tab shows all cited sources for the person → `people/tabs/_sources.html.erb`
- [x] i18n namespaces `citations.*` → `config/locales/en.yml`, `ru.yml`

### Tests
- [x] Source model validation; citation links source to event; cascade destroy
- [x] Controller: create/destroy citation; tree-scope blocks cross-tenant

### Done when
- [x] A fact can carry a source and shows a "sourced" badge; green

---

## 0.8 — Tabbed person profile (structure)

Adopt the verified industry-standard layout (research 3-0). Wire the above features
into tabs instead of one long page.

- [x] Tab scaffold on the profile via URL `?tab=` + Turbo morph:
      **Details / Sources / Memories (photos) / Timeline** (start with these four;
      Collaborate/About later) → `app/views/people/show.html.erb`, new partials
- [x] *Details* = the existing inline vitals editor (Person + Event)
- [ ] *Sources* = 0.7
- [ ] *Memories* = 0.6 photos/gallery
- [ ] *Timeline* = stub now (a placeholder frame), filled by the Block-1 timeline
- [x] Tab navigation works without full reload; deep-linkable (tab in URL/anchor)
- [x] i18n tab labels

### Tests
- [x] Each tab frame renders independently; default tab on load

### Done when
- [x] Profile uses the standard tabbed layout; each tab loads its own frame; green

---

## Suggested landing order (PRs)

1. **0.1 Tenancy** — the foundation; nothing public-safe ships before it.
2. **0.2 Privacy** — gate; depends on 0.1.
3. **0.4 GEDCOM export** — independent, schema-free, high-trust win (can parallel 0.2).
4. **0.8 Tabbed profile shell** — cheap scaffold that 0.6/0.7/timeline plug into.
5. **0.6 Photos** → **0.7 Sources** → **0.5 Search** → **0.3 Tree polish**.

Each PR ships with its tests green and ticks its **Done when** boxes here.

## Out of scope for Block 0 (tracked in [[mvp-and-growth]])

Full source/citation model, timeline, media gallery, notes/research-log, relationship
calculator, integrity checks (Block 1); places/maps, more chart types, collaboration,
share links (Block 2); hints, PDF, AI photo, DNA (Block 3, optional).
