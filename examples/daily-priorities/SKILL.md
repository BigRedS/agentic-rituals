---
name: daily-priorities
description: >
  Read-only morning synthesis. Reads ~/notes/open-items.md, the calendar for
  the next few working days, and per-account notes.md files. Emits a
  prioritised terminal punch-list weighted by "who am I about to be in front
  of". Trigger phrases: "daily priorities", "priorities today", "morning
  triage", "what should I focus on today". Terminal output only — never
  writes files. If open-items.md is missing or stale, says so instead of
  proceeding.
metadata:
  version: "example"
---

# Daily priorities

Given the current open items, the next few days of calendar, and what is on
file about each account, what should the user tackle first?

**Core principle: the account you're about to talk to takes priority.** An
item due for a meeting in 90 minutes wins over an older item with no upcoming
touch-point. Age tiebreaks.

**Read-only.** If this skill finds itself wanting to write, that's a bug.

**Forbidden shortcuts** (inherited from `open-items`):

1. Do not skip the calendar fetch because "the user probably knows their
   day".
2. Do not silently use a stale `open-items.md`. If its `Last run:` is more
   than 24h old, say so and ask before proceeding.
3. Do not invent a "same as yesterday" answer. Every run reads all sources.

## Workflow

1. **Freshness.** Parse the `Last run:` line at the bottom of
   `~/notes/open-items.md`. Missing → offer to run `open-items` first and
   stop. Older than 24h → say how stale and offer the same.
2. **Parse items.** Every `- [ ]` line: description (minus any `📅`), due
   date, type / person / age from the sub-bullet, account from the section
   heading, anchor.
3. **Calendar.** Next 3 working days. Drop events under 15 minutes, events
   with only the user attending, and events the user declined — always check
   `responseStatus`; a declined meeting is not the user's meeting. Keep
   `needsAction` but flag it.
4. **Account per meeting.** Title against `## Aliases` in each
   `~/notes/*/notes.md`; then attendee email domains; then attendee names.
   First hit wins; nothing → no tag, don't guess.
5. **Cross-reference.** Items with a matching account tag, plus items whose
   person matches an attendee (catches items tagged to a different account).
6. **Loose ends.** Items attached to no meeting, by type then age, capped at
   10 with a `(+ N more)` line.
7. **Emit.**

## Output format

```
Daily priorities — <YYYY-MM-DD Weekday>

Data freshness:
  open-items.md · Last run: 2026-10-19 06:30
  Calendar · fetched 08:12

## Today (<date>)

10:00–10:30  Acme quarterly review · Jane Doe, Steve Smith  [acme]
  Open items:
    [owed-by-me] Send Jane the collector config (2d)
    [follow-up]  Told Steve I'd send the policy JSON (4d)
  Notes: "SSO migration blocking Q3 launch; Steve escalating."

14:00–14:45  Internal — team sync  [no account]

## Tomorrow (<date>)
...

## Loose ends

- [owed-by-me]  Give Rick my view on the migration plan (1d)   · beta
- [action]      Write up the archive-tier findings (2d)          · uncategorised
```

Days in order, meetings in order, nothing printed for empty days or empty
sub-sections.
