---
title: Landing page
tags: [feature, marketing, growth]
status: draft
---

# Landing page

What a signed-out visitor sees at `/`: the case for keeping a family history, and for keeping it
here. Part of the launch plan ([[launch-ru]]); the positioning it sells is [[positioning]].

## Routing
`/` is the landing for guests and the People list for anyone with a live session — decided in
`config/routes.rb` by a constraint on the session cookie, so `root_path` keeps meaning "home"
inside the app and signed-in people never take an extra redirect. A stale cookie counts as a
guest. Guests get Russian or English from `Accept-Language` until they pick one.

## The story, top to bottom
The page is a run of full-width bands, each with its own shape, so the eye never reads the same
three-column grid twice. Warm paper (`--color-cream`) alternates with the white surface.
1. **Hero** (cream) — the promise in three lines at most, its last words under the yellow marker
   (`<mark>`, kept on one line on wide screens):
   *collect the family's story together, while there's still someone to ask.*
   - **The first step is taken here.** One field, "your family's name", with the tree's crest at its
     start, drawn as the name is typed (`crest-preview`: the same letter and hue `Tree::Crest`
     will give the tree), and "Начать бесплатно". It is a GET to `/registration?tree_name=…`, which
     arrives with the name filled in and the cursor on the person's own name; after sign-up the
     crest step follows, so the shield the visitor watched appear is the one they then finish.
     Only a family name, never a relative's: nothing personal is typed before consent.
   - **"See an example — the Rurikids' tree"**: the real, read-only example tree, no sign-up, when
     the install sets `DEMO_URL`. The album card links there too.
   - Beside it a **family album**, not the interface: Yaroslav the Wise and his parents in
     public-domain portraits (the 1672 *Tsarsky titulyarnik*, Losenko's Rogneda) as a person card
     with dates, and two notes the family "left" — a daughter adding a portrait, a son passing on
     his father's words. It shows the feeling (relatives filling one story) before the product.

2. **Now → with Heartwood** — the pain as a before/after: stories in someone's head, photos in
   chats, everyone with one piece → one tree everyone adds to.
3. **How it works** — three numbered steps, then the real tree screenshot in a window frame.
   Screenshots are cropped to 3:2 from the top so they never outgrow a laptop screen, and each
   has a dark twin (`*.dark.png`, served by `<picture>` under `prefers-color-scheme: dark`):
   a light app window on a dark page glares.
4. **Why it matters** (yellow band) — the Duke & Fivush finding as a large pull quote, then
   three short reasons.
5. **What's inside** — only shipped features, icons in a list beside the profile screenshot.
6. **A letter from the maker** — Basecamp's trust device: why Heartwood exists and what it
   promises, first person, signed by name with a photo (`landing/founder.jpg`; initials until
   it exists). No invented testimonials — until real families speak, the maker does. Hosted
   only: the maker's promises are about the server he runs, so the letter
   (`landing/_letter`) renders through the `landing_letter` cloud slot ([[open-core]]) and a
   self-hosted install shows none.
7. **Our promises** (cream) — stored in Russia (only when the operator says so), no ads or
   trackers, living people hidden, export or delete any time, open source, backups. Each links to
   where it's true.
8. **Pricing** — two plan cards (a collection, so cards are right): Free up to
   `Tree::PLANS["free"][:people_limit]` people; Family without limits.
9. **FAQ** — `details/summary` in two independent columns (opening one never moves the other),
   a `+` that turns into `×` when open, no JS.
10. **Final CTA** band, then the footer with the operator, legal documents, the [[guides]] and
    source link.

## The example tree
`db/demo/rurikids.rb` builds "Рюриковичи", Rurik to Vladimir Monomakh: 19 people, all long dead
(so a guest on the view link sees every one of them), with portraits, sources, places and a full
chronology for Yaroslav. The development seeds use it; a live install builds it under an account
of its own (one account owns one tree) and gets the address for `DEMO_URL`:

```bash
bin/rails demo:rurikids OWNER=demo@example.org   # prints DEMO_URL=/shared/<token>
```

## Rules
- Same design language as the app ([[design-system]]): tokens, `.btn`, quiet chrome. The
  landing is the one page that leaves the sheet: full-width bands, bigger type (18px body,
  up to 56px titles), the warm `--color-cream` and the marker (`--color-highlight-border`). No
  other new colours, shadows or radii.
- No claim the product can't back today. When a feature ships, add it; never the reverse.
- Analytics on this page only, never inside the app. The hosted engine fills the
  `landing_analytics` slot ([[open-core]]): Yandex.Metrica, off until `YANDEX_METRICA_ID` is
  set, loaded only after the visitor accepts the notice, with a line in the privacy policy
  ([[accounts-and-legal]]). Self-hosted installs have no analytics at all.
- Copy lives in `config/locales` (`landing.*`), Russian first.
