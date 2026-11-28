---
title: Pricing & Hosting
tags: [business, pricing]
status: draft
---

# Pricing & Hosting

The optional paid plan. Built on [[multi-tenancy]] and the [[open-core]] split. Early thinking
— validate with real users before committing.

## What people pay for
*Convenience and peace of mind*, never access to their own data ([[vision]] "own your roots"):
- We run, update, and back up the server.
- One-click onboarding (sign up → import [[gedcom]] → start) with no ops.
- Managed storage for [[media]] and full GEDZIP backups.

## Pricing shapes to test
- **Monthly subscription** — covers hosting + ongoing storage/compute. Natural for an
  always-on service.
- **One-time / lifetime** — appealing for a "preserve forever" product, but storage is a
  recurring cost — bound it (storage caps, or lifetime-of-product terms). Test carefully.
- **Free tier** — small trees / limited storage, to let people try before paying.

## The honest pitch to users
> "The app is free and open — you can host it yourself forever. Pay us only if you'd rather we
> handle the server. Either way, your data is yours and leaves with you via GEDCOM."

This framing turns the open core from a threat into the trust-builder that *drives* paid
conversions.

## Price (RF launch)
Decided 2026-11-03: **Family — 1 490 ₽ per tree per year**, paid once a year by card or СБП
through ЮKassa, with a fiscal receipt (54-ФЗ) from «Чеки от ЮKassa». Free stays at
`Tree::PLANS["free"][:people_limit]` people. No auto-renewal (no stored cards): the owner pays again,
and a payment before expiry extends from the current end date; an expired tree keeps every person and only stops adding new ones
(`Tree#effective_plan`). Revisit after the closed beta.

## Paying that feels like backing a project (decided 2026-11-28)
The plan is a service with a receipt; the warmth is in how it is offered, never in a second,
blurry kind of money. Donations stay a separate button ([[open-core]] `thanks`).

- **One plan, three amounts.** 1 490, 2 490 or 4 990 ₽ a year, the same plan for each — the page
  says so in plain words: nothing more unlocks, the rest helps the project live. It is still
  payment for the service (one receipt), not a gift.
- **One pays, the whole family uses it.** Any member of the tree can pay, not only the owner.
- **Chipping in by link.** The plan section carries a link "pay for our tree" for the family
  chat: whoever opens it pays without an account (an email for the receipt, a name if they
  want the family to see it). The link can only pay; it shows the tree's name and nothing else.
- **The keeper.** Whoever paid last is the tree's keeper: one quiet line for every member —
  «Древо хранит Вера — оплачено до 28 ноября 2027». No badges anywhere else.
- **A soft threshold.** The free plan is `people_limit` people; the next `grace` (10) still go
  in, with a note that the tree has outgrown the free plan. Nobody is stopped in the middle of
  an evening of typing. The hard stop is `Tree#people_cap`.
- **The promise at the moment of paying.** Stop paying and nothing is lost; all the money back
  within 14 days (the offer's own term), no questions.
- **Letters, not mailings.** A signed thank-you after a payment; the owner is told when someone
  else paid for their tree; a month before the end, the reminder.
- **Open numbers** (`OPEN_NUMBERS=on`): on "About", how many families keep a tree here, how many
  of them pay and what came in over twelve months — and, if set, what the servers cost.
- **Never:** timers, "today only", auto-renewal, nagging on every screen, marks that split
  relatives into payers and the rest.

## Billing implementation
Lives in the private Cloud Engine ([[open-core]]). Keep the integration (ЮKassa/CloudPayments for the RF launch — see [[launch-ru]]; Stripe elsewhere)
out of the AGPL core entirely.
