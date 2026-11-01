---
title: Launch market — Russia first
tags: [business, launch, legal]
status: draft
---

# Launch market — Russia first

Decided 2026-11-01: the hosted plan launches for the **Russian-speaking market (RF)** first.
The open core stays bilingual and international; this note is about the *hosted* service.
See [[positioning]], [[pricing-hosting]], [[open-core]].

## Why Russia first
- Weaker competition: MyHeritage and «Древо Жизни» dominate; Ancestry is practically absent.
- Strong demand for family history (archives, «Бессмертный полк», ВГД forum community).
- We already ship Russian as a first-class locale.

## What it changes
- **Personal data law (152-ФЗ).** Personal data of RF citizens must be first recorded and
  stored on servers located in Russia (art. 18 §5). The hosted instance and its backups run
  in a Russian data center — Timeweb Cloud (VPS + S3), decided 2026-11-01. Before launch: notify
  Roskomnadzor as a personal-data operator, publish a privacy policy («Политика обработки
  персональных данных»), collect explicit consent at sign-up, and give users account deletion.
- **Payments.** Stripe does not work in RF. Use ЮKassa or CloudPayments (cards + СБП),
  integrated in the private Cloud Engine per [[open-core]]. A one-time payment per year fits
  the existing `Tree#activate_family!(period:)`.
- **Analytics and ads.** Yandex.Metrica and VK Ads pixels go **only on the landing page**,
  never inside the app — the "your data never leaves" promise must stay literally true.
- **Channels.** ВГД (vgd.ru), genealogy communities on VK and Telegram, Yandex Direct,
  content about «как составить родословную». Paid ads only after the funnel is proven on a
  closed beta (metric: relatives invited per tree).

## Trust features that gate a paid launch
1. ✅ [[change-history]] — who changed what, and one-click undo/restore.
2. ✅ [[accounts-and-legal]] — policy, separate consent, terms, account deletion, 90-day history.
3. ✅ [[backups]] — verified snapshots every 6 hours, off-site in Russia, restore drill.
4. ✅ [[landing]] — the story for signed-out visitors.
5. ✅ Archive with photos — GEDZIP layout as `.zip`, and its import (see [[import-export]]).
6. View-only share links (see [[privacy-access]]).

## Before the first real user (outside the code)
- Register the operator (ИП/ООО), fill the `OPERATOR_*` settings, have a lawyer review the
  three documents, notify Roskomnadzor.
- Rent a Timeweb Cloud VPS and two Timeweb S3 buckets (photos, backups); set `STORAGE_*` and
  `BACKUP_*`, versioning on the photo bucket, a 30-day lifecycle rule on the backup bucket.
- Run the restore drill once on staging.
