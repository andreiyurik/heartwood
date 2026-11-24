---
title: Getting started
tags: [feature, onboarding, growth]
status: stable
---

# Getting started

Basecamp teaches itself with the product, not around it: no tour, no tooltips, no video. An empty
screen says what goes there; the first steps are real work. The family tree's value arrives when the
first relative does ([[launch-ru]]), so the first minutes lead there.

## The three steps
Once the tree has its first person (before that the blank slate does the asking), editors see
**"Getting started"** at the top of the people page:

1. **Add yourself** — done when the tree has anyone in it.
2. **Add parents and grandparents** — done when the tree holds three generations (someone whose
   parent has a parent). The button adds parents to the earliest-added person who has none yet:
   first you, then your father, and so on — "Add parents — Ivan".
3. **Ask the family what you don't know** — done when the tree has a question ([[questions]]) or a
   member besides the owner. The button asks about the latest person without a birth date (else the
   latest added): "Ask about Grandma Vera".

Each step ticks itself from the tree's real state, never from a click. "1 of 3" sits beside the
title. When all three are done the block is gone; "Hide" (×) puts it away for that member for good
(`tree_memberships.getting_started_hidden_at`).

Viewers don't see it: none of the steps is theirs to take.

## Rules
- No checklist for things that don't move the family forward (crest, settings, import): the crest
  has its own step right after sign-up, import its button on the blank slate.
- One button, on the next step only. Done steps stay, ticked and quiet, so progress is visible.
- `GettingStarted` reads the tree; it stores nothing.

## Not yet
- A first screen of its own for a relative who joins by invitation.
