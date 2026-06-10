# Heartwood

> The living core of your family tree — open, yours, and built to last generations.

Heartwood is an open-source platform for building and preserving family trees. Run it
on your own server for free, forever — or let us host it for you for a small fee if you'd
rather just fill in your family's story and not think about servers.

The name is the dense, enduring core of a tree's trunk. That's the idea: an open **core**
you truly own, that outlives any single company or subscription.

## Philosophy

- **Own your roots.** Your family's history is too important to rent. The core is
  AGPL-licensed and self-hostable in minutes.
- **Boringly solid.** A canonical Rails 8 app — SQLite, Hotwire, vanilla CSS, no Node,
  no build step, no Redis. Easy to deploy, easy to understand, easy to keep alive.
- **For real people.** Intuitive enough for a grandparent to add a cousin, powerful
  enough for a serious genealogist (GEDCOM import/export, sources, media).

## Open core, fair hosting

- **Self-host** the full core for free under the AGPL-3.0.
- **Hosted plan** (optional): pay monthly or once, and use our server — same app, zero ops.

## Tech stack

The "vanilla Rails" stack, on purpose:

- **Ruby on Rails 8.1** — the framework
- **SQLite** — the database (yes, in production)
- **Hotwire** (Turbo + Stimulus) — interactivity without a SPA
- **Propshaft + importmap** — assets with no Node, no bundler
- **Vanilla CSS** — modern CSS, no framework
- **Solid Queue / Cache / Cable** — jobs, cache, websockets on the database
- **Kamal** — deploy anywhere with one command

## Self-hosting

```bash
git clone https://github.com/YOUR_ORG/heartwood.git
cd heartwood
bin/setup
bin/rails server
```

Open http://localhost:3000 and start your tree. Production deploy is one `kamal deploy`
away — see `config/deploy.yml`.

## License

The Heartwood core is licensed under the **GNU Affero General Public License v3.0**
(AGPL-3.0). See [LICENSE](LICENSE). In short: it's free to use, modify, and self-host —
and if you run a modified version as a network service, you share your changes back.
