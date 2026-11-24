---
title: Feedback to the maker
tags: [feature, growth]
status: stable
---

# Feedback to the maker

The beta is judged by what families say and where they stumble ([[launch-ru]]). Feedback must cost
a person ten seconds and no extra tool: one line in the account menu, one box, a letter to a human.

## Where
- **Account menu → "Write to us"**, on every tree page. It opens `/feedback/new`: one text box, a
  lede that a real person reads it, *Send* and *Cancel*.
- Shown only when the installation names an operator address (`OPERATOR_EMAIL`,
  `config.x.operator`). With none, the menu has no such line and `/feedback` is not found: a
  self-hosted install mails no one it hasn't chosen.

## The letter
`FeedbackMailer.sent` to the operator address, `Reply-To` the writer, so the answer is an ordinary
reply. It carries:
- the text, as written;
- who wrote it (name and email — the operator already holds both as the account's data);
- **the page they wrote from** — the path they came from (`Referer`, same host only, path and
  query, nothing else), so "this button doesn't work" arrives with its button;
- the interface language.

No screenshots, no browser fingerprint, no third-party form or widget, nothing stored in the
database: the letter is the whole record. The promise that data goes nowhere stays true.

## Limits
- Sent at once (`deliver_now`), never queued, and `feedback.body` is filtered from the request log:
  the words exist only in the letter.
- Signed-in members only — relatives on a question's link reach the asker through the answer.
- 2000 characters; five letters an hour per person (`rate_limit`).

## Not yet
- A reply inside the app. Mail is enough until the beta shows otherwise.
