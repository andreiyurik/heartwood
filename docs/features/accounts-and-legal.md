---
title: Accounts, consent & deletion (152-ФЗ)
tags: [feature, legal, privacy, trust]
status: draft
---

# Accounts, consent & deletion (152-ФЗ)

The legal minimum before real families put real data in. Gates the paid launch
([[launch-ru]]). Not legal advice: the texts are a careful template and **must be reviewed by a
lawyer** before the hosted launch, and the operator must notify Roskomnadzor (off-app).

## Operator details are configuration
The hosted service and every self-hoster are different personal-data operators, so nothing
about the operator is hardcoded. `config/operator.yml` (`Rails.configuration.x.operator`) reads
`OPERATOR_NAME`, `OPERATOR_INN`, `OPERATOR_OGRN`, `OPERATOR_ADDRESS`, `OPERATOR_EMAIL`,
`OPERATOR_HOSTING` from the environment. Unset values render as a visible «не указано»
placeholder, so a missing detail is obvious on the page rather than silently blank.

## Three public documents
`/privacy` (Политика обработки персональных данных, required by art. 18.1), `/consent`
(Согласие на обработку — since 2025-09-01 consent must be a separate document, not a clause
inside another one), `/terms` (Пользовательское соглашение). Plain server-rendered pages,
per-locale templates (`privacy.ru.html.erb` / `privacy.en.html.erb`), linked from the sign-in,
sign-up and join screens and from the account page. `Legal::VERSION` dates the current edition.

Key positions the texts commit us to (the code must keep them true):
- Databases with citizens' data are in Russia (art. 18 §5); no cross-border transfer.
- No selling or sharing; processors are only the hosting provider and the mail sender.
- No analytics or ad trackers inside the app; only essential cookies (session, locale), so no
  cookie banner in the app. On the hosted landing page only, Metrica waits for the visitor to
  accept its notice ([[landing]]).
- Data about relatives is entered by the user for personal and family purposes; the operator's
  basis is the family's legitimate interest (п. 7 ч. 1 ст. 6), kept by: only tree members see
  it, view links hide the living and are `noindex`, and anyone named can demand removal
  (`Person#erase`, 10 working days, the owner is told). See [[legal-ru]] п. 2.
- The consent also covers what other members of a tree have entered or will enter about the
  person who joins it.
- The terms: 14+; the user enters living people with their knowledge and no health, religion
  or ethnicity of the living; liability is the statutory one (no "as is" — ст. 16 ЗоЗПП); a
  rights-holder's notice is handled in 10 working days (ст. 1253.1 ГК); changes come 10 days
  ahead and never worsen a paid period.
- The landing footer names the operator (name, ИНН, ОГРН, email) once `OPERATOR_NAME` is set.
- Retention: account data until deletion; history snapshots of deleted records for
  `Edit::RETENTION` (90 days); download archives `Archive::RETENTION` (24 hours); backups up to
  30 days.
- Requests from data subjects answered within 10 working days.

## Consent at sign-up
Both sign-up paths (`/registration`, `/join/:code`) show a **separate, unticked, required**
checkbox: «Я даю согласие на обработку персональных данных» linking `/consent`, plus one line
saying that signing up accepts the terms and the policy. `User` validates
`privacy_consent` acceptance on create and stamps `privacy_consented_at` and
`privacy_consent_version` (= `Legal::VERSION`) as evidence.

## Account page & deletion
`/account` (avatar menu): who you are, download your tree (GEDCOM export), and **Delete my
account** — confirmed with the password. Deleting:
- signs out everywhere and removes the user, their memberships and imports;
- **incinerates every tree they own** (other members lose it; the page says how many and
  suggests exporting first). Ownership transfer is deferred;
- keeps trees they only joined; their history rows there stay but lose the author
  (`user_id` → NULL, shown as «Удалённый пользователь»).

`Tree::Incineratable#incinerate` (after Fizzy's `Account::Incineratable`) destroys the tree with
live updates suppressed and **purges every photo file**, including those of previously deleted
people kept for undo ([[change-history]]). It runs in `Tree::IncinerateJob`.

## Retention of history
`Edit.prune` (daily, `config/recurring.yml`) deletes edits older than `Edit::RETENTION` and
purges the kept photo files of people whose deletion is no longer restorable. Deleting a person
flagged as a possible duplicate also drops the hint (it used to fail on the foreign key).

## Deferred
- Re-consent when `Legal::VERSION` changes.
- Ownership transfer before deleting an account.
- ~~Public оферта and receipts (54-ФЗ)~~ — done in the private engine (`/offer`, receipts sent
  with every ЮKassa payment), see [[open-core]] "How the Engine plugs in".
- Cookie notice — with the landing page's analytics.
