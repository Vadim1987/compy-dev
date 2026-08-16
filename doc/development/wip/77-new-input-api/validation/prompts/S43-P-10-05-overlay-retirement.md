# P-10-05 — retire "overlay" from the persistent docs (prompt of record)

Commissioned by session43, 2026-08-16. W10 batch 1 of the P10 row (R002).
Worker: Sonnet, model passed explicitly. Deliverable:
`../outcomes/S43-P-10-05-overlay-retirement.md`.

## The rule

The project-facing thing is an **input widget**. "Overlay" is the word the
implementation used for it, and it leaks into documentation where a reader has
no idea the two are the same thing. Replace it.

**Where the console context genuinely needs the word** — because the passage is
about the console's own drawing layer rather than the project-facing widget —
use `input_widget_overlay`, the implementation's own name, rather than a bare
"overlay".

This is **judgment per site, not find-and-replace.** There are ~132 occurrences
in the persistent corpus and some of them will be legitimate: a sentence about
the console's compositing, a quoted identifier, a code sample. Read each, decide,
and be able to say why.

## Scope — the persistent corpus only

`doc/input_api.md`, `doc/development/internals/`, `doc/development/decisions/`,
`doc/development/technical_debt/`, `doc/development/tests.md`,
`doc/development/conventions/`.

**Out of scope, deliberately:**

- `src/` and `tests/` — code comments belong to a later step that owns comment
  work as a whole; touching them here would collide with it.
- `doc/development/wip/` — the feature's own scratch, deleted at the end.

## Two traps

1. **Headings.** If you rename a section heading, every comment and document
   citing that heading by name breaks — and a citation that no longer resolves
   reads as authoritative while being wrong. So: after any heading change, grep
   `src/`, `tests/` and the whole of `doc/` for the old heading text and fix the
   citations **in the same commit**. If a heading's rename would cascade beyond
   a handful of citations, leave it and report it instead.
2. **Identifiers are not prose.** `input_widget_overlay`, field names, function
   names, file names and code samples stay exactly as they are. Only prose
   changes.

## Constraints

- Prose only. **No code, no behaviour, no test edits.** The suite must be
  untouched at **968 / 0 / 0 / 10**.
- Do not "improve" surrounding sentences while you are in them. One decision,
  applied N times — that is what makes it reviewable.
- Do not touch `REMARK:` / `INTERIM:` markers, or add any.
- One commit, `docs(...)`, staging only the files you changed, by path. Never
  `git add .`. **NEVER push.** Leave the owner's untracked scratch alone
  (`claude.sh`, `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`, `repos.txt`,
  `input-pr-slices.tar.gz`).
- Trailer: `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`

## Deliverable

The count changed and the count deliberately left, **with the reason for every
site you left** — that list is the useful half of this report, because it is
what the next reader will otherwise re-litigate. Plus any heading you did not
rename and why, and the commit hash. Do not commit the report.
