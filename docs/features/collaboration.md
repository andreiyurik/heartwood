---
title: Collaboration
tags: [feature, realtime]
status: in-progress
---

# Collaboration

Families build trees together. Part of [[features-index]] (Should). Borrowed from webtrees'
collaborative model (see [[prior-art]]), the invite-link mechanic from once-campfire's
`join_code` (adapted per-tree — see [[prior-art]] — since Heartwood, unlike campfire, has many
trees rather than one account per install).

## Shipped
- **Invite links**: each tree has a `join_code` (`Tree#reset_join_code!` to revoke and reissue).
  `GET/POST /join/:join_code` — a guest sees the tree's name and a sign-up form; one request
  creates the user and an editor `TreeMembership` (`User.sign_up!(join:)`). "Already have an
  account?" signs in and returns to the confirm page. Self sign-up (`/registration`) names the
  tree and creates user, tree and owner membership together; the owner renames it in `/settings`.
- **Roles**: owner (created the tree, sole admin) / editor (full read-write) / viewer
  (read-only), on `TreeMembership#role`. Enforced at the controller level
  (`TreeAuthorization#require_can_edit`/`#require_owner`) on every mutating action across
  People/Events/Citations/Relatives/Hints, not just hidden in views.
- **Member management**: `/tree_memberships` — owner-only role toggle and removal, visible
  member list for everyone in the tree.
- **Multi-tree membership**: a user can belong to more than one tree (their own plus any they've
  joined). `sessions.current_tree_id` remembers which one is active; a nav `<details>` switcher
  appears once someone actually has more than one.

## Deferred
- **Live updates**: when Aunt Maria adds a cousin, everyone viewing should see it appear via
  Turbo Streams over Solid Cable. Not yet wired for tree data (hints already use this pattern —
  see `turbo_stream_from Current.tree, :hints` in the layout — the same approach extends to
  people/events once needed).
- **Per-record visibility** tied into [[privacy-access]] (public / members-only / private on
  individual people/events) — today a viewer sees everything the tree contains, just can't edit
  it. Coarser than the eventual model, intentionally simple for v1.
- **Read-only share links** ([[privacy-access]] "Share links") — a *different* mechanism from
  the `join_code` invite links above: no account, no `TreeMembership` row, just a token that
  opens one person/branch as a view. `join_code` always grants an editing membership today;
  it should not be repurposed for "just let them look." Worth its own token/model rather than
  overloading `Tree#join_code`.
- Change history / "who edited what" audit trail.

## Notes
- Started simple per the original plan: roles + invite links first, live updates and granular
  per-record privacy are the natural next layers, not blocking v1 collaboration.
