---
title: ADR 0008 — Rich text via Action Text + Lexxy (not Trix)
tags: [adr, frontend, action-text, hotwire]
status: accepted
---

# ADR 0008 — Rich text via Action Text + Lexxy (not Trix)

**Status:** Accepted · **Date:** 2026-06-13

## Context

People need to write **prose** about their relatives — a biography / life story — not just
structured facts. This is the "stories / narratives" pillar in [[features-index]] and grows out
of [[note]]. It calls for a rich-text editor (headings, bold, lists, links, eventually images).

Rails ships **Action Text** (omakase), whose default editor is **Trix**. Before adding anything
we check the [[stack]] vanilla rules: no Node, no build step, importmap + Propshaft only.

We evaluated the editor choice:

- **Trix** (Action Text default) — works, but dated; basic feature set; not what 37signals
  themselves ship anymore.
- **Lexxy** (`gem "lexxy"`) — 37signals' newer editor, built on Meta's Lexical. Real `<p>`
  semantics, Markdown shortcuts, code highlighting, attachment previews. It is the editor used
  in **fizzy** — our reference for Basecamp-grade Hotwire UX ([[fizzy-reference-scope]]).
- A JS-framework editor (TipTap, ProseMirror, etc.) — would drag in Node/a build step. Rejected
  outright by the vanilla rule.

## Decision

Adopt **Action Text with the Lexxy editor** (replacing Trix) for rich prose, starting with
`Person#biography`.

Why it passes the vanilla bar:

- **No Node, no build step.** Lexxy ships its own pre-bundled JS on the asset load path; we pin
  it (`pin "lexxy"`) and `import "lexxy"` through importmap, and include `lexxy.css` via
  Propshaft. Nothing compiles.
- **Not hand-written JS.** It is a vendored library exactly like Trix would be, so it does not
  conflict with the "[the only raw JS we write is the tree graph](../tree-rendering.md)" rule.
- **Standard storage.** Content lives in Action Text's `action_text_rich_texts` table as
  server-rendered, sanitized HTML — portable and Hotwire-friendly. Visibility flows through the
  owning record, so a biography inherits [[privacy-access]] from its [[person]] (tree-scoped).
- **Clean integration on Rails 8.1.** Lexxy detects there is no `ActionText::Editor` adapter yet
  (that lands in Rails 8.2) and falls back to prepending the Action Text helpers, so
  `has_rich_text :biography` and `form.rich_text_area :biography` "just work" and emit
  `<lexxy-editor>` instead of Trix. Pinned `~> 0.9.18`.

## Consequences

- ➕ Basecamp-grade writing experience for biographies — and a reusable base for future prose
  ([[note|notes]], research log, source transcriptions).
- ➕ Zero Node / build step; one small gem; standard Action Text data model.
- ➕ GEDCOM round-trip path stays clean: prose maps to a `NOTE` on export ([[gedcom]]) — the HTML
  is reduced to text/Markdown, not a custom tag.
- ➖ **Beta dependency.** Mitigation: our surface area is tiny (`has_rich_text` + `rich_text_area`),
  and the escape hatch is trivial — drop the gem and Action Text falls back to Trix with no model
  or schema change.
- ➖ Action Text adds one table + a JS/CSS payload. Justified: rich prose is a core product
  pillar, and Trix (the alternative) is also a dependency — the marginal cost is one small gem
  for a markedly better editor.
