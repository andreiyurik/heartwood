# AGENTS.md — Entry point for AI agents & humans

> Read this first. This file orients any coding agent (or new human contributor)
> working on **Heartwood**. The full design lives in the Obsidian-style vault at
> [`docs/`](docs/index.md) — start at `docs/index.md`.

## What this project is

Heartwood is an **open-source, self-hostable genealogy / family-tree platform** with an
optional **paid hosted plan**. Open core licensed AGPL-3.0; the goal is a *reference-quality*
("эталонное") canonical Rails 8 application. See [[vision]].

## Hard stack constraints (do not violate)

This is a **canonical "vanilla Rails 8" app, on purpose**. Before adding any dependency,
check it against these rules — they are the whole point of the project:

- ✅ **Ruby on Rails 8.1**, Ruby 4.0.x
- ✅ **SQLite** in development *and production* — see [[adr/0002-sqlite-production]]
- ✅ **Hotwire** (Turbo + Stimulus) for all interactivity — no SPA
- ✅ **Vanilla CSS** (modern CSS: nesting, custom properties) — **NO Tailwind / Bootstrap**
- ✅ **Propshaft + importmap** — **NO Node, NO esbuild/Vite, NO bundler step**
- ✅ **Solid Queue / Cache / Cable** — **NO Redis**
- ✅ **Minitest** (omakase) — **NO RSpec**
- ✅ **Kamal** for deploy
- ⚠️ The **only** place raw JavaScript is justified is the family-tree graph layout, wrapped
  in a single Stimulus controller — see [[architecture/tree-rendering]].

If a task seems to need React/Node/Redis/Tailwind, that is a signal to stop and reconsider,
not to add it.

## How to run things in this environment

Ruby is installed via **mise** but its shims are **not** on PATH in non-interactive shells.
Prepend the bin dir in every command:

```bash
export PATH=~/.local/share/mise/installs/ruby/4.0.5/bin:$PATH
bin/rails server      # or: bin/rails test, bin/rails console, etc.
```

## Where to find things

- **Vision & principles** → [[vision]]
- **Domain model** (Person, Family, Event, Source…) → [[domain-model]]
- **Feature catalog** (what we borrow & prioritize) → [[features-index]]
- **Import/export & GEDCOM** → [[gedcom]], [[import-export]]
- **Architecture & decisions (ADRs)** → [[stack]], `docs/architecture/adr/`
- **Business model** (open core, pricing) → [[open-core]], [[pricing-hosting]]
- **Roadmap** → [[roadmap]]
- **Prior art we learn from** → [[prior-art]]

## Conventions for editing the docs vault

- Atomic notes, one concept per file. Link liberally with `[[wikilinks]]`.
- Every note has YAML frontmatter: `title`, `tags`, `status` (`draft`/`stable`).
- The vault is the **single source of truth**: design decisions live here, not in chat.
