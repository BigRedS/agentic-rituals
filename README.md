# Agent rituals

One of the first places I turned to when we started talking about 'agentic workflows' was the sort of repetitive tasks I used to replace with scripts.

Somewhere along the way these became called 'rituals' and they're the sort of thing I do routinely - combing instant messages, mailboxes, call transcripts for action items.

The actual, specific skills I used were quite employer- and employee-specific - Salesforce accounts, Slack user IDs, our internal and public APIs and CLIs etc.

What this repo provides, then, is a generic starting-point and also a reminder for me if/when I want to set this up again.

The assumption here is that the user has a directory of notes that look roughly like an Obsidian vault; a directory of directories with markdown files in them for notes. Mine is at `~/notes`.

## The problem

I don't have a single source of todo items - they may come from a Slack DM, a Slack thread, an email, a Zoom or Teams call.

Worse, these can be pretty easy and obvious ("I will do that") or picked up by some other tool - Granola and Zoom can produce action-items from a call - but an AI agent can read and understand a "let me check" and figure out the deadline for a "I'll do that tomorrow"

The usual answer is a to-do app and discipline - I have tried many todo apps but I've never found a way to get discipline. What I do have is a corporate Claude account and a cron daemon :)

So the aim here is to use the agent to maintain my todo list, and all I have to do is look at it and tick things off.

## The ritual

This is based on three skills, each run at particular times:

**`open-items`** runs automatically at 06:30 in the morning, in the background. It reads the last 14 days of slack and the last 7 days of recorded meetings, classifies
each candidate item into one of three categories (someone is blocked on me; I said I'd do something; I asked and nobody answered), tags each with an
account, and writes `~/notes/open-items.md`. It overwrites the file every run, but ticked items stay ticked and items whose source has aged out of the
window are carried forward until ticked. It is the only skill of the three that writes anything.

I run **`daily-priorities`** when I sit down. It reads the open-items file, the next three
working days of calendar, and each account's notes, and prints a list ordered
by one rule: the account I am about to be in front of comes first. This is read-only and prints to the shell.

**`end-of-day-wrap-up`** runs at the end of the day. It reads the file again,
plus today's sent Slack messages, sent mail and meetings, and lists what I
committed to today that has not gone out. Only self-inflicted commitments:
what I said I would do, never what someone asked of me. Read-only.

These do similar things but with different priorities and biases - the morning-sweep errs on the side of under-reporting to avoid creating noise and overloading my todo list, but the evening one over-reports on a narrower search to make sure I don't miss anything.

Really, they're solving different problems - in the morning I'm building my general todo list, but in the evening it's just "what do I need to do before I go home?"

The daily-priorities output deliberately has nothing to do with scheduling,
availability, or whether the day is well-structured. It reports state. The
moment it started advising, I would start arguing with it.

## The rules

Some of these are just how I think about computers, others are because things went wrong.

**Scripts collect, the model judges.** LLMs exist to understand and read natural language, not to run repeatable deterministic tasks.
I started this because there is a cost to the input and output of any LLM process while curling a massive JSON doc is free,
but the bigger value is that asking claude to "check slack" is inconsistent whereas a script will be written to always check the same channels
and always retrieve every message from the given time window.

**Always re-fetch, and prove it.** Agents are very good at finding shortcuts and will sometimes just repeat the cached data to save time, assuming nothing will have changed since the last run.
To get around this, each data-fetching script prints a timestamp on completion, and each skill that uses this is required to print that timestamp itself; it can only have that timestamp if it has run the script.

**Keep a forbidden-shortcuts list.** Claude is even lazier than I am; every time it found a shortcut that was wrong but specific to the skill,
I added it to the top of the relevant skill. As default models change, the amount of initiative Claude will use, and the effort it will go to
chasing a supposed efficiency gain, varies unpredictably. In general, newer, more capable and more-independent models are better here, but they do need reining in.

**Under-report**, selectively. If in doubt as to whether something is an open item, skip it. A false negative shows up on the next run once someone chases in a thread or a call.
False positives would lead to my not-trusting the list and so not depend on it, which would defeat the point.
The trickiest thing here is call transcripts - Granola was excellent at attributing calls to the right person, Gong's _quite_ good, Zoom's pretty bad and OpenWhisper is useless because I don't update the speakers in-call.
The rule became: a step is mine only if it names me, or names nobody and I was the only person from my side on the call.

**Invent standard identities.**
I've a standard identity of the form `[source]:[source's id]`, so a slack message looks like `slack:C0123:1729512345.000123` for example.
This gives a unique reference for a given task, meaning consecutive runs can maintain its state.
These are inserted everywhere in comments so they're not rendered in markdown readers.
The downside is that hand-added things need a `manual:<something of my choosing>` else they drop out of this handling and disappear.
Generally, I try to avoid gaining todo items without a call transcript, a slack thread or similar so this isn't a major problem for me.

**Evidence-log and current state are different files.**
`pulse.md` is appended-to weekly with cited observations and is never rewritten.
`notes.md` is what is currently true and is continually overwritten.
A separate skill distils one into the other, behind a watermark (`<!-- notes: distilled through YYYY-MM-DD -->`) so that an observation deliberately left out stays left-out, and also
so that we have a record of which accounts have and have not been distilled on a given week.


**Projects are not tasks.** A project generates action items but is not itself a task. Projects tend to get directories (which get deleted when they're over, but remain in git history).
The easy test is whether I could look at a thing as an entry on a todo list, do it, then tick it off, without getting up from my desk. If not, it's a project and needs splitting into tasks.

**Versioning and history is Something Else's Problem**
All these skills produce are text files, so the easiest way to back it up is a cronned git commit/push; this gets point-in-time restores as well, so is a good way to go through the history of a note.
The notes directory is intentionally Obsidian-shaped, which lends itself to Obsidian's own sync, again getting point-in-time restores and history retrieval.

These skills assume that _something else_ is dealing with answering the question of what a given file looked like at some point in the past, and don't attempt to help with that task;
cronning git or setting up the obsidian sync are left as an exercise for the reader.

## Conventions

`examples/AUTHORING.md` has the full list. Four that I would carry to any
skill repo:

**Automation plus local additions.** Some skills are "act as if a human followed this playbook", and mostly they began by asking Claude to write a skill based off a doc.
Here, we keep the playbook projection in a reference file with a header saying it is a projection and must be regenerated, not hand-edited; the skill can then still refer to the doc, and the doc can trivially be replaced with a new one.
Keep what was learned running it (which query gets that number, which threshold is real) in a separate file that survives regeneration.
State the precedence rule in the skill, too - agents will need to be told that the what-was-learned file trumps the official doc.

**Define a terminal output shape**
Lots of these skills produce ephemeral updates to the shell, rather than writing files.
It turns out I have opinions on what these look like (who knew!) and like files it's worth defining this in-general and in-specific

For instance, my preference generally is one line per finding, beginning with the name of whoever owns it, ending with an impact estimate, ordered by that impact estimate.
I don't like long lists of things to do, so this is limited to 8.
A reader of three different skills' output does not re-learn the layout each time, and a diff between two runs is readable.

**The repo-with-symlinks layout.** Skills live in a git repo, one directory each, and `link-skills` symlinks them into `~/.claude/skills/`. Shared
scripts live in `bin/` and are symlinked alongside, so `../bin/<script>` resolves from inside any skill. `new-skill` scaffolds and links in one go.
I wish there were a better way to do this, but there doesn't seem to be.

**The overwrite guard.** A scheduled skill needs a blanket write permission on the notes dir hierarchy or it stalls on a prompt at 06:30. A blanket permission
lets it clobber hand-written files silently.
The hook in `hooks/` resolves this: new files pass through, writes to existing files get a confirmation prompt.

## What didn't transfer

**Sources plumbing.** The Slack fetcher, the meeting fetcher and the account resolver were all specific to one employer's stack and are not here. The
fetcher contract is in `examples/open-items/SKILL.md` step 2; it is two pre-filtered lists and a timestamp, and writing one against your own Sources
is probably several minutes in your own Claude.

**Scheduled runs and permissions.** A headless run stops at the first permission prompt, and permission rules match on command text so every script
has to be invoked by its full path. Doing `cd dir && ../bin/script` causes it to wait on a prompt since you can't add `../bin/script` to the permissions.

**Everything else I ran.** Twenty-odd skills for health checks, usage reports, cardinality investigations and so on. They were the bulk of the
work and the bulk of the value, and every one of them was product-specific.
These are all built with the same rules, and broadly the same process - a plan-mode session with a highly capable model to make the first version, a bunch of hacking about, and then another plan-mode to tidy.

## Using what is here

```
git clone <this repo> ~/repos/agent-rituals
cp -r examples/open-items ~/.claude/skills/        # then write a fetcher
cp bin/extract-done bin/extract-open ~/.claude/skills/bin/
```

Or more honestly: read `examples/open-items/SKILL.md`, read the forbidden-shortcuts list, and start your own with a fetcher against whatever your sources are. The scripts and the format will fit.

Before pushing any fork of this publicly: `bin/scrub-check` with a file of your own account slugs and people's names; it's how I stripped this before publication.


```
bin/        extract-done, extract-open    — the two scripts the ritual turns on
            link-skills, new-skill        — the skills-repo-with-symlinks layout
            scrub-check                   — what I ran before pushing this
hooks/      overwrite-guard.sh            — "always allow new files, confirm overwrites"
examples/   the three ritual skills, reduced to their generic shape
            notes-conventions.md          — the per-account file contract
            AUTHORING.md                  — how the skills were written
            sample/open-items.md          — what the output looks like
tests/      the regression test for extract-open
```
