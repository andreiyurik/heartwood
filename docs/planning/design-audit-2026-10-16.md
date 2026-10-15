---
title: Design audit — every screen against the Basecamp bar (2026-10-16)
tags: [planning, design, audit, ux]
status: stable
---

# Design audit — every screen against the Basecamp bar

A walk through every screen of Heartwood on the `basecamp-design-language` branch (after
[[redesign-plan]] Phase 6), the way a 37signals designer would do it: desktop 1280px, phone
375px, light and dark, English and Russian, as the owner (`dev@heartwood.ru`, the Pushkin
seed tree), as a freshly registered owner with an empty tree, and as someone opening an
invite link without an account. Screens: sign in (and its error), register, forgot password,
join, empty tree, people list (search, filters, no matches), profile (rich and sparse),
account menu, add/edit person, inline event / relative / source forms, the profile `…` menu,
relationship calculator, clan tree, person tree with the slide-over panel, map, members,
settings, duplicates, GEDCOM import, flash toast.

The rules are in [[design-system]]; this note records what still falls short of them,
ranked by how much it costs a relative who opens the tree for the first time. Each item says
what was done about it. Anything left open is in §3 and in [[design-system]] §6.

## 1. What the walk found, ranked by impact

### Bugs (a product can't look like Basecamp while it 500s)

1. **The relationship calculator crashed on the first keystroke.** The search form on
   `relationships/show` never sent `person_id` and `for=relationship`, so the autocomplete
   endpoint raised `RecordNotFound`. The controller test only called the endpoint with the
   right params, so nothing caught the view. *Fixed; the test now asserts the form carries
   both hidden fields.*
2. **Inline form titles were Title-Cased by CSS.** `.inline-title { text-transform:
   capitalize }` turned "Add source for Birth" into "Add Source For Birth" and did the same
   to Russian. *Fixed: no transform; the copy carries its own case.*
3. **The map was a blank planet.** With no located place in the tree, `/map` showed the whole
   world with no pins and no explanation; the profile's "Show on the map" revealed the same
   emptiness. *Fixed: both show a blank slate that says what to do (add a place to a life
   event), and the profile hides its map section until one of the person's events is
   located.*

### Hierarchy on the profile (the most-visited page)

4. **The facts block repeated the metadata line.** "Sex · Status" under the name said the
   same thing as "1799 – 1837 · Male" right above it; in Russian it even produced "Умер(ла)".
   *Fixed: the metadata line carries nickname · years · sex · Living; the facts block is gone.*
5. **A two-page biography pushed the structure off the screen.** Opening Pushkin's page you
   scrolled past 600px of prose before reaching his birth, death, parents or children — the
   things a relative came for. *Fixed: order is now Life events → Family → Biography →
   Sources → Memories → Map, the Basecamp "record then its discussion" shape.*
6. **Every event row shouted three actions.** "+ Add source · ✎ Edit · 🗑 Remove" were
   always visible at 60% on all twenty rows; on a phone they wrapped under every row and
   doubled its height. Basecamp reveals row controls only on hover. *Fixed: round icon
   buttons (with titles and screen-reader labels) that are invisible until the row is
   hovered or focused, and always visible on touch screens where they fit on one line.*
7. **Three "add" buttons after the events list** ("Add event", "Birthplace", "Where they
   lived") read as three different features; "Birthplace" next to an existing Birth row
   invited a second birth. *Fixed: one "Add event".*
8. **Family was plain text with "None recorded." noise.** Four headings, bare names, a
   "None recorded." line under each empty group, and a "+ Add parent" after it — twice the
   height it needed and none of the identity of the People list. *Fixed: relatives are the
   same rows as the People list (avatar · name · years); empty groups show only the add
   button for editors, and Siblings disappears when there are none.*

### Forms

9. **"More details" fields were indented twice** (the `<details>` block was offset to the
   field column, then each field inside it had its own label column), which squeezed the
   biography editor to 240px on a 1280px screen. *Fixed: only the summary line is offset; the
   fields inside line up with the others, and the biography stacks its label above a
   full-width editor.*

### Chrome and wayfinding

10. **An unlabeled download icon was the only export.** Next to "Add person" sat a circle
    with an arrow; nobody new would guess it exports GEDCOM. Import lived as a stray link at
    the bottom of Settings. *Fixed: "Import GEDCOM" (editors) and "Export GEDCOM" (everyone)
    are labelled items in the account menu, in the same group as Members / Settings; the
    header icon and the Settings link are gone.*
11. **The Edit action on a profile was an icon only** while its neighbour "Tree" had a
    word. *Fixed: "Edit" is icon + label, like Basecamp's toolbar.*
12. **On a phone the tree's name vanished** from the toolbar (only 🌳 remained), so a
    relative who had just joined did not see which tree they were in. *Fixed: the name stays
    and truncates with an ellipsis.*
13. **Members did not explain roles**, and the remove control was a solid red circle on
    every row. *Fixed: one metadata line under the title says what editors and viewers can
    do; remove is a quiet ghost icon that turns red on hover.*
14. **Duplicates showed "Scan now" twice** (toolbar and blank slate). *Fixed: the toolbar
    button appears only when there is a list to re-scan.*
15. **All initials avatars were the same green**, so a list of fourteen people was fourteen
    identical discs. Basecamp hashes the name into a hue. *Fixed: a stable hue per name
    (`--avatar-hue`), light and dark.*

## 2. What already meets the bar (keep it that way)

The sheet, the quiet toolbar and 36px titles, the people rows, the account menu, the inline
forms (label-left), the blank slates on the empty tree and on sources/memories, the flash
pill, the tree drawer, the dark theme, the sign-in / register / join cards, the phone layout
of the people list and forms.

## 3. Still open after this pass

- **Dates print as raw GEDCOM strings** ("26 МАЙ 1799"); a date presenter that renders
  `date_start` in the viewer's locale is domain work, not design — see [[domain-model]].
- **The tree page's "Scroll to zoom · drag to pan …" strip** is a permanent instruction
  line; Basecamp would show it once. Left as is until the tree gets a proper first-run.
- **The profile is still long** for a person with twenty events; the nav does not tuck
  away on scroll ([[design-system]] §6).
- **Comments on a person**, **avatar upload from the Memories section**, and the
  **project-home dock** remain the next bar ([[design-system]] §6).
- **Sign-in errors** arrive as a toast that fades in five seconds; an inline message under
  the form would survive a glance away. Campfire does the same toast, so it stays.

## Related
[[design-system]] · [[redesign-plan]] · [[prior-art]] · [[collaboration]] · [[person-profile]]
