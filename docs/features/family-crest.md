---
title: Family crest
tags: [feature, collaboration, brand]
status: draft
---

# Family crest

Every tree wears a small crest next to its name. It makes the tree "ours" in the first minute and
makes the invitation link look personal in a family chat. Decided in [[ux-audit-2026-11-10]] §3.3;
the look follows [[design-system]].

## What the owner can do
- **Nothing** — the default crest is a shield in a colour derived from the tree's name, carrying the
  family's initial ("Род Пушкиных" → П).
- **Choose** — a shape (4), a colour (8) and a symbol (14, or the initial). An ordinary form of
  radio buttons on the Settings page; every change saves itself and the page morphs, so the header
  crest is the live preview. Any combination looks decent — that is the point of offering parts
  instead of a canvas.
- **Upload** — a family that already has a crest (or a drawing by a grandchild) attaches a PNG or
  JPEG; it replaces the drawn crest everywhere until removed.

There is deliberately **no free-form editor**: a blank canvas stops most people, and a React editor
would break [[stack]]. If someone wants more, they draw it anywhere and upload it.

## Where it shows
- The header crumb on every page, the invitation page, the members page.
- **The link preview**: `/join/:code/card.png` and `/shared/:token/card.png` are 1200×630 cards
  (paper background, the crest, the tree's name) referenced by `og:image`, so a link pasted into
  Telegram, WhatsApp or VK shows the family's crest instead of a grey box. The card carries
  nothing the page behind it doesn't already show to the same visitor: the tree's name and crest.

## How it is built
- `Tree::Crest` — `crest_shape`, `crest_hue`, `crest_symbol` columns (all optional) and
  `crest_image` (Active Storage). The shapes, hues and symbols are constants; symbols are small
  SVG fragments drawn for this project (no third-party art).
- `shared/_crest` renders the inline SVG; colours come from the same OKLCH tone as the initials
  avatars, so both schemes work.
- `Tree::Card` builds the card as SVG and rasterizes it with libvips (already a dependency for
  Active Storage variants). The production image installs `fonts-dejavu-core` so Cyrillic names
  and initials render. An uploaded crest never goes through the SVG renderer: libvips decodes it
  and lays it over the card.

## Not built
- A crest per branch or per person; heraldic rules (tinctures, charges); animated crests.
- The crest as the browser-tab icon of a tree (Campfire does this for accounts) — worth doing once
  trees have their own URLs.

## Related
[[collaboration]] · [[design-system]] · [[media]]
