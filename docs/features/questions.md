---
title: Questions for relatives
tags: [feature, collaboration, growth]
status: stable
---

# Questions for relatives

The owner knows there is a box of unsigned prints and a great-grandmother nobody can name. The
person who knows is an aunt who will never open a genealogy app. A **question** is the smallest
thing we can hand her: one sentence, one field, no account. Part of [[collaboration]]; the beta's
metric is how many relatives come and add something ([[launch-ru]]), and this is the cheapest way
in.

## Who does what
- **Asking**: an owner or editor, about one [[person]] — or one photo of that person ([[media]]).
  "Who is in this photo?" is the photo's own default; the rest is free text ("What was
  grandmother Vera's mother called?").
- **Answering**: anyone with the question's link — no account, only an optional "who's answering"
  name — and every member of the tree (viewers too: an answer is a remark, not a change to the
  tree).
- **Turning an answer into the tree**: an owner or editor, in one step from the answer: pick where
  it goes, adjust the words, "Put in the tree". Then the question is closed.
- **Closing without an answer, deleting a question or a spam answer**: an owner or editor.

## How a question reaches a relative
Each question has its **own link** (`/q/<token>`, `has_secure_token`), separate from the invite
link and the view link: it can't give membership, and it opens nothing but this one question.

- After asking, the question page shows the link with **Copy** and, on phones, **Share** (the
  system sheet — family chat, Telegram, WhatsApp, mail). That is the whole delivery mechanism.
- **We don't send the question by email to an address the asker types.** That would make our
  server mail strangers (spam reputation, and an outsider's email collected without their consent
  under 152-ФЗ). The asker's own mail app, through Share, does it better.
- **After answering, the guest is offered a tree of their own** — one quiet line under the thanks
  ("Your side of the family has a story too"), leading to sign-up. Everyone who marries into a
  family brings another one; this is how a tree reaches the next family. Shown only once they
  have answered, never before, and never to someone who already has an account.
- Members see open questions on the person's profile, in one list (`/questions`, in the account
  menu) and in the weekly [[digest]].
- The link carries a preview card (the tree's card with its crest) so it looks trustworthy in a
  messenger.

## What the link shows (privacy)
The page under the link shows: the tree's name and crest, who is asking (a member chose to send it),
the question, and the answer form. Then, by [[privacy-access]]'s rule (`Person.visible_to(nil)`):

- a person who is not living: their name, years and portrait;
- **a living person: nothing about them** — the question's own words are all there is;
- a photo the question is about: shown, whoever is in it — the asker attached this print to this
  question on purpose; the ask form says the photo will be visible to anyone with the link.

Nothing else: no other answers, no tree, no relatives. `X-Robots-Tag: noindex` and
`Referrer-Policy: no-referrer`, as on the view link. A signed-in member who opens the link lands on
the question inside the app.

## Where the answer goes
One form per answer, only for editors: the answer's text (editable — "Anna Petrovna, I think"
becomes "Anna Petrovna") and a choice of field:

| Question about | Fields |
|---|---|
| a photo | caption · when it was taken |
| a person | given names · surname · surname at birth · born · died |

Writing goes through the ordinary model update, so it lands in [[change-history]] under the editor
who accepted it and can be undone there: a name is a `Person` edit, *born*/*died* create or change
the `BIRT`/`DEAT` [[event]], a caption is a `Photo` edit. Facts that fit none of these are for the
editor to type into the biography; a question can also be closed with no field.

## A photo in the answer
The aunt has the great-grandfather's print in her phone. The answer form on the link has
**"Attach a photo"** (one picture; on a phone it opens the camera or the gallery), so she sends it
with a line of text — or with no text at all: a photo alone is an answer.

- JPEG, PNG, WebP or GIF, up to 15 MB, as the album takes. The form says the photo is seen only by
  the tree's members — never on the question's link, which shows no answers.
- The asker's letter says a photo came with the answer.
- On the question, the photo shows in the answer (opens full size). An owner or editor puts it in
  the person's album with one button, **"To <name>'s album"**: a copy becomes an ordinary `Photo`
  of the question's person (in [[change-history]] under that editor), and the answer remembers it
  (`kept_photo`), so the button turns into "In the album". Keeping a photo doesn't close the
  question; the answer's words can still go into a field.
- The answer's own file goes with the answer: deleting the answer, the question, or the person
  (`Person#erase` included) purges it. A kept copy is the album's from then on.

## Model
- `Question`: tree, person, optional photo, `asker` (user), `body`, `token`, `closed_at`,
  `closed_by`. Destroyed with its person or photo; `Person#erase` takes them along.
- `Answer`: question, optional `user`, `author_name` (guests), `body` (optional when a photo is
  attached), `accepted_at`, `has_one_attached :photo`, `kept_photo` (the album copy, nullified if
  that print is deleted).
- Both refresh open pages live (`broadcasts_refreshes_to :tree`). Neither is tree data: not in
  GEDCOM, not in the archive, not in history.
- Guests' answers are rate-limited; body and name are length-capped.

## Telling the asker
When an answer arrives (not the asker's own), `QuestionsMailer.answered` mails the asker — at most
one letter an hour per question, so a family chat answering all at once is one letter. The asker
turns these off with one click in the letter (RFC 8058) or on the account page
(`users.answer_emails`); see `User::Letters`, shared with the [[digest]].

## Not yet
- Several people or a group of photos in one question.
- Several photos in one answer; an answer by voice.
