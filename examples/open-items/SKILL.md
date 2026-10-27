---
name: open-items
description: >
  Sweep Slack (and any meeting source you wire in) for pending action items
  and write them to ~/notes/open-items.md, grouped by account and tagged with
  the people involved. Trigger phrases: "refresh open items", "update open
  items", "what's on my plate today". Reset phrases (overwrite unconditionally,
  losing ticks): "reset open items", "hard refresh open items". Conservative
  by default — under-reports rather than over-reports. Items ticked `[x]`
  persist across runs; unticked items are carried forward after their source
  ages out of the fetch window. Companion skill `daily-priorities` reads the
  file plus the calendar.
metadata:
  version: "example"
  scripts: ../bin/extract-done, ../bin/extract-open, <your fetcher>
---

# Open items

This is the real skill with the employer-specific sources cut out. What is
left is the shape: a deterministic fetcher, an LLM classification step, an
anchor-based render that preserves ticks, and the rules that stop the model
from taking shortcuts. Plug in your own fetcher for step 2; the rest holds.

Sweep Slack for anything the user owes a response on, is waiting on, or
committed to. Write `~/notes/open-items.md`, overwriting each run — but
preserve any item the user has ticked `[x]`, and carry forward any unticked
item whose source has aged out of the window. Same source state plus the same
prior file produces the same file.

**Core principle: conservative.** If in doubt whether something is an open
item, skip it. A skill that under-reports keeps its signal; one that
over-reports becomes just another notification the user ignores. False
negatives are cheap (they show up next run once source state changes); false
positives destroy the ritual.

**Always re-fetch. Never short-circuit.** Every invocation performs the full
sweep, no matter how recent the existing file is. The skill is stateless with
respect to prior runs except for `[x]` anchors and carried items, both read
through scripts. Idempotence is emergent (same source state → same file), not
gated.

**Forbidden shortcuts** — these have all happened in previous runs and are
all wrong:

1. **"No change in source state, skipping."** There is no state check. Every
   run refetches.
2. **"File is recent, skipping the fetch."** File recency is irrelevant.
3. **Restoring the file from git history.** If the file is missing, the user
   deleted it or this is a first run. Regenerate from the fetchers.
4. **Reading the existing file as a source of truth.** Its ONLY roles are
   providing `[x]` anchors via `extract-done` and carry-forward candidates via
   `extract-open`. The structure is defined by this file; the content comes
   from fresh fetches.
5. **Using an MCP tool for the sweep.** Collection goes through the fetcher
   script, always. MCP is for one-off lookups (user ID → name) during shaping.

Keep this list. Every entry is something the model actually did; the list is
the cheapest fix for each.

**Reset invocations**: additionally `rm -f ~/notes/open-items.md` before
step 1, and skip the two extract calls.

**Verification.** The terminal summary MUST include the `collected_at`
timestamp from the fetcher's JSON verbatim. If you don't have one, you didn't
run the fetcher — go back and run it.

## Workflow

Run every script by absolute path (`~/.claude/skills/bin/<script>`), never
`cd … && ../bin/…`. A scheduled run is headless, and permission rules match
on command text: the absolute path is allowed, the `cd` form waits on a
prompt nobody answers.

### 1. Extract done state

```bash
../bin/extract-done > /tmp/open-items-done.json
```

JSON array of anchors from `[x]` items in the current file. Empty if the
file is missing.

### 1b. Extract still-open items

```bash
../bin/extract-open --slack-days 14 > /tmp/open-items-open.json
```

One object per unticked item: `{section, anchor, source, block,
carry_if_absent}`. The fetchers only see their window, so without this an
item vanished the morning it aged out, done or not. `carry_if_absent` encodes
the one case where absence means done: a Slack item still inside the window
that today's fetch didn't return was replied to, so it is `false` and drops.
Everything else is `true`. The script decides; don't second-guess per item.

### 2. Fetch candidates

```bash
<your-fetcher> 14 > /tmp/slack-candidates.json
```

Whatever your fetcher is, it should emit two pre-filtered lists and a
`collected_at`:

```
{
  "user_id": "U<your-user-id>",
  "window_start": "2026-10-05",
  "collected_at": "2026-10-19T06:30:00Z",
  "inbound_unreplied": [ {channel_id, channel_name, author_id, ts, thread_ts?, text, permalink, context: [...]} ],
  "outbound_open":     [ {channel_id, channel_name, ts, thread_ts?, text, permalink, context: [...]} ]
}
```

`inbound_unreplied` = addressed to the user in the window, no reply from the
user since. `outbound_open` = from the user, no reply from either side since.
Bot and alert channels excluded at the fetcher. Each candidate carries up to
six messages of thread context so classification needs no further calls.

### 3. Classify each candidate

Three categories, or skip:

- **`owed-by-me`** — someone is blocked on the user. From `inbound_unreplied`:
  any DM where the last message isn't the user's; any @mention; any thread
  whose latest inbound is question-shaped. Skip where the user reacted ✅ or
  👀. Anchor on the inbound ts.
- **`follow-up`** — the user's last message was a holding reply or a
  commitment ("let me check", "I'll send", "on it"). From `outbound_open`.
  Anchor on the user's own ts.
- **`owed-to-me`** — the user asked and nobody replied, and the question is
  ≥ 24h old. From `outbound_open`. Anchor on the user's ts.

Mixed signals → prefer `owed-by-me`; the newer inbound is sharper. Nothing
fits cleanly → skip.

### 4. (Optional) meeting actions

If you have a meeting source with extracted next steps, add it here with its
own anchor scheme (`meeting:<id>:<4-hex of sha1(text)>`). Keep a step only
when it is attributable to the user: the text names them, or names nobody and
the user is the only person from your side on the call. A step naming a
colleague is theirs. This is where over-reporting creeps in.

### 5. Resolve the account tag

Match `channel_name`, then participant email domains, against the
`## Aliases` section of each `~/notes/<account>/notes.md`. No match →
`uncategorised`. **Do not invent tags.** An honest `uncategorised` tells the
user which account needs an alias.

### 6. Render

Anchors: `slack:<channel_id>:<ts>`, `meeting:<id>:<hash>`, `manual:<slug>`.
In the done set → `[x]`, else `[ ]`. In the done set but gone from the
source → drop (no ghost items). Then merge step 1b: anchor also fetched today
→ today's rendering wins; absent and `carry_if_absent: true` → keep the block
verbatim (recompute the age on Slack items); absent and `false` → drop.

Write with the Write tool, not `echo`/`printf` (an escaped `\n` once leaked
into the file). Header and footer timestamps come from one `date` call.

### 7. Terminal summary

```
Open items refresh — <YYYY-MM-DD HH:MM>

  Fetched at: <collected_at, verbatim>
  N total  ·  K owed by me  ·  F follow-up  ·  J owed to me  ·  M meeting actions
  Accounts touched: <a>, <b> (+ <n> uncategorised)
  Done items preserved: <d>  (or "0 (reset)")
  Carried forward: <c>  ·  dropped as resolved: <r>

  File: ~/notes/open-items.md
```

## Output format

See `examples/sample/open-items.md`. Rules:

- **The checkbox line is the task itself**, imperative, plus `📅 YYYY-MM-DD`
  only when a date was actually agreed. Type, people, age, link and quote go
  on the indented sub-bullet; the anchor comment last. Obsidian Tasks shows
  only the checkbox line, so metadata on it hides the task.
- Sections alphabetical by tag; `uncategorised` last; within a section order
  by type (`owed-by-me` → `follow-up` → `owed-to-me` → `action`) then age.
- Age: `3h` under a day, `2d` under a week, `3w` beyond.
- Hand-added items need a `<!-- manual:<slug> -->` anchor to survive; an item
  with no anchor is dropped next run. Never invent `manual:` items.
- Zero items → header plus `_No open items._`.

## What this skill does NOT do

Doesn't reply, react, or post. Doesn't edit `notes.md`. Doesn't decide what
to do with each item — that's `daily-priorities`.
