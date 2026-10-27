# Agent rituals

How I ran a daily to-do ritual, a per-account notes system, and a couple of
dozen recurring-work skills on top of Claude Code for three months in a
customer-facing engineering role, and what in it is worth stealing.

This repo is the write-up plus the handful of pieces that are genuinely
generic. It is not an installable package. The skills I actually ran were
tied to my employer's tooling (a CLI for the product, a Salesforce-backed
catalog, a call-recording service, browser-token Slack access) and would not
survive extraction. The *design* survives, so that is what is here.

```
bin/        extract-done, extract-open   — the two scripts the ritual turns on
            link-skills, new-skill        — the skills-repo-with-symlinks layout
            scrub-check                   — what I ran before pushing this
hooks/      overwrite-guard.sh            — "always allow new files, confirm overwrites"
examples/   the three ritual skills, reduced to their generic shape
            notes-conventions.md          — the per-account file contract
            AUTHORING.md                  — how the skills were written
            sample/open-items.md          — what the output looks like
tests/      the regression test for extract-open
```

## 1. The problem

Commitments scatter. Someone asks a question in a Slack thread you were
skimming on your phone. You say "let me check" in a channel and then a
customer call starts. The call ends with four next steps, two of which are
yours. An email goes out with "I'll send the explainer tomorrow". By Friday
you have no idea what you owe, and the cost is not the missed item, it is the
background hum of *probably* having missed something.

The usual answer is a to-do app and discipline. I have neither. What I do
have is an assistant that can read every one of those sources, and a text
file I will actually look at because it is in the same Obsidian vault as
everything else I write.

So the job of the assistant is narrow and specific: **find the commitments,
write them to a file, and do not act on any of them.** Everything below
follows from taking that narrowness seriously.

## 2. The three-skill ritual

Three skills, run at three times of day. They are separate on purpose.

**`open-items`** runs at 06:30 from a launchd job, headless. It sweeps the
last 14 days of Slack and the last 7 days of recorded meetings, classifies
each candidate into one of three categories (someone is blocked on me; I
said I'd do something; I asked and nobody answered), tags each with an
account, and writes `~/notes/open-items.md`. It overwrites the file every run,
but ticked items stay ticked and items whose source has aged out of the
window are carried forward until ticked. It is the only skill of the three
that writes anything.

**`daily-priorities`** runs when I sit down. It reads the file, the next three
working days of calendar, and each account's notes, and prints a list ordered
by one rule: the account I am about to be in front of comes first. Read-only.
If the file is more than a day old it says so and refuses to pretend.

**`end-of-day-wrap-up`** runs at the end of the day. It reads the file again,
plus today's sent Slack messages, sent mail and meetings, and lists what I
committed to today that has not gone out. Only self-authored commitments:
what I said I would do, never what someone asked of me. Read-only.

Why three and not one? Because they have different biases and the biases are
the point. The morning sweep must under-report, or it becomes noise and I
stop reading it. The evening sweep must over-report, because I read it in
tick-off mode and a missed line costs more than an extra one. A single skill
with a `--mode` flag would have one bias set wrong half the time. Splitting
them also means the expensive scheduled part (the sweep) is the only part
that has to run unattended, and the two interactive parts can ask questions.

The daily-priorities output deliberately has nothing to do with scheduling,
availability, or whether the day is well-structured. It reports state. The
moment it started advising, I would start arguing with it.

## 3. Design rules that made it work

Each of these exists because its absence produced a specific failure. I have
kept the failures in, because the rule without the failure reads as taste.

**Scripts collect, the model judges.** Every source is read by a shell
script that emits JSON. The model never fetches. It classifies candidates,
writes the task line, and renders the file. Failure this prevents: the model,
given a Slack MCP tool and a vague instruction to "sweep", will search
differently every run, paginate inconsistently, and produce a file that
differs from yesterday's for reasons that have nothing to do with Slack. A
script does the same thing every time and can be tested against a fixture.

**Always re-fetch, and prove it.** The skill has no state check and no
`--only-if-changed` flag. Every run fetches. The terminal summary must print
the fetcher's `collected_at` timestamp verbatim, which the model cannot have
unless it ran the fetcher. Failure this prevents: on three separate occasions
the model reported "no change in source state, skipping" and wrote nothing.
It had not checked the source state. It had inferred, from the file being
recent, that nothing would have changed. The proof-of-fetch line turns that
into something I notice in two seconds.

**The forbidden-shortcuts list.** The top of `open-items/SKILL.md` is a
numbered list of things the model did on previous runs that were wrong:
skipping the fetch, restoring the file from git history, reading the old file
as a source of truth, using the MCP tool instead of the script. Each entry
was added the day it happened. This is the single highest-value section in
any skill I wrote. It costs one line per incident and it is the only form of
"learning from mistakes" the system has.

**Under-report.** If in doubt whether something is an open item, skip it. A
false negative shows up next run once the thread moves. A false positive
teaches me the list is unreliable, and I stop reading it, and the ritual is
dead. The hardest place to hold this line was meeting next-steps: the
recording service extracts every commitment on every call, including the ones
my colleague made on calls I did not attend. The rule became: a step is mine
only if it names me, or names nobody and I was the only person from my side
on the call.

**Anchors are identity.** Every item carries an HTML comment with an opaque
anchor: `<!-- slack:C0123:1729512345.000123 -->`, `<!-- meeting:<id>:<hash> -->`,
`<!-- manual:<slug> -->`. It is invisible in rendered Markdown and trivially
parseable by awk. `extract-done` reads the anchors of ticked items before a
run; the render step marks any item with a matching anchor `[x]`. Without
this, the file could not be regenerated without losing my ticks, and a file I
cannot tick in is not a to-do list. The human-readable line is never used for
matching, because the model rewords it.

**Carry-forward, with one exception.** A fetcher only sees its window. Before
`extract-open` existed, an item vanished the morning its message passed 14
days old, done or not, and "no longer listed" was being read as "done". Now
unticked items are carried forward until ticked, except in the one case where
absence really does mean resolved: a Slack item still inside the window that
today's fetch did not return was replied to. The script decides this per
item (`carry_if_absent`), and the skill is told not to second-guess it.

**The task is the checkbox line.** Obsidian's Tasks plugin shows only the
`- [ ]` line in its queries. For two months my file had the metadata on that
line (`**owed-by-me** · Jane · 2d`) and the actual task on the line below, so
every task was invisible in every query. Now the checkbox line is the
imperative task, dates go on it only when a date was actually agreed, and
everything else sits on an indented sub-bullet where it folds away. The
conventions file for the whole vault says this once; every list-producing
skill points at it.

**Hand-added items need an anchor.** Anything I type into the file by hand
needs `<!-- manual:some-slug -->` or it is gone the next morning. This
sounds hostile. It is the price of the file being regenerable at all, and the
alternative (the model trying to recognise and preserve my lines) was worse.
The skill is told never to invent `manual:` items itself.

**Write the file with the file tool, not `echo`.** One morning the header
read `2027-7-12 06:32` and there was a line containing a literal `n ` where a
`\n` had leaked through a `printf`. The fix is a rule: timestamps come from
one `date` call, pasted verbatim into header and footer, and the file is
written with the editor tool. Dumb rules for dumb failures.

## 4. Notes as a cache with owners

The ritual needs to tag every item with an account. That needs a mapping from
Slack channel names, email domains and meeting titles to accounts. That
mapping lives in a per-account `notes.md`, which is also where everything
else I know about the account lives. The conventions are in
`examples/notes-conventions.md`; the ideas that mattered:

**One file per account, `##` sections, each section with exactly one owning
skill.** Non-owners read and trust. A non-owner that notices a discrepancy
says so and stops; it never silently fixes. This sounds bureaucratic until
you have had two skills quietly rewriting the same section in different
formats.

**Evidence log and current state are different files.** `pulse.md` is
appended weekly with cited observations and never rewritten. `notes.md` is
what is currently true. A separate skill distils one into the other, behind a
watermark (`<!-- distilled through YYYY-MM-DD -->`) that exists for two
reasons: so that an observation deliberately left out is not re-proposed
forever, and so that "which accounts have undistilled weeks" is a question
with an answer.

**The lane that may delete must never write silently.** Three skills update
`notes.md` with cached facts (identifiers, aliases, contact roles); they do it
in place, logging each edit in their summary, and undo is `git checkout`. The
fourth skill produces judgement: it develops the narrative, promotes facts out
of the catch-all section, and trims. Every refresh proposes deletions as well
as additions, because a file that only grows stops being read. That skill
always shows a diff and writes on approval. Cached facts can be mechanically
restored. Judgement cannot, so it gets a human.

**Projects are not tasks.** A project generates action items; it is not one.
The test: could one person finish this in one sitting? If yes, it belongs in
`open-items.md`. No skill writes action items into `notes.md`, because a
to-do list there goes stale silently and competes with the file that is
actually maintained.

## 5. Authoring conventions worth stealing

`examples/AUTHORING.md` has the full list. Four that I would carry to any
skill repo:

**Projection plus local additions.** Some skills are "act as if a human
followed this playbook". Keep the playbook projection in a reference file
with a header saying it is a projection and must be regenerated, not
hand-edited. Keep what you learned running it (which query gets the number,
which threshold is real) in a sibling file that survives regeneration. State
the precedence rule in the skill. Otherwise the first re-projection deletes
three months of earned knowledge.

**A fixed-shape terminal summary ending in a Findings block.** Same layout
across every skill: one line per finding, a bucket tag first that answers
"who does something about this", an impact estimate last, ordered by impact,
capped at eight. A reader of three different skills' output does not re-learn
the layout each time, and a diff between two runs is readable.

**The repo-with-symlinks layout.** Skills live in a git repo, one directory
each, and `link-skills` symlinks them into `~/.claude/skills/`. Shared
scripts live in `bin/` and are symlinked alongside, so `../bin/<script>`
resolves from inside any skill. `new-skill` scaffolds and links in one go.
Nothing clever, and it meant every skill had history from day one.

**The overwrite guard.** A scheduled skill needs a blanket write permission
on the notes tree or it stalls on a prompt at 06:30. A blanket permission
lets it clobber hand-written files silently. The hook in `hooks/` resolves
this: new files pass through, writes to existing files get a confirmation
prompt. Twenty lines.

## 6. What did not transfer, and why

**Source plumbing.** The Slack fetcher, the meeting fetcher and the account
resolver were all specific to one employer's stack and are not here. The
fetcher contract is in `examples/open-items/SKILL.md` step 2; it is two
pre-filtered lists and a timestamp, and writing one against your own Slack
is an afternoon.

**Slack access.** My fetcher used the browser session's tokens, lifted from a
logged-in web client, because no sanctioned app with search-on-my-behalf
scopes was available. It worked. It is also the kind of thing a security
team is right to object to, and the tokens expire with the browser session.
If you can get a real user token, do that first.

**Scheduled runs and permissions.** A headless run stops dead at the first
permission prompt, and permission rules match on command text. Every script
had to be invoked by absolute path; the `cd dir && ../bin/script` form waited
on a prompt nobody was there to answer. I lost seven consecutive mornings to
this before finding it in the logs.

**Everything else I ran.** Twenty-odd skills for health checks, usage
reports, cardinality investigations and so on. They were the bulk of the
work and the bulk of the value, and every one of them was product-specific.
The pattern they shared is in section 5. The skills themselves are not
extractable, and pretending otherwise would have produced a package that
nobody could run.

## Using what is here

```
git clone <this repo> ~/repos/agent-rituals
cp -r examples/open-items ~/.claude/skills/        # then write a fetcher
cp bin/extract-done bin/extract-open ~/.claude/skills/bin/
```

Or more honestly: read `examples/open-items/SKILL.md`, read the
forbidden-shortcuts list, and start your own with a fetcher against whatever
your sources are. The scripts and the format will fit; the rest is yours to
earn.

Before pushing any fork of this publicly: `bin/scrub-check` with a file of
your own account slugs and people's names kept outside the repo.
