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

## Phase 3 — New-user journey
Reference: campfire `users/new` via join code, `first_runs`; writebook blank slate.
- [ ] Invite link → signup form that names the tree; create user + membership in one request.
- [ ] Empty tree = one focused blank slate: "Add yourself" / "Import GEDCOM" (hide search,
      filters, map, export until there are people).
- [ ] **GEDCOM import UI** — parser/mapper exist but have no route/controller/view, while the
      welcome email promises import. `resource :import` + upload form ([[import-export]]).
- [ ] Name/rename the tree (today silently "My Tree").
- [ ] Failed sign-in: shake/invalid state on the auth card.

## Phase 4 — Person page, forms, members
Progressive disclosure: the common fields first, depth one click away.
- [ ] Person form: given names, surname, sex visible; the rest in `<details>`; avatar uploads
      from the profile header on change.
- [ ] Citation form: source, page, confidence first; the rest in `<details>`.
- [ ] Members page: labelled editor/viewer switch that submits on change; Web Share button;
      decide whether editors may share the invite ([[collaboration]]).
- [ ] `aria-label` on every search input.

## Phase 5 — Code canon (do each item when touching that area; comments + fixtures early)
Reference: campfire/writebook `app/models`, `app/controllers/concerns`, `config/routes.rb`.
- [ ] **Comments**: ~13% of Ruby lines vs ~0.7% in campfire. Strip per the CLAUDE.md rule —
      worst: `person.rb`, `tree_controller.js`, `event.rb`, `tree.rb`, `relatives_controller.rb`.
- [ ] **Fixtures** for people/families/events/places/sources/citations (a named family),
      replacing most of the 327 `create!` calls in tests.
- [ ] Split `Person` (423 lines) into concerns: `Searchable`, `Living`, `Relatives`, `Kin`,
      `Avatar`; tree-graph builder as a PORO without `Current`/URL building.
- [ ] `PersonScoped` controller concern (one `set_person` + one visibility rule; today 5 copies).
- [ ] Custom actions → noun resources (`hints/scans`, `hints/dismissals`, `places/searches`,
      `people/panels`, `autocompletable/people`, `resource :locale` via PATCH).
- [ ] `app/services/gedcom` → `app/models/gedcom`; `DuplicateFinder` → `tree.scan_for_duplicates`;
      jobs become one-liners calling model methods.
- [ ] `enum :role` on `TreeMembership`; `belongs_to :tree, default: -> { Current.tree }`.
- [ ] Controllers thin: `Event#cite`, `Person#relative_candidates`, `params.expect` everywhere;
      authorization answers `403`.
- [ ] Live collaboration: `broadcasts_refreshes` + morphing, so relatives see each other's
      edits; drop most hand-written `*.turbo_stream.erb`.
- [ ] Stimulus: `#private` members, shared `timing_helpers.js` debounce, generic
      `auto_submit`/`autocomplete`/`toggle_class`; delete `hello_controller.js`.

## Decisions
- Product name stays **Heartwood** (decided 2026-09-26); open source and community go in
  the tagline, not the name — see [[positioning]].
