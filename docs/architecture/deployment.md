---
title: Deployment (Kamal)
tags: [architecture, operations]
status: draft
---

# Deployment

One VPS, one container, deployed with Kamal and served by kamal-proxy with a Let's Encrypt
certificate. The same recipe serves a self-hoster and the hosted service in Russia
([[launch-ru]]); everything installation-specific comes from the environment, so
`config/deploy.yml` and `config/environments/production.rb` stay generic. See [[stack]],
[[backups]], [[adr/0002-sqlite-production]].

## Environment
| Variable | Needed | What it does |
|---|---|---|
| `APP_HOST` | yes, for a public install | The domain (`heartwood.example`). Turns on HTTPS (`assume_ssl`, `force_ssl`), host authorization, and is the host in links inside emails. Without it the app answers on any host over plain HTTP — fine on a home LAN, but links in emails then point at `localhost`. |
| `MAILER_FROM` | no | The sender of password-reset and confirmation emails. Defaults to `Heartwood <no-reply@APP_HOST>`. |
| `SMTP_ADDRESS` | to send email | SMTP server. Without it password-reset and confirmation emails fail (and their jobs retry), so set it on any install people sign up to. |
| `SMTP_PORT` | no | Defaults to 587 (STARTTLS); 465 switches to implicit TLS. |
| `SMTP_USERNAME`, `SMTP_PASSWORD` | with `SMTP_ADDRESS` | SMTP login, kept in `.kamal/secrets`. |
| `OPERATOR_*` | hosted in RF | The personal-data operator — [[accounts-and-legal]]. |
| `STORAGE_*`, `BACKUP_*` | hosted | Photos and backups in S3 — [[backups]]. |
| `MAP_TILES_URL`, `MAP_TILES_ATTRIBUTION`, `GEOCODER_URL` | no | Map tiles and place lookup, default OpenStreetMap; `off` turns them off (not `""`: Kamal drops empty values) — [[place]]. An operator in Russia either points them at a Russian provider or turns them off: the OSM servers are abroad. |

`/up` is excluded from the HTTPS redirect and host check so kamal-proxy's health check works.

## First deploy
1. Point the domain's A record at the VPS.
2. In `config/deploy.yml`: the server IP under `servers.web`, the domain under `proxy.host`,
   uncomment the `secret` and `clear` entries you use.
3. Fill `.kamal/secrets` (never committed with real values; it reads them from the shell or a
   password manager).
4. `bin/kamal setup`, then `bin/kamal deploy` for every later release.

The SQLite databases and local uploads live in the `heartwood_storage` volume at
`/rails/storage`; backups copy them off the server ([[backups]]).

## Email in Russia
The hosted service sends mail through a Russian SMTP provider (Yandex 360 for business,
Mail.ru for business, Unisender Go) so delivery to `@mail.ru`/`@yandex.ru` inboxes works and
the addresses stay in RF ([[launch-ru]]). Set SPF, DKIM and DMARC for the domain at the
provider.

## The hosted service (`-d hosted`)
`bin/kamal deploy -d hosted` merges `config/deploy.hosted.yml` over `config/deploy.yml`: it
builds the image from the working directory with the private engine ([[open-core]]), lists
the hosted service's full `env.secret` (Kamal replaces arrays, it doesn't merge them) and the
Timeweb endpoints. With a destination Kamal reads secrets from `.kamal/secrets-common` and
`.kamal/secrets.hosted` — **not** `.kamal/secrets` — so the hosted values go there.

Before every hosted build, run `bin/cloud-lock`: `Gemfile.cloud.lock` is not in git, and
without it the image would keep whatever gem versions the last local resolve picked instead of
the core's `Gemfile.lock` (security bumps included).

Kamal tags the image with the core's git SHA, which doesn't change when only the engine did.
Deploy an engine-only change with a version naming both:
`bin/kamal deploy -d hosted --version "$(git rev-parse --short HEAD)-$(git -C vendor/cloud rev-parse --short HEAD)"`.
