---
title: Guides — where to look for your ancestors
tags: [feature, growth, seo, evidence]
status: draft
---

# Guides — where to look for your ancestors

Public pages that answer the questions people actually type into Yandex and Google: «как найти
участника войны», «метрические книги где искать», «как написать запрос в архив». Each guide
says which records exist, who holds them and how to get them, links to the sites, and ends
with what the app is for: *keep what you found in one place, with the source, and let the
family add what they remember*. Part of the launch plan ([[launch-ru]]); the in-app twin is
"Where to look" on the [[person-profile]].

Based on the methodology and source catalog of
[ex-ussr-kinship-research](https://github.com/DenisSergeevitch/ex-ussr-kinship-research)
(MIT, © Denis Shiryaev) — rewritten for people, not for an AI agent, credited on every guide
and in `NOTICE.md`.

## Why guides and not a page of links
A list of links is thin content; search engines rank answers. One guide per question, each
with the same shape: *what records exist → where they are → how to get them → the sites →
"found something? keep it in the tree"*. Copy stays honest ([[landing]] rules): we never claim
a site has a record, only what kind of records it holds.

## The guides
| Slug | Question it answers |
|---|---|
| `military` | Великая Отечественная и Первая мировая: «Память народа», ОБД «Мемориал», «Подвиг народа», GWAR, Arolsen |
| `metric-books` | Метрические книги до 1918 года: в каком архиве, как найти приход, где сканы |
| `repressions` | Репрессированные и раскулаченные: «Открытый список», базы «Мемориала», «Возвращённые имена» |
| `archive-request` | Запрос в архив или ЗАГС: куда писать, что указать, готовый текст письма |
| `ai-research` | Исследование с ИИ-агентом: what the skill is, and the round trip back into the tree |

`/guides` is the index. Guides are Rails views (`app/views/guides/<slug>.<locale>.html.erb`,
like the legal pages) — no CMS, no database: they change with the code and are reviewed with it.

## The site catalog — one list, two places
`config/research_sites.yml` holds every site we point to: key, URL, tier, the years its records
cover, which guide lists it, and when the link was checked. Names and descriptions are I18n
(`research_sites.<key>.*`). `ResearchSite` reads it. The same catalog drives:
- the guides' site rows;
- "Where to look" on a person's profile ([[person-profile]]): sites whose years overlap the
  person's life, for people who are not living.

Tiers, from the skill's source classes: **official** (an archive or state database — the record
itself), **project** (a reputable index or memorial project — find the original it points to),
**community** (forums and trees — a lead, never proof). The tier is one muted word on the row.
Before adding a site: it must be reachable, say what it holds, and have a known owner. Many
Russian state sites refuse connections from abroad — check those from a Russian connection.

## URLs, languages and search engines
- Locale is in the path: `/ru/guides/<slug>` and `/en/guides/<slug>`. A crawler sends no cookie
  and often no `Accept-Language`, so a cookie-based locale would index one language only. The
  path locale wins over the cookie for that request; `/guides` redirects to the visitor's
  language. The language switcher on a guide goes to the other language's URL.
- Each guide has its own `<title>`, `meta description`, `canonical`, `hreflang` alternates
  (ru, en, x-default → ru), OpenGraph tags and JSON-LD (`Article` + `BreadcrumbList`).
- `sitemap.xml` lists the landing page and every guide in both languages.
- **Indexing is the hosted service's call.** `GUIDES_INDEX=on` (set by the hosted deploy)
  makes the guides indexable and the sitemap non-empty. Without it every install still serves
  the guides to its family, but with `noindex` — a hundred self-hosted copies of the same text
  would compete with each other and with us in search.
- No analytics on guides (analytics stays on the landing only, [[launch-ru]]).

## What guides never do
- No public pages of people or trees for search traffic. Trees stay private
  ([[privacy-access]], 152-ФЗ); only the guides are public.
- No scraping or automated search of other sites. "Where to look" links out; the person
  searches themselves.

## Not yet
- Guides per region (губерния) — after the first five prove they bring visitors.
- A request letter filled in from a person's profile (the template is in `archive-request`).
