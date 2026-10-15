---
title: Design System — Basecamp's approach, adapted
tags: [architecture, design, ui, ux, css]
status: stable
---

# Design System — Basecamp's approach, adapted

How Heartwood should look and behave, derived from a 2026-10-16 study of the live Basecamp
app (`app.basecamp.com`: home, project, to-dos, to-do list, message board, message, menus,
inline forms, blank slates) and of its compiled stylesheet, cross-checked against the open
reference apps (`~/dhh-references/`, see [[prior-art]]). The **rules** here are binding for
every screen; the **recommendations** at the end are the honest gap list against this bar.
Short version in `CLAUDE.md`; this note is the source of truth.

## 1. The seven ideas behind Basecamp's UI

1. **The page is a sheet.** The body is a quiet tinted background; the content sits on one
   white sheet (Basecamp: `--color-canvas`, max 1088px, 40px padding, a soft `--shadow-xl`,
   no border). Nothing else on screen competes with it. There are no cards inside the sheet
   for ordinary content — cards appear only for *collections of things* (project dock,
   kanban) — so a form, a profile or a list is never "a box inside a box".
2. **One quiet chrome.** Above the sheet: one slim toolbar — breadcrumbs on the left
   (`Project ‹ To-dos`), page actions on the right (`Bookmark · Edit · …`), one `…` menu
   for everything secondary. Account things (profile, settings, sign out) live behind the
   avatar. Nothing in the chrome shouts; the page title shouts.
3. **One big title, then the metadata line.** Every page opens with an `h1` at 36px /
   weight 800 / letter-spacing −0.024em / line-height 1.15, and directly under it a single
   subtle line of metadata ("Victor Cooper on Oct 10 • Announcement"). Then a small action
   row (primary button + filters). Section titles are 18px / 600. That hierarchy — one huge,
   the rest small — is what makes pages feel calm.
4. **Lists are rows, not cards.** A row = avatar (40–56px) · bold title · one subtle
   metadata line · hairline divider (`1px` at 10% ink). Counts are small round badges at
   the right edge. Secondary controls (drag handle, edit pencil) are invisible until the
   row is hovered or focused.
5. **Edit in place, never leave.** "Add a to-do" expands into a form *inside the list*
   (no modal, no new page), label-left / field-right, placeholders that read as prompts
   ("Describe this to-do…", "Type names to assign…"), a small solid primary button and a
   ghost Cancel. `Escape` cancels. Saving animates the new row in; completing slides it out.
6. **Everything is a small, flat button.** One `.btn` driven by custom properties: 32px tall
   (`--component-sm`) for toolbars and rows, 40px for page-level actions, radius 8px,
   weight 400–500, 1px border at 25% of the button colour. Variants are *mixes*, not new
   styles: `--solid` (filled, inverted text), `--ghost` (transparent, 8% tint on hover),
   `--icon`, `--round`. Hover changes background by 3–8%, never adds a halo.
7. **Motion is short and purposeful.** Durations 75 / 150 / 300ms, ease-out. Every
   animation says what happened: a yellow fade on the thing that just changed, menus
   drop in 8px, new rows slide in, removed rows slide out, invalid forms shake, the
   nav tucks away on scroll. Nothing loops, nothing is decorative.

## 2. Tokens (what we adopted into `colors.css` / `base.css` / `utilities.css`)

| Group | Basecamp | Heartwood |
|-------|----------|-----------|
| Spacing | `--4px … --96px` (4px scale) | `--block-space`/`--inline-space` (campfire) + the same 4px rhythm in component rules |
| Radius | xs 2 · sm 4 · md 6 · lg 8 · xl 12 (sheet 16) | `--radius-sm/md/lg/xl` = 4/6/8/12; `--border-radius` stays as the sheet/card radius |
| Shadows | base → sm → md → lg stacked; `xl` = `0 0 3rem 8%`; `modal`; `card` | `--shadow-sm/md/lg/xl` with the same recipe (black at 2.5–10%) |
| Components | xs 24 · sm 32 · base 40 · lg 48 | `--component-sm` 32px, `--component-base` 40px |
| Durations | fast 75 · medium 150 · slow 300 | same names |
| Easing | `--ease-out-expo` (0.16,1,0.3,1), `--ease-out-overshoot` (0.25,1.25,0.5,1) | same |
| Colour | `--color-body` (tinted page) ≠ `--color-canvas` (sheet); ink 10–70 scale; semantic `--color-text-subtle`; `--tint-ink-5/10/15/25` via `color-mix` | `--color-bg` = body tint, `--color-surface` = canvas; `--tint-ink-*` added; our OKLCH tokens stay (see [[redesign-plan]] Phase 1) |
| Type | 16px, line-height 1.5, headings 1.15, body letter-spacing −0.006em, h1 −0.024em, `text-wrap: pretty` | same |

Light mode: body tint is a barely-green off-white (Basecamp's `hsl(135 29% 97%)`); the sheet
is pure white. Dark mode: body `hsl(202 42% 7.5%)`, sheet `hsl(200 28% 14.7%)` — the sheet is
*lighter* than the body in both schemes.

## 3. Patterns (how screens are built)

- **Frame**: `#header` (sticky sheet toolbar: back · tree crumb · sections · page actions ·
  account menu) → `#main` (the sheet: `.page-header` with `h1` + `.page-header__meta`, then
  the content). Full-bleed pages (tree, map) keep the toolbar and drop the sheet padding.
- **Account menu**: avatar → `details.account-menu` listing Members, Settings (owner),
  Duplicates, language, Sign out. One place for the account, like Basecamp's avatar menu.
- **Action row**: under the title: one `.btn--primary` ("＋ Add person"), then ghost
  filters/inputs at 32px.
- **Rows**: `.person-row` (and members) = avatar 40px · name (ink, bold) · meta line ·
  divider. No dotted leaders, no green links in lists.
- **Inline forms**: `.form--inline` inside a turbo-frame, `.field` as label-left grid on
  wide screens, stacked under 40rem; buttons small; entrance `fade-in-up`.
- **Menus**: `details` + `menu.action-sheet`: 15rem, 4px padding, 32px items, hover
  5% tint, dividers, destructive item turns red on hover, `action-sheet-entrance`.
- **Blank slate**: dashed 2px warm border, bold title + one explanatory line + actions.
- **Flash**: bottom-centre dark pill (ink on canvas), `fade-in-up`, then fades and removes
  itself (campfire's `element-removal`).
- **Hover-revealed controls**: row actions (`.event-actions`) are round icon buttons at 0
  opacity until the row is hovered or anything inside is focused. Keep them focusable, give
  each a `title` and a screen-reader label; never hide the only way to do something on
  touch (they also show under `(hover: none)`).
- **Avatars**: an initials avatar hashes the name into `--avatar-hue` (`initials_avatar`
  helper); lightness and chroma are one token (`--lch-avatar-tone`), so every person gets
  their own colour and both schemes stay consistent.
- **Canvas pages (tree, map) stay sheets**: title and metadata line like every page, an
  action row, then a canvas that bleeds to the sheet's edges and takes its bottom corners
  (`canvas_page`). No permanent instruction text; a one-time tip pill instead. Canvas
  controls are ordinary round `.btn`s with `--shadow-md`.
- **Blank states everywhere a view can be empty**: the map with no located place, a person
  with no located event (the map section is simply absent), empty family groups (only the
  add button, no "None recorded." for editors).

## 4. Animations (`animation.css`)

| Name | Use |
|------|-----|
| `fade-in-up` (8px, 150ms) | inline forms, menus, flash, panels appearing |
| `action-sheet-entrance` (−8px, 150ms) | `details > menu` dropdowns |
| `yellow-fade` (3s) | the element that was just created/updated (`.just-changed`) |
| `adding` / `removing` (2rem slide, 150ms) | list rows entering / leaving |
| `pop-open` (0.3 → 1.05 → 1, 300ms overshoot) | badges, success ticks |
| `modal-appear` (0.85 → 1.02 → 1) | the tree drawer / dialogs |
| `shake-it` (±0.15em, 400ms) | invalid sign-in / form |
| `pulse` | skeleton while an import runs |

All honour `prefers-reduced-motion: reduce` (durations collapse to 1ms).

## 5. Honest recommendations — where Heartwood still falls short of the bar

Ordered by impact. ✅ = done in the 2026-10-16 passes (all fifteen are done; the next bar is in §6).

1. ✅ **Too much chrome, too little title.** The old header crammed tree ▸ page title ▸
   actions ▸ EN/RU ▸ hints ▸ settings ▸ members ▸ sign-out into one bar; the page title was
   18px in a toolbar. Now: a quiet toolbar, the title is the page.
2. ✅ **Cards inside cards.** Profile, form, settings, hints each drew their own bordered
   box on a bordered page. Now the sheet is the only box.
3. ✅ **Pill buttons with halos.** `2em` radius, 600 weight and a box-shadow ring on hover
   read as "generic Rails demo". Now the flat 8px Basecamp button.
4. ✅ **Lists with dotted leaders.** Green link names + dotted line + uppercase dates
   looked like a table of contents. Now Basecamp rows with a metadata line.
5. ✅ **No account menu.** Four icons with no labels. Now one avatar menu.
6. ✅ **Motion was either missing or jarring** (drawer slide only, flash blinks).
   Now a small, consistent set with reduced-motion support.
7. ✅ **The profile was a tab machine.** Now it reads top-down like a Basecamp record:
   facts → biography → life events → family → sources → memories → map (a collapsed
   block that resizes Leaflet when opened). The jump-link row only scrolls; `?tab=` is gone.
8. ✅ **"Relationship calculator" was a feature box on the profile.** It is now its own page,
   reached from the profile's `…` menu, which also holds "Delete this person" (the edit
   page's danger zone is gone — destructive actions live in the menu, as in Basecamp).
9. ✅ **Events were a dense grid.** Each event is a row: date first, kind bold, detail,
   place subtle, sources as a count badge; Add source / Edit / Remove sit at the right and
   brighten on hover (they stay clickable at 60% so touch and tests see them).
10. ✅ **Forms stacked label-over-field.** Every `.field` is now a field-row (bold label on
    the left, field on the right) from 40rem up, including the person form with its rich-text
    biography; phones stack.
11. ✅ **No "just changed" feedback.** Creating an event or relative redirects to
    `#dom_id(record)`; the `:target` row plays `yellow-fade` (and `.just-changed` is there for
    JS). Pure CSS, no state.
12. ✅ **The tree drawer was a different design language** (coloured header band, centred
    layout). Now a sheet-style card: avatar · name · years, action row, facts; the sex colour is
    a 4px top edge.
13. ✅ **Empty states beyond the tree.** Biography, sources, memories and the duplicates page
    use `shared/blank_slate` (title, one line, one action) — the inline, left-aligned variant.
14. ✅ **Keyboard shortcuts.** `hotkey_controller.js`: `/` focuses search (people list and
    tree), `n` adds a person, `e` edits and `t` opens the tree from a profile. Keys are shown
    in button titles and as a `<kbd>` in the search field; nothing fires while typing.
15. ✅ **Dark mode borders.** Tree, places, map and relationship styles now use the ink
    tints (`--tint-ink-10/15/25`) instead of the fixed grey tokens, so both schemes derive
    from the same rule. (`--color-border*` remain only for the Lexxy editor bridge.)

### Second pass (2026-10-16, [[design-audit-2026-10-16]])

A screen-by-screen walk found fifteen more gaps; all are closed. The ones that changed the
rules above: the profile reads **record-first** (life events and family before the
biography; the metadata line replaces the facts block), row controls are **hover-revealed
icons**, every chrome action has a **label** (Import/Export GEDCOM live in the account
menu), **avatars are coloured by name**, and **empty maps say what to do**.

## 6. Next bar (not yet started)

- **Comments on a person** — Basecamp's thread under every record is the collaboration
  surface we lack; family members have nowhere to say "I think this date is wrong".
- **Nav that tucks away on scroll** (Basecamp hides the toolbar after 100px) once pages get
  long enough to need it.
- **A project-home "dock"** for the tree: People / Tree / Map / Sources as preview cards.
- **Dates in the viewer's locale** instead of raw GEDCOM strings ("26 МАЙ 1799") — a
  presenter over `date_start`, see [[domain-model]].
- **The tree's "add relative" shortcuts** (ghost slots, panel buttons) could become one
  quieter affordance per card once the card design settles.

## Related
[[prior-art]] · [[redesign-plan]] · [[design-audit-2026-10-16]] · [[stack]] · [[person-profile]] · [[collaboration]]
