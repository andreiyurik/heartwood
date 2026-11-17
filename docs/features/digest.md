---
title: Weekly "what's new in the tree" email
tags: [feature, collaboration, email, growth]
status: stable
---

# Weekly digest

Most relatives open the tree once, add their branch and forget it. One short letter a week —
only when something happened — brings them back to what the others added. Part of
[[collaboration]].

## Rules
- **Once a week** (Monday morning), to every member of every tree, one letter per tree.
- **Only if something changed** in that tree during the past week by *someone else*: a letter
  about your own edits is noise. No changes → no letter.
- Contents, short and in this order:
  1. people added — names with links (at most ten, then "and N more");
  2. other changes — counted ("12 changes by Masha and Andrey");
  3. photos added, comments written;
  4. open [[questions]] with links ("Who is in this photo?" — answer it).
- Every link goes to the app; nothing personal beyond what the member already sees in the tree.
  **Living people are named in the letter** — the recipient is a member and sees them anyway.
- **One-click unsubscribe**: a signed link in the footer (and the `List-Unsubscribe` and
  `List-Unsubscribe-Post` headers, RFC 8058) turns the digest off for that account without
  signing in. The account page has the same switch to turn it back on.
- No advertising, no "say thanks" link: it is a service letter, not a mailing (38-ФЗ ст. 18 would
  otherwise require a separate consent).

## How
- `config/recurring.yml`: `weekly_digest` runs `WeeklyDigest.deliver_all` every Monday at 9am
  (server time). It enqueues `DigestMailer.weekly(membership)` for each membership with news,
  through Solid Queue. The window is the last seven days, so no "last sent" column is needed.
- `WeeklyDigest` (a plain model over a membership and a window; `Digest` is Ruby's own) collects
  the news from `Edit` (people, changes, photos added — photo additions are history now),
  `Comment` and `Answer`, leaving out the recipient's own. Open questions are listed but alone
  are not news.
- `users.weekly_digest` (boolean, default true). `User::Letters` keeps one switch per kind of letter
  (`digest`, `answers`) and a `generates_token_for` token per kind; `/letters/:kind/unsubscribe/:token`
  shows one button on GET and unsubscribes on POST, so a mail scanner's prefetch changes nothing.
- The letter is in the member's language: `users.locale`, set at sign-up and whenever they switch
  the language, falling back to the default.

## Legal check (152-ФЗ)
The consent ([[accounts-and-legal]]) lists "sending service letters" as a purpose; the privacy
policy's purposes now name the weekly summary and how to switch it off (`Legal::VERSION`
2026-11-17). It uses data the member already sees in the tree, goes only to members, and carries
no advertising, so 38-ФЗ's consent for advertising mailings doesn't apply.
