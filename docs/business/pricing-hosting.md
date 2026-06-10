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

## Billing implementation
Lives in the private Cloud Engine ([[open-core]]). Keep the integration (Stripe or similar)
out of the AGPL core entirely.
