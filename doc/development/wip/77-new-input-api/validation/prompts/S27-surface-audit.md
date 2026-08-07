# S27 sub-agent prompt of record — what does each frozen surface actually freeze?

**Model:** Sonnet. **Spawned:** 2026-08-07, session27. **Nature:** verification by
experiment. Read-only with respect to committed files. Judgment (what to remove)
stays with the parent.

---

You are working in the LÖVE2D project **compy**, repo root `/repo` (your cwd).

**Do not edit any file under `src/`, `tests/`, `doc/` or `agents/`. Do not
commit. Do not push.** You may create scratch files under
`/tmp/claude-1000/-repo/scratch-audit/` and you may temporarily modify a file
**only** if you restore it immediately with `git checkout --` and verify with
`git status` that the tree is clean before you finish. Your one lasting write is
the deliverable named at the end.

## Background

`src/controller/consoleController.lua` builds the project-facing `compy.input`
surface out of several `setmetatable` wrappers. The project owner has reviewed
the file and asked, of several of them, whether they earn their place — his
words, verbatim:

- `:415` — "setting `__index` is redundant, because its trivial?"
- `:427` — "whole function is redundant because its trivial? (literally setting
  `__index` and `__newindex` to their default behaviour!)"
- `:475` — "why set `__index` if its trivial"
- `:476` — "we have characteristical 'frozen write' metatable, why not use class
  instead of repeating same setmetatable three times?"
- `:795` — "why so special treatment for `before_exit_slot` if
  `default_before_exit` is simply a noop? that's exactly case where simple check
  of nil-ness followed by execution of non-nil function would be justified than
  complex meta-table juggling (feel free to contest)"
- `:1285` — "that's exactly where we can check hook existance before execution
  instead of relying on 20 lines of useless boilerplate and metatables"

(Line numbers are as of the review; find them by content, they may have moved.)

He is probably right about several and probably wrong about at least one, and I
need to know **which** before I touch anything. The design rule these wrappers
implement is in `doc/development/decisions/input.md`, Decision 7: the
`compy.input` container and its sub-tables are **frozen** — a project cannot
replace `compy.input.shortcuts` or `compy.input.hooks` — while every **leaf**
inside stays writable. Some of these metatables implement exactly that; others
may genuinely reproduce default table behaviour and be deletable.

## Your task

For **each** wrapper named above, answer one question with evidence:

> **What does this metatable make impossible that a plain table would allow?**

The way to answer is not to read it and reason. It is to **run the experiment**:

1. Write a scratch Lua script (or a scratch busted spec placed in
   `/tmp/.../scratch-audit/`, run with `busted <path>`) that builds the surface
   the way production does and attempts the write that the metatable is supposed
   to refuse — `compy.input.shortcuts = {}`, `compy.input.hooks = {}`,
   `compy.input.fn = {}`, `compy.before_exit = nil`, a leaf write, and so on.
   Record what happens: does it raise, silently succeed, or silently no-op?
2. Then **mutate**: temporarily replace the wrapper with a plain table (or drop
   the metamethod), re-run the same probes, and record what changes. **Restore
   the file immediately afterwards.** If nothing changes, the wrapper is
   provably inert and the owner is right. If a probe stops raising, the wrapper
   is load-bearing and you have the exact behaviour it protects.
3. Run `busted tests` after each restore and confirm **934 successes / 0
   failures / 0 errors / 3 pending**. Report immediately if it differs — that
   means a restore did not take.

Also answer, for the `before_exit` pair (`:795` and `:1285`) specifically:

- Does anything depend on `compy.before_exit` being non-nil at the call site —
  i.e. would `if compy.before_exit then compy.before_exit() end` at
  `stop_project_run` behave identically for a project that never set it, one
  that set it, and one that set it to `nil` after setting it?
- Is the slot's assignment path doing anything besides storing a function
  (validation, type-check, rejecting a non-function)?

## Tools and correctness

- **The `lua-lsp` MCP server may be available** (defs / refs / hover /
  diagnostics over a real AST of the `/repo` workspace). It was unreachable
  earlier in this session — every call returned a broken pipe — so **try it
  once, and if it fails, fall back to grep and say so in your report.** Do not
  silently substitute one for the other.
- The test suite is `busted tests` from the repo root, no display needed.
- `git show 3256aac:<path>` shows a file as it was before this feature landed;
  useful if you want to know whether a wrapper predates the work.

## Deliverable

Write **`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S27-surface-audit.md`**:

One section per wrapper, each with:

1. **What it is** — name, current `file:line`, two lines on what it wraps.
2. **The probe** — the exact code you ran and the exact result.
3. **The mutation** — what you replaced it with, and what changed. Quote the
   error text that appears or disappears.
4. **Verdict** — `LOAD-BEARING` (with the one behaviour it protects, stated as a
   sentence a reader can test) or `INERT` (nothing observable changed).
5. **If INERT: what removing it costs.** Does any test cover it? Does any doc
   claim it? Grep for both.

Then a short **summary table** (wrapper / verdict / one-line justification) and,
last, a **shared-shape note**: of the ones that are load-bearing, do they
implement the *same* freeze? If so, say what a single shared helper would have
to take as parameters to replace all of them — that is the owner's `:476`
question and I want it answered with the actual signature, not "yes it could be
factored".

End with a `git status --short` transcript proving the tree is clean.

Be blunt about what you could not settle. An honest "the probe was inconclusive
because X" is worth more than a confident guess.
