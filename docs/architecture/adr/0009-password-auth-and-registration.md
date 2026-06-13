---
title: ADR 0009 — Password auth + open registration (not fizzy's magic links)
tags: [adr, auth, tenancy, onboarding]
status: accepted
---

# ADR 0009 — Password auth + open registration (not fizzy's magic links)

**Status:** Accepted · **Date:** 2026-06-13

## Context

Heartwood needed a public **sign-up** so a new visitor can create an account and start a
family tree. [[fizzy-reference-scope|Fizzy]] — our shell/Hotwire reference — implements
registration as a **fully passwordless, two-step magic-link flow**: enter email → receive a
6-digit code by email → enter your name. Login is the same code flow. It is elegant and very
"DHH", and the temptation was to port it 1:1.

The existing Heartwood auth is **password-based** (`has_secure_password`, `Session` keyed to a
`User`, a password-reset flow via `PasswordsController`). The app is **open-source and
self-hostable** (AGPL, [[adr/0003-agpl-open-core]]).

## Decision

Keep **password authentication** and add a **password-based open registration**, styled after
fizzy's centered-card aesthetic but functionally classic:

- `RegistrationsController#new/create` + `resource :registration` — email + password + name on
  one screen; on success we `start_new_session_for` (immediate login) and redirect to root.
- The owner's tree is bootstrapped on the first authenticated request by
  [[multi-tenancy|TenantScoping]] (no duplicate logic in the controller).
- A personal **welcome email** (`RegistrationMailer#welcome`, en/ru) greets the user by name
  and points them at the first step (add a person / import GEDCOM).
- `User` gains a `name` (for the greeting) and validations: name presence, email
  presence/format/uniqueness, password min length 8.
- The auth screens (sign-up, sign-in, password reset) share one fizzy-style `.auth-card`.

We **borrow fizzy's design, not its auth architecture.** Magic-link / passkey login stays a
possible future ADR.

## Why not fizzy's passwordless magic links

- **Self-host SMTP barrier.** Magic-link-only login means *every* sign-in round-trips through
  email. A self-hoster running Heartwood for their family on a home server would be forced to
  configure working SMTP just to log in. Fizzy is a hosted SaaS where mail is always available;
  Heartwood is self-host-first, so the trade-off is inverted.
- **Don't rip out working auth.** Magic links would mean deleting `has_secure_password` + the
  reset flow and adding `Identity` + `MagicLink` + a code mailer + pending-auth tokens — large,
  hard-to-reverse, and against the "[[fizzy-reference-scope|don't cargo-cult fizzy's
  complexity]]" guidance.
- **The parts the user wanted are design + onboarding**, both delivered here without the
  passwordless machinery: the calm centered card, and the personal welcome letter.

## Consequences

- ➕ Simple, self-host-friendly: works with or without SMTP (only the welcome email needs mail,
  and it's non-blocking via Solid Queue).
- ➕ One consistent auth visual across sign-up / sign-in / reset.
- ➕ Stronger `User` invariants (email format/uniqueness, password length) — note this tightened
  the password-reset test to use an 8-char password.
- ➖ Passwords to manage (reset flow already exists, so marginal).
- ➖ Diverges from fizzy functionally — accepted; magic-link/passkey can return as a later ADR if
  the hosted plan wants it.
