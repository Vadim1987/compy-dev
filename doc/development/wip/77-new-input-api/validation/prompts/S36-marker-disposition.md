# Commission — marker disposition pass (Sonnet, session36)

**Model:** Sonnet (passed explicitly). **Mode:** mechanical inventory with light classification,
read-only. **Deliverable:**
`doc/development/wip/77-new-input-api/validation/outcomes/S36-marker-disposition.md`.

## What this is for

`REMARK:` / `INTERIM:` markers are review notes left in the tree. The gate before this feature's
PR says they must be **zero**. Nobody knows what they actually contain — the raw count is 27 in
`src/`+`tests/` and 84 in the persistent doc corpus (111), and a crude keyword sample suggests
many are **the same complaint repeated**, which would be one fix rather than many.

**You are not fixing anything and not judging whether a remark is right.** You are producing the
inventory that turns 111 unknowns into a schedule: what each marker asks for, and who owns it.

## Scope — exactly these

- **Code:** every `REMARK:` / `INTERIM:` in `src/` and `tests/` (note `src/examples/keyboard`,
  `src/examples/maze`, `src/examples/balloons` are separate git repos nested in the tree; include
  their markers and say which repo).
- **Docs:** every `REMARK:` in `doc/`, **excluding** `doc/development/wip/` — the wip tree is
  transient and is deleted at release, so its markers do not matter.

## For each marker, one row

| field | meaning |
|---|---|
| `where` | `path:line` |
| `verbatim` | the marker text, trimmed to its ask (quote it; do not paraphrase away its meaning) |
| `kind` | one of: **factual** (claims the text is wrong/stale/no longer true), **vocabulary** (a word to retire or rename, e.g. "overlay" → "input widget"), **archaeology** (complains the text recounts history, interim forms, self-inflicted-then-dissolved states), **prose-size** (too long, compress, rewrite for readability), **question** (asks something that needs an answer, not an edit), **duplicate** (same ask as another marker — name it), **answered** (the tree already satisfies it — say why) |
| `owner` | which plan owns the fix: **SPRINT** (`S27-triage-and-plan.md`, defect removal + adoption — name the step if you can), **PARENT** (`plan.md`, the release: prose sweep, vocabulary, ledger compaction, PR assembly), or **NEITHER** (out of scope for both; say why) |
| `note` | one line, no more |

**The `owner` column is the point of the exercise.** The two plans are deliberately separate: the
sprint removes defects and drives adoption, the parent is the release. A marker that says "this
paragraph is too long" is the parent's prose sweep. A marker that says "this sentence is not true
any more" about input behaviour is the sprint's docs step. When genuinely unsure, write **UNSURE**
and say what the question is — a wrong binding is worse than a flagged one.

## Then, the part that makes the inventory worth having

After the table, three short sections:

1. **Clusters** — groups of markers that are **one move**: every `overlay` → `input widget`
   rename, every "remove the historical archaeology" complaint, every "compress this paragraph".
   Give each cluster a name, a count, and the list of `path:line`s. **This is the headline
   number** — how many distinct moves the 111 markers actually represent.
2. **Already answered** — markers the tree has overtaken. Verify before claiming it: quote the
   code or text that answers them.
3. **Needs an owner decision** — markers that ask a question rather than request an edit, listed
   so they can be answered in one sitting.

## Rules

- **Write the deliverable early and update it as you go.** A previous worker lost a full pass to
  an infrastructure failure with nothing on disk. Write the table incrementally, file by file.
- **Read-only**: change nothing but your own report, no commits, never push.
- Do not skip markers because they look trivial, and do not merge two markers into one row — the
  clusters section is where merging happens, and only there.
- The two large files (`doc/development/internals/user_input.md`, ~33; and
  `doc/development/decisions/input.md`, ~30) hold most of the doc load; do them carefully and
  the rest will go quickly.
- If a marker's `path:line` has drifted (files have moved this week), record where you actually
  found it.
