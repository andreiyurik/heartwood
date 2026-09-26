---
title: Redesign Plan (canonical 37signals style)
tags: [planning, redesign, design, refactor]
status: draft
---

# Redesign Plan

Bring Heartwood to the bar in `CLAUDE.md`: a canonical Rails 8.1 + Hotwire app, built as if
37signals made it — simple, intuitive, functional. Based on a 2026-09-26 audit of our CSS,
screens and code against **once-campfire** and **writebook** (`~/dhh-references/`,
see [[prior-art]]). The references run edge Rails; we stay on stable 8.1 ([[stack]]) — check
every borrowed API exists in 8.1.

One phase ≈ one PR (or a few small ones). TDD throughout; system tests must stay green.
Order: bugs → CSS foundation → frame/nav → the new-user journey → code canon.

## Phase 0 — Bugs found by the audit
- [x] Invite "copy link" does nothing: `data-clipboard-target` input sits outside the
      `data-controller="clipboard"` button (`tree_memberships/index.html.erb`). Put the
      controller on the wrapper; add a visible label.
- [x] Viewers see Edit/Remove on events and "add citation" (`events/_event.html.erb`,
      `citations/_add_link.html.erb`) — gate on `can_edit?`.
- [x] Leaflet CSS linked twice (`stylesheet_link_tag :app` already includes it).
- [x] `<html lang>` missing, no skip link / `id` on `<main>`, hardcoded `aria-label="Language"`.
- [x] Bad join code renders a blank 404 — now raises `RecordNotFound` → the standard 404 page,
      as campfire does (a branded 404 comes with Phase 2).

## Phase 1 — CSS foundation (no visual redesign yet, just the right base) ✅
Reference: campfire/writebook `app/assets/stylesheets/`. Each step was verified by diffing
computed styles on 22 pages (light + dark) before and after.
- [x] `_reset.css` (campfire's) and `utilities.css` (`--inline-space`, `--block-space`,
      `.txt-*`, `.flex`, `.gap`, `.margin-*`, `.pad-*`, `.for-screen-reader`, `.shadow`).
      Campfire's control base in `base.css`: one hover halo + focus ring for every
      button/input (checkboxes, radios, file pickers and selects keep the native look).
- [x] One token system: legacy aliases and all hex/rgba literals gone; `--color-surface`,
      `--color-male`/`--color-female`, `--color-negative-border`, `--color-always-white`.
- [x] Dark mode: only `--lch-*` redefined under `prefers-color-scheme: dark`; Lexxy reads our
      roles (`rich_text.css`). Map tiles stay light (OSM has no dark tiles).
- [x] `application.css` split into one file per component and rewritten in campfire style
      (nested blocks, logical properties, merged duplicates, why-only comments).
- [ ] Deferred to phases 2–4: re-express spacing with `--block-space`/`--inline-space` and a
      small `.txt-*` scale as each screen is redesigned (a visual change, not a refactor);
      rename `--maxw`/`--radius` with the new `layout.css`.

## Phase 2 — Page frame and navigation ✅
Reference: writebook `layout.css` + `content_for :header`; campfire flash toast.
- [x] Grid `layout.css` with `#header`/`#toolbar`/`#main`; full-bleed tree/map via
      `content_for :body_class` (`full_bleed` helper) → `body.full-bleed`, not `:has()`.
      `--maxw`/`--radius` are now `--main-width`/`--border-radius`.
- [x] Shared header: 🌳 tree name (a switcher when there are several) ▸ page as breadcrumbs,
      back button (`back_link`), People / Tree / Map in `#toolbar`, members and sign-out icons.
      Pages pass actions through `content_for :header`. No settings icon yet — there is no
      settings screen until the tree can be renamed (Phase 3).
- [x] Icon buttons (`icon_link_to`/`icon_button_to`) with screen-reader labels; the header wraps;
      the tree toolbar collapses into `<details>` on phones (`collapse-on-mobile`).
- [x] Flash as a self-removing toast (`element-removal`, adapted from campfire; keeps the text).
- [x] `page_title` helper: "Person · Tree · Heartwood" (also feeds the header breadcrumb).
- [x] Branded, bilingual `public/404.html`.
- [ ] Still open: spacing on the remaining screens moves to `--block-space`/`--inline-space` as
      each is redesigned in Phases 3–4.

## Phase 3 — New-user journey ✅
Reference: campfire `users/new` via join code, `first_runs`; writebook blank slate.
- [x] Invite link → signup form showing the tree; user and membership in one request
      (`User.sign_up!`). Self sign-up asks for the tree name and creates the tree with it.
- [x] Empty tree = one blank slate: "Add yourself" (prefilled from the account name) /
      "Import GEDCOM". Search, filters, export and the Tree/Map navigation appear once there are people.
- [x] **GEDCOM import UI** — `resource :import`, `Import` model (Active Storage file, status,
      counts, warnings), `ImportJob`, live status through `broadcasts_refreshes`.
      Failures (no people, plan limit) import nothing.
- [x] Name/rename the tree: `resource :settings` (owner only), settings icon in the header.
- [x] Failed sign-in: the card shakes, the fields turn red, the email is kept.
- Not done: the import has no preview/dry-run step and does not merge with existing people
  (see [[import-export]]); re-importing a Gramps round trip adds duplicates for the duplicate
  scan to flag.

## Phase 4 — Person page, forms, members ✅
Progressive disclosure: the common fields first, depth one click away.
- [x] Person form: given names, surname, sex visible; prefix, suffix, nickname and biography in
      `<details>` (open when filled or on errors). The photo changes from the profile header
      on file selection (`auto-submit`), no longer inside the form.
- [x] Citation form: source title, page, confidence first; the rest in `<details>`.
- [x] Members page: labelled editor/viewer select that submits on change; Web Share button
      (hidden where `navigator.share` is missing). Decision: the invite link stays owner-only —
      it grants an editing seat, so who may add editors stays the owner's call ([[collaboration]]).
- [x] `aria-label` on every search input.

## Phase 5 — Code canon (do each item when touching that area; comments + fixtures early)
Reference: campfire/writebook `app/models`, `app/controllers/concerns`, `config/routes.rb`.
- [x] **Comments**: Ruby in `app/` went from 14% comment lines (273/1931) to 2% (33/1691);
      `tree_controller.js` from 90 comment lines to 28. Only "why" lines stay.
- [~] **Fixtures**: the Bach family (`bach` tree, 8 people, 3 families, events, places, a source
      and a citation; sign in as `users(:bach)`). Maps, exports, clan tree, trees, events,
      relatives, citations and the event/citation model tests use it. The graph, privacy, search
      and Gedcom tests still build their own records on purpose (they need bespoke topologies);
      `create!` calls in tests: 327 → 316.
- [x] `Person` split (371 → 48 lines) into `Person::Avatar`, `Kin`, `Living`, `Relatives`, `Searchable`;
      the tree-graph builder is the PORO `Person::TreeGraph` — it takes the viewer and an
      `avatar_url` callable, so it reads no `Current` and builds no URLs
      (`TreeGraphs` controller concern supplies both).
- [x] `PersonScoped` controller concern: one `set_person`, always through `visible_to`
      (was 5 copies with two different visibility rules).
- [x] Custom actions → noun resources: `Hints::ScansController`, `Hints::DismissalsController`,
      `Places::SearchesController`/`GeocodesController`, `People::PanelsController`/`MapsController`,
      `Maps::EventsController`, `Autocompletable::PeopleController` (`for=relative|relationship`,
      candidates from `Person#relative_candidates`), `resource :locale` via PATCH.
- [ ] `app/services/gedcom` → `app/models/gedcom`; `DuplicateFinder` → `tree.scan_for_duplicates`;
      jobs become one-liners calling model methods.
- [x] `enum :role` on `TreeMembership` (`validate: true`, so a bad role is an error, not an
      exception); `belongs_to :tree, default: -> { Current.tree }` in `BelongsToTree` (Event takes its
      tree from its eventable instead; `Person` methods use their own tree, not `Current`).
- [x] Controllers thin: `Event#cite`, `Person#relative_candidates`, `params.expect` in the
      resource controllers (sessions/passwords keep `permit` on top-level scalars); authorization
      answers `403` with an empty body — the UI hides what a role can't do.
- [x] Live collaboration: `LiveUpdates` (`broadcasts_refreshes_to :tree`) on Person, Event, Family,
      FamilyPartner, FamilyChild, Source, Citation; open list/profile/tree/map pages subscribe with
      `live_updates` and refresh. Profile and list morph; tree and map *replace* (their canvas is laid
      out by JavaScript). Forms never subscribe. `preserve-form` keeps an open inline form through a
      refresh. All hand-written `*.turbo_stream.erb` are gone: changes redirect with 303 and Turbo
      morphs the page. A GEDCOM import refreshes once, not per record.
- [x] Stimulus: `#private` members (tree, place, drawer controllers), a shared debounce in
      `helpers/timing_helpers.js` (with `cancel`), generic `auto_submit` and `autocomplete`
      (the old `search`), `hello_controller.js` deleted. No `toggle_class`: nothing would use it yet.

## Decisions
- Product name stays **Heartwood** (decided 2026-09-26); open source and community go in
  the tagline, not the name — see [[positioning]].
