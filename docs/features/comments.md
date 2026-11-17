---
title: Comments on a person
tags: [feature, collaboration]
status: stable
---

# Comments on a person

Basecamp puts a thread under every record; a family tree needs one under every person, because
the most common thing a relative wants to say is "I think that date is wrong" or "she was born in
Tver, not Kalinin". Part of [[collaboration]]; the next bar in [[design-system]] §6.

## What users see
- The last section of a profile, **Discussion**: rows of comments, oldest first, each one avatar ·
  bold name · the words · one muted line with the time (counted in the browser, see
  [[design-system]]). Below them one field, "Add a comment…", and a small "Post" button.
- Every member can comment, viewers too: a comment doesn't change the tree.
- The author can edit or delete their comment in place; the owner can delete any.
- New comments appear on every open profile through the same live refresh as the rest of the tree
  (`broadcasts_refreshes_to :tree`); an open comment form is left alone.
- The [[digest]] counts comments under "what's new".
- View-only links and question links never show comments.

## Model
`Comment`: tree, person, user (nullified when the account is deleted — the row then says "a
deleted account", like [[change-history]]), `body` (plain text, 5 000 characters). Destroyed
with the person; `Person#erase` deletes them. Not tree data: not in GEDCOM or the archive, not in
history.

## Legal note
Messages between users are what makes a service an "organiser of information dissemination"
(ОРИ, ст. 10.1 149-ФЗ) — see [[legal-ru]] §9. Comments and answers to [[questions]] are exactly
that, so the question goes to the lawyer before the hosted launch.
