---
title: Person Profile
tags: [feature, ui]
status: draft
---

# Person Profile

The page everything orbits. Part of [[features-index]] (Must).

## What it shows
- Identity: names, photo (primary [[media]]), key dates (from [[event]]).
- **Vital events** timeline: birth, marriage(s), death, etc. — each with its
  [[source-citation|sources]] and confidence.
- **Family box**: parents, partners, children — derived via [[relationship]], each a link;
  inline "add relative" actions.
- **Facts**: occupation, religion, residence (from [[event]] attributes).
- **Media gallery**, **notes**, **sources** sections.
- **Where to look**, under the sources: a closed `details` listing the archive and memorial sites
  whose years the person lived through (the [[guides]] catalog, `ResearchSite.for`) — the war
  databases for someone who was an adult in 1941–1945, parish registers for someone born before
  1918. A site with a search template opens with the person's name already filled in, so the link
  carries the name: never shown for living people. Each row links to its guide.
- A button into the [[family-tree-view]] centered on this person.

## Hotwire shape (the canonical loop)
- The profile is a set of **Turbo Frames** — each section (events, family, media) edits inline
  without a full page load.
- "Add child / add parent / add spouse" opens a frame, submits, and Turbo Streams the new
  relative into the family box. No SPA, no custom JS. See [[stack]].
- The add-relative frame is a **combobox first**: a debounced search (reusing the
  `search` Stimulus controller) finds *existing* people in the tree and links one in a single
  click — or you fall through to the "add someone new" form. This keeps marriages between
  branches and shared children one action, not a duplicate person. Candidates exclude the focus
  person and anyone already in that relation; lookup is tree-scoped. The domain methods
  `Person#add_parent/#add_child/#add_partner` accept either attributes (build new) or an existing
  `Person` (link), so both paths share one family-wiring code path.

## Borrowed wisdom
- Gramps/webtrees person pages: keep **evidence visible** next to each fact, not hidden away
  (see [[sources-evidence]]).
- Don't bury "add relative" — it's the #1 action; make it one click from the profile.
