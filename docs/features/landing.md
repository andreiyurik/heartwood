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
     the install sets `DEMO_OWNER`.
   - Beside it **the product's story as one scene** (`landing/_scene`, see "Scenes" in
     [[design-system]]), about six seconds, once:
     1. a small family tree **grows** from "you" upward — parents, grandparents, and an empty
        place where a great-grandmother should be;
     2. a question goes to the **family chat** («Как звали маму бабушки Анны?», an outgoing chat
        bubble with the answer link);
     3. an aunt is typing, then answers by link without signing up — a name and an **old
        photograph**;
     4. the photograph **flies from the chat onto the tree**, the branch is drawn, and the
        great-grandmother takes her place, marked the way the app marks a fresh change.
     The last frame is the resting state. The two messages look like a messenger (bubbles, time,
     ticks, "typing…") because that is where the link really travels; no messenger's brand or
     colours are imitated.
     The tree in the scene is **the visitor's**: its title and crest follow the family name typed
     in the field (`crest-preview`), so the first thing they type already has a place to live.
     The people in it are an ordinary invented family named by kinship (бабушка Анна, тётя Вера),
     not presented as customers. **The ancestors have faces, the living have initials** — as in
     the product, where living people stay hidden. The faces are public-domain studio photographs
     of the 1910s (`landing/scene-*.jpg`, sources in `app/assets/images/NOTICE.md`), toned alike.
     The Rurikids stay one click away as the real example.

2. **Now → with Heartwood** — the pain as a before/after: stories in someone's head, photos in
   chats, everyone with one piece → one tree everyone adds to.
3. **How it works** — three numbered steps, then the real tree screenshot in a window frame.
   Screenshots are cropped to 3:2 from the top so they never outgrow a laptop screen, and each
   has a dark twin (`*.dark.png`, shown by `.only-dark` so it follows the theme button too):
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
   Right after it, also hosted only (`landing_support` slot): **"The project is open, and it
   lives on support"** — the code is open and can be read, checked and self-hosted; projects
   like this last while the people who need them back them, and any amount is a signal that
   it is worth developing. One large, warm button to the operator's donation page (new tab) and
   a link to the source. It says plainly that nothing unlocks and nothing is taken away.
   Decided 2026-11-25; it is the one place a guest is asked ([[ux-audit-2026-11-10]] §4.2 kept
   the ask out of the landing body until then). Never on the pricing cards: it is not a plan.
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
chronology for Yaroslav. The development seeds use it; a live install keeps it under an account
of its own (one account owns one tree).

**`DEMO_OWNER=<email>` is all an install sets.** The container's start builds the tree under
that account when it isn't there yet (`demo:rurikids` after `db:prepare`; a failure is logged and
the server starts without the example), and the landing
finds the account's view link by itself — no token to copy, and renewing the link needs no
redeploy. The account gets a random password and no letters; an address that can't receive mail
(`demo@example.invalid`) means nobody can ever reset its password and sign in as it.
`DEMO_URL` still wins when set: any address can be the example.

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
