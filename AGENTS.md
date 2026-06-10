# AGENTS.md — Entry point for AI agents & humans

> Read this first. This file orients any coding agent (or new human contributor)
> working on **Heartwood**. The full design lives in the Obsidian-style vault at
> [`docs/`](docs/index.md) — start at `docs/index.md`.

## ⛔ Workflow — non-negotiable (read this before writing ANY code)

Every coding task on Heartwood follows this order. No exceptions, no shortcuts — even for a
"trivial" change. **We build strictly test-first (TDD).**

1. **READ THE DOCS FIRST.** Start at [`docs/index.md`](docs/index.md). Find the notes relevant
   to the task (domain entity, feature, ADR) and read them. The vault is the source of truth;
   the code must match the design recorded there. If the docs are silent or wrong, update the
   docs *first*, then proceed.
2. **WRITE THE TEST NEXT (Minitest).** Write a failing Minitest test that expresses the desired
   behavior — model/unit, integration, or system test as appropriate. Run it and **watch it
   fail** (red). No production code is written before a failing test exists for it.
3. **THEN WRITE THE CODE.** Write the minimum code to make the test pass (green). Run the test
   and watch it pass.
4. **REFACTOR.** Clean up with tests staying green. Then run the full suite (`bin/rails test`)
   before considering the task done.

Red → Green → Refactor. If you catch yourself writing production code without a failing test
in front of it, stop and go back to step 2. Minitest only — **no RSpec** (see constraints below).

```bash
export PATH=~/.local/share/mise/installs/ruby/4.0.5/bin:$PATH
bin/rails test                         # full suite
bin/rails test test/models/person_test.rb   # one file
bin/rails test test/models/person_test.rb:42 # one test by line
```

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
