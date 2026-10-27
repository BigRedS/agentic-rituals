# ~/notes — conventions for agents

A generalised copy of the conventions file that every skill in the original
system was written against. It lived at `~/notes/AGENTS.md` (symlinked from
the skills repo) so any agent working in the tree picked it up. Replace
"account" with whatever your unit of work is: customer, project, client,
team.

## Directory layout

- One directory per account. The directory name is the slug every
  account-scoped skill takes as its argument.
- The directory is **never created automatically**. Everything else about an
  account is learned by skills as they go.
- The tree is an Obsidian vault; to-do lists in it use the Tasks plugin
  format (below).

## Per-account files

- `notes.md` — required. Freeform Markdown with named `##` sections; the
  shape is below. Skills may materialise a skeleton on first run, showing the
  draft before writing.
- `activity.md` — chronological log of work done. Skills that produce
  artefacts append a dated entry worded so a future reader learns **what
  actually happened**, not just that something did. Never re-ordered.
- `pulse.md` — weekly evidence log, appended by the weekly sweep. Raw
  observations with citations, never rewritten. `notes.md` is what is
  currently true; `pulse.md` is what was observed and when.
- Reports go in this directory; by default each run overwrites the last.

## `notes.md` shape

Every section is **optional**: an absent section means "not developed yet",
never "known to be empty". Every section is top-level `##` so a consumer can
grep for one without knowing what nests under it. Cache sections sit at the
top, narrative below.

**Each section has exactly one owning skill.** Non-owners read and trust it;
a non-owner that spots a discrepancy surfaces it and stops. It never silently
fixes.

| Section | Owner | Kind |
|---|---|---|
| `## Identifiers` | the monthly verification skill | cache |
| `## Aliases` | weekly sweep, discovery capture (add-only) | cache |
| `## At a glance` | notes maintainer | narrative |
| `## Contacts` | notes maintainer | narrative |
| `## Projects` | notes maintainer | narrative |
| `## Open issues & risks` | notes maintainer | narrative |
| `## Environment` | notes maintainer | narrative |
| `## How to work with them` | notes maintainer | narrative |
| `## Decisions & constraints` | notes maintainer | narrative |
| `## Reference` | notes maintainer | narrative |
| `## Notes` | any, per hygiene rules below | freeform |

**`## Aliases`** — nicknames, short-names, subsidiary names, ticket prefixes,
common misspellings. This is what maps a Slack channel, an email domain or a
meeting title to a directory, so every skill that tags things by account
depends on it.

**`## Projects`** — multi-week workstreams, one `###` each, with a status
from a closed set (`Active` · `Blocked` · `Not started` · `Paused` · `Done` ·
`Dropped` · `Unknown`). `Unknown` is legitimate: it is a question addressed
to a human, and should not survive many refreshes.

**Boundary with `open-items.md`:** a project *generates* action items. The
test is "could one person finish this in one sitting?" If yes, it is an
action item and belongs in `open-items.md`. **No skill writes action items
into `notes.md`.** A to-do list here goes stale silently and competes with the
file that is actually maintained.

**`## Decisions & constraints`** — decisions that bind future work, one dated
line each. Not a meeting log. Lines leave only when falsified.

**`## Notes`** — the catch-all. Facts learned in passing land here; the notes
maintainer promotes them into owned sections as it develops the file.

### Four write lanes

- **Verification** (monthly) re-checks the identifier cache against the
  system of record and prompts before updating.
- **Weekly sweep** updates structured facts it can cite evidence for
  (aliases, contact-role changes), silently and in place, logging every edit
  in its terminal summary. Undo is `git checkout` on the tree.
- **Discovery capture** is add-only on `## Aliases`.
- **Notes maintainer** owns the narrative, distils `pulse.md` into it, and —
  unlike the others — **trims**: every refresh proposes deletions alongside
  additions, because a file that only grows stops being read. It always
  shows a diff and writes on approval; it never writes silently, because it
  is the one lane producing judgement rather than cached fact.

### Distillation watermark

A developed file ends with `<!-- notes: distilled through YYYY-MM-DD -->`.
It exists so that an observation deliberately held back is not re-proposed
on every run forever, and so "which accounts have undistilled weeks" is
computable.

## Hygiene

If, during any task, you learn or verify an account fact not already in its
`notes.md`, add it without being asked — and say so in one line in your
response (`→ added alias "srt" to ~/notes/acme/notes.md`). Never silently
write. If a new fact contradicts an existing note, flag and ask. Don't
capture ephemeral state or individual conversations; link, don't copy.

You will almost never be asked to change an external system. If you think you
are, ask "are you sure?" and do only what was requested.

## To-do lists

Any list of things for the user to do that gets written to this tree should
be queryable by Obsidian Tasks, not prose bullets:

1. Every action is its own `- [ ]` line. A bare `[]` is not a checkbox.
2. **The task is the single line.** Tasks does not read continuation or child
   lines, so dates, tags and priority sit on the task line. Context and links
   go on an indented sub-bullet, where they fold away.
3. Dates use the Tasks emoji signifiers, always `YYYY-MM-DD`: due `📅`,
   scheduled `⏳`, done `✅`. Only attach a date the user actually committed
   to. An invented deadline makes every query lie.
4. Tag rather than invent checkbox states: `#waiting`, `#verify`.
5. Group under `##` headings by the natural axis, usually account. Never
   repeat a task in a summary section.
6. `open-items.md` is generated and rewritten each morning. Anything carved
   out of it belongs in a separate file that won't be overwritten.
