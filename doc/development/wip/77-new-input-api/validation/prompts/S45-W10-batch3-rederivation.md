# S45 worker prompt of record — re-derive W10 batch 3 (comment bloat)

Model: **Sonnet**, explicit. Read-only over the repo except the one deliverable
file. Spawned 2026-08-25 by session45 (parent: Opus).

---

You are working in the LÖVE2D project at `/repo` (cwd). This is a documentation
/ inventory task: **no code changes, no test runs, no git — ever**. Do not run
`git commit`, `git stash`, `git checkout`, `git add`, or any other `git`
subcommand that writes; `git log`/`git show` reads are allowed if you need
history, nothing else. The parent has uncommitted work in this tree.

**Tooling note:** a `lua-lsp` MCP server (defs / refs / diagnostics over a real
AST of `/repo`) is available. You will mostly be reading Markdown, but if you
need to confirm that a Lua symbol or file still exists, prefer the LSP over
guessing; `grep` is the right opening move for "does this string still appear".

## Background you need

Feature #77 is in its pre-PR validation phase. An owner code review left 187
remarks, extracted mechanically into
`doc/development/wip/77-new-input-api/validation/outcomes/S27-remark-inventory.md`.
Each entry has this shape:

```
#### R062 — `tests/input/input_events_spec.lua:241` *(unmarked)*
> the remark text, verbatim
**Context:** ```lua … ```
**Asks for:** a one-line paraphrase
**Provisional kind:** mechanical | question | …
```

Those remarks were triaged into workstreams in
`doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md`.
Workstream **W10 (editorial)** holds 92 ids and was split into four batches
(see the section `### W10 — Editorial`):

1. retire the word "overlay" — **done**
2. no historical contrast — **still open, owned by a later step**
3. **comment bloat (~50 remarks)** — *"never separately enumerated inside
   W10's block of 92 and must be re-derived first"*. **This is your task.**
4. vocabulary ("test cases" not "rows", etc.) — **done**

The W10 id list is in the same file under the appendix line beginning
`W10 every id not listed above (92):`. Use that list verbatim as your universe.
Do not add ids from other workstreams.

## Your task

For **every id in the W10 list**, decide whether it belongs to **batch 3
(comment bloat)** and report what is left of it in the tree today.

**Batch 3 means the remark asks for a comment to be shorter** — "too verbose",
"overbloated", "this can be one line", "no need to explain X at such length",
"why is this comment here at all". Judge from the remark's own words plus the
**Asks for:** line.

**Not batch 3:** a remark asking for a *factual* correction, a rename or
vocabulary change, a question to the owner, a request for new content, or a
complaint about the *code* rather than about a comment. If a remark asks for
both a correction and a trim, mark it batch 3 **and** say what else it asks.

Then, for each id you classify as batch 3, establish its **current state**:

- **Does the marker still exist?** Search the tree for the remark's text (or a
  distinctive fragment of it). The gate today is
  `grep -rniE 'INTERIM|REMARK' src/ tests/ --exclude-dir=lib --exclude=words_corpus.lua`,
  which returns 23 hits — so most of these markers are already gone. A missing
  marker usually means a later session answered it.
- **Does the site still exist?** The inventory's `file:line` is as of
  `c6a0778f` and the tree has moved a great deal. Report the file's current
  path if it moved, and say plainly when the file or the commented code is gone.
- **Line numbers must be current**, not the inventory's. If you cite a line,
  you have opened the file.

## Deliverable — one file, written by you

`doc/development/wip/77-new-input-api/validation/outcomes/S45-W10-batch3-rederivation.md`

Structure it as:

1. **Headline numbers** — how many of the 92 are batch 3; of those, how many
   still have a live marker, how many have a live site but no marker, how many
   are gone entirely.
2. **The live table** — one row per batch-3 id that still has work attached:
   `id | current file:line | what the remark asks | marker still present? | note`.
   Ordered by file, so the eventual sweep can go file by file.
3. **The discharged list** — batch-3 ids whose marker and site are both gone,
   one line each with the evidence that it is gone (file deleted / text absent /
   comment rewritten).
4. **Disputed or ambiguous** — ids you could not classify confidently, with the
   remark quoted and both readings stated. Do not guess silently; this list is
   expected to be non-empty and it is more useful than a false-confident call.

**Report facts, not plans.** Do not propose rewrites, do not edit any comment,
and do not judge whether a comment *should* be cut — that judgement is the
parent's. Your deliverable is the enumeration that has never existed.

When you are done, reply with the headline numbers and the path you wrote.
