# Authoring skills

Guidance for writing and editing `SKILL.md` and its reference files, written
against real edits to the original skills. The domain-terminology section has
been removed; everything else is as it was.

The broad principle: **terse and precise beats verbose and organised**. Same
direction for both human readers and LLM agents.

## Voice

- Short sentences. Bullets over paragraphs. Concrete over abstract.
- Positive framing beats negative. "Only call read subcommands" > "Never call
  risky subcommands". Negative rules focus attention on the forbidden
  behaviour.
- Keep the **why** when it isn't obvious. A one-line reason generalises to
  edge cases the rule doesn't cover.
- One behaviour per bullet.
- Watch ambiguous pronouns in compressed prose. In a terse bullet, "this"
  often loses its antecedent. Spell out the referent.

## Bullets vs headers

- **Headers** when any item exceeds ~4 lines, items contain their own
  sub-structure, you want it grep-navigable, or there are more than ~7.
- **Bold-bullets** for short parallel enumeration where every item is 1–3
  lines and the reader reads top to bottom.
- LLM-authored drafts over-favour indented bullets with bold openers. When
  editing one, look for items whose body is 5+ lines with sub-structure;
  those usually want to be headers.

## Punctuation and markup

- No `§`. Say `"Section name"` or point at the file and section by name.
- Markdown headers cannot wrap across lines.
- Bullet continuation lines indent to align with the text after `- `.
- Emoji only when specifically asked (the Tasks signifiers are an exception
  with a reason).

## Frontmatter

- `name`: kebab-case, matches the directory.
- `description`: front-load the primary use case in the first ~50 characters;
  third person; include the trigger phrases you'd naturally say.
- `metadata.version`: bump on structural changes.
- `metadata.scripts`: the shared `bin/` scripts the skill relies on, spelled
  `../bin/<name>` relative to the skill directory. Skills are consumed through
  a symlink at `~/.claude/skills/<name>`, and `bin/` is symlinked alongside,
  so the relative path resolves there and only there.
- `metadata.last_reviewed`: date of the last hand-review.

## Length

- `SKILL.md` body ≤ ~300 lines. Beyond that, move content to `references/`.
- Reference files: no cap. Loaded on demand.

## Scripts collect, the model judges

Every skill that touches a data source does so through a shell script that
emits JSON. The model never fetches; it classifies, writes prose, renders.
Reasons, each learned the hard way:

- A script can be tested in `tests/` with a fixture. A prompt cannot.
- "Did it actually fetch?" becomes checkable: every terminal summary prints
  the fetcher's `collected_at` verbatim.
- The model, given the option, invents shortcuts ("no change in source,
  skipping"). Removing the option is cheaper than forbidding it — but forbid
  it too, in a **Forbidden shortcuts** list at the top of the skill, one entry
  per thing the model actually did.

## Earned CLI knowledge

If you've had to recover the same piece of CLI knowledge more than once, it
belongs in a "Conventions and gotchas" section of the skill, with a
provenance tag saying what it was calibrated against, rather than as inline
`NOTE:` comments.

## Playbook-derived skills

Some skills are "act as if a human followed this playbook, plus add value at
the beginning and end". Keep the playbook projection in `references/` with a
header that makes its provenance explicit:

    > **Projection of [source doc]**. Regenerate when the source changes:
    > ask the model to re-read the source and update this file, preserving
    > this header. Do not hand-edit for stylistic tightening.

Pair it with a sibling `references/local-additions.md`: *what* to check is
the projection, overwritten on regeneration; *how* to get the numbers here is
ours, and survives. Mirror the headings so a reader can interleave them, and
state the precedence rule in `SKILL.md` (mechanics: local wins; what counts
as a finding: playbook wins).

## Terminal summary

Skills that produce a report define a `## Terminal summary` section with a
prescriptive, fenced template. Keep the shape stable run-to-run so repeats
are visually diffable: the one-line "what ran" header, the key per-run
numbers, the report path, and anything that would otherwise get lost.

### The Findings block

Any skill whose run produces things the user might act on ends with:

```
 Findings:
   [Q] <one-line finding>                                    (~<impact>)
   [D] <one-line finding>                                    (~<impact>)
```

One line per finding, ≤100 characters. Bucket tag first, from a legend the
skill defines ("who does something about this", not "how bad"). Impact
parenthetical last, prefixed `~`, omitted rather than `(n/a)`. Ordered by
impact across the whole block. Capped at ~8 lines with `+ N more in the
report`. A run with nothing to act on emits `Findings: none`.

## Cross-referencing

Relative paths to sibling files; section by name, no `§`. Repeated content
goes in a reference file, not pasted twice.
