---
name: end-of-day-wrap-up
description: >
  Sweeps commitments the user made today (open-items.md, today's meetings,
  Slack messages and emails the user sent) that aren't done yet —
  self-authored only, not items put on the user. Trigger phrases: "end of day
  wrap up", "eod wrap", "what did I promise today".
metadata:
  version: "example"
---

# End-of-day wrap-up

The evening mirror of `daily-priorities`: what did the user commit to today
that hasn't gone out? Terminal punch list, no writes.

## Scope

- **Self-authored only.** "I'll send X", "will get back to you", "let me
  check". Skip what others asked of the user — that's `open-items`'
  `owed-to-me`.
- **Today only** for Slack, email and meetings. **Full backlog** for
  `open-items.md`: every unticked `owed-by-me`, `follow-up` and `action`
  item, regardless of age — that file *is* the persistent commitment log.
- **Bias toward inclusion.** The user reads this in tick-off mode, not triage
  mode. Surface ambiguous commitments with a `?` marker rather than filter
  them out. This is the opposite bias to `open-items`, and deliberately so:
  a morning list is read as "what must I do", an evening list as "did I
  forget anything".
- **Not-yet-done** is best-effort: if there is no cheap way to verify, say
  "may already be done" rather than drop it.

## Sources

| Source | Include | Exclude |
|---|---|---|
| `~/notes/open-items.md` | unticked `owed-by-me`, `follow-up`, `action` | `owed-to-me` |
| Slack `from:<@me> after:<today>` | messages with commitment language | announcements, acks, self-DMs |
| Sent mail today | outbound with commitment language | FYIs, calendar invites |
| Meetings today, if you have a source with next steps | steps attributable to the user | steps naming a colleague |

Commitment cues (not exhaustive): "I'll", "let me", "will send", "will
chase", "get back to you", "sending shortly", "on it", "will circle back".

## Workflow

1. Freshness check on `open-items.md`, as in `daily-priorities`.
2. Parse its unticked items.
3. Resolve the user's own Slack ID once per run (never hardcode it), then
   search `from:<@id> after:<today>`, paginate to exhaustion. Drop self-DMs:
   they are working notes, not commitments. For each candidate, peek at the
   same thread for a later message from the user that delivers the promise
   ("as promised, here's…"); if found, skip.
4. Same for sent mail: a later message from the user in the thread closes it.
5. Meetings, if wired: keep a step only when attributable to the user. Skip
   any already anchored in `open-items.md`.
6. Dedup across sources by person + verb, group by account (tag from
   `open-items.md`, else attendee domains against `## Aliases`, else
   uncategorised).
7. Emit.

## Output format

```
End-of-day wrap-up — YYYY-MM-DD Weekday · HH:MM

<N> open commitments across <M> accounts.

## acme

- [open-items]  Send Jane the collector config (2d, still unticked)
- [Slack]       In #acme-onboarding at 15:22, told Jane "I'll send the team
                URLs shortly" — no follow-up message seen
- [Email]  ?    Re: onboarding kickoff (14:03) — "I'll send the explainer";
                may already be done

<one-line sign-off: how many look genuinely open vs. probably done.>
```

Within an account: `open-items` first, then meetings, Slack, email. Accounts
by descending count. Zero → one plain sentence.

## What this skill does NOT do

Doesn't tick items, send anything, or include commitments from previous days
(that's what the morning sweep captured).
