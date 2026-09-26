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

## Phase 1 — CSS foundation (no visual redesign yet, just the right base)
Reference: campfire/writebook `app/assets/stylesheets/`.
- [ ] Add `_reset.css` and `utilities.css` (`--inline-space`, `--block-space`, `.txt-*`,
      `.flex`, `.gap`, `.margin-block-*`, `.for-screen-reader`, `.hide`).
- [ ] One token system: replace the ~170 legacy hex aliases (`--line`, `--muted`,
      `--surface`, `--accent`…) with `--color-*` roles; move all 19 hex literals and ad-hoc
      shadows into `colors.css` (incl. `--color-male`/`--color-female`).
- [ ] Dark mode: redefine only `--lch-*` under `prefers-color-scheme: dark`, as the references do.
- [ ] Split the 1006-line `application.css` into one file per component (`layout`, `nav`,
      `flash`, `forms`, `people`, `events`, `tree`, `drawer`, `auth`, `maps`, `hints`…).
      While moving: nested blocks, logical properties, `:where()` defaults, merge duplicates.

## Phase 2 — Page frame and navigation
Reference: writebook `layout.css` + `content_for :header`; campfire flash toast.
- [ ] Grid `layout.css` with `#header`/`#main`; full-bleed tree/map via a body class, not `:has()`.
- [ ] Shared header: tree name ▸ page breadcrumb, back button, one consistent
      People / Tree / Map nav, members/settings icon. Pages `content_for :header` actions
      instead of each building its own button row.
- [ ] Icon buttons with screen-reader labels; wrapping toolbars; tree toolbar collapses on
      phones. Real mobile layout (today there are no responsive media queries).
- [ ] Flash as a self-removing toast (campfire `element-removal`).
- [ ] `page_title` helper: "Person · Tree · Heartwood".

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

## Open decision
- Product name — decide before Phase 2 (header, logo, copy) — see [[positioning]].
