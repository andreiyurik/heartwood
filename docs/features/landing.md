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
1. **Hero** — the pain and the promise in one line: *collect the family's story together, while
   there's still someone to ask.* Primary CTA "Начать бесплатно" → `/registration`; secondary
   "Войти". A real screenshot of a tree.
2. **The pain** — memory leaves quietly: grandparents' stories never written down, photos
   without names scattered across chats and boxes, every relative holding one piece.
3. **How it works** — three steps: create a tree → send relatives a link → fill it in together,
   changes appear for everyone at once.
4. **Why it matters** — children who know their family's stories are more resilient (Duke &
   Fivush, Emory University, "Do You Know?" scale); a tree is something you hand down.
5. **What's inside** — only shipped features: live collaboration, history & undo, sources,
   map, relationship finder, photos & biographies, GEDCOM in/out with Gramps.
6. **Your data is yours** — stored in Russia (only shown when the operator says so), never
   sold, no ads or trackers inside the app, export any time, open source (AGPL), delete in one
   step. Each line links to where it's true (policy, export, source code).
7. **Pricing** — Free up to `Tree::PLANS["free"][:people_limit]` people; Family without limits
   (price shown once billing ships).
8. **FAQ** — `details/summary`, no JS: safety, "what if you shut down", moving from MyHeritage /
   «Древо Жизни», who sees living relatives, do relatives need an account, price.
9. **Final CTA**, then a footer with the legal documents and the source code link.

## Rules
- Same design language as the app ([[design-system]]): tokens, `.btn`, quiet chrome. Wider
  measure and bigger type than app pages, but no new colours, shadows or radii.
- No claim the product can't back today. When a feature ships, add it; never the reverse.
- No analytics until the paid-ads step; then Yandex.Metrica on this page only, with a notice
  and a line in the privacy policy ([[accounts-and-legal]]).
- Copy lives in `config/locales` (`landing.*`), Russian first.
