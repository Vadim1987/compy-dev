# BUG-01-01 cold review — hidden-configure draft teardown

Reviewer had no access to the author's own analysis (wip/ tree
unread by design). Verified against `src/`, `tests/`, and the
persistent docs (`doc/input_api.md`,
`doc/development/{decisions,internals,technical_debt}/input.md`)
only, plus `busted tests` runs. Commits reviewed: `bd2a5d49`
(fix), `abadf244` (debt correction). `3b0e9f61` out of scope.

## Verdict

**Approve.** The diagnosis is correct, the fix closes the hole on
every reachable path, it does not open a new one, and the test is
honest — confirmed by reverting the production change in a scratch
worktree and watching the new case fail at the exact assertion the
commit message claims.

## Claims checked

| Claim (from commit message) | Status | Settled by |
|---|---|---|
| `get_compy_input()` runs inside `prepare_project_env`, which `ConsoleController.new` calls once | Verified (incomplete but not misleading) | `src/controller/consoleController.lua:80` is the sole call to `prepare_project_env`; `1005` is its sole definition. `get_compy_namespace`→`get_compy_input` is *also* called from `prepare_env` (`consoleController.lua:984`), a second, likewise call-once site (`:79`). Both surfaces' `state.pending` alias the same `widget.pending`, so the extra call site doesn't undercut the conclusion — see next row. |
| `table.clone` copies the metatable, so env clones share `state` | Verified | `src/util/table.lua:64`: `setmetatable(res, getmetatable(obj))` reuses the *same* metatable object; `pairs` never sees `input`/`before_exit` (metatable-only `__index` fields, `consoleController.lua:843-847`), so cloning never re-derives them — every clone's `.input` resolves through the one shared metatable closure. |
| The draft therefore had application lifetime | Verified | Pre-fix, `state.pending` in `get_compy_input()` (`consoleController.lua:790-805`, pre-image) was a fresh literal `{ }` built inside a function called once per application — same argument as above, one level down. |
| Sibling channels (`shortcuts`, `hooks`, `callbacks`) don't share the hole | Verified | `reset_compy_input` wipes `shortcuts`/`hooks` by name off `_bindable` (`controller.lua:326-337`); `reset_callbacks` re-seeds `callbacks` in place (`userInputController.lua:478-482`). Both run from `clear_user_handlers`, called from `stop_project_run` and the crash path. |
| Fix: move `pending` to the widget, wiped via `reset_widget_outputs` | Verified | `userInputController.lua:49` (`pending = { }` in `new`), `:489-492` (`clear_pending`), `controller.lua:344-352` (`reset_widget_outputs` now calls `ui:clear_pending()`). |
| No public surface added | Verified | `build_widget_api` (`consoleController.lua:697-772`) exposes `show/hide/is_shown/get_cursor/set_cursor/set_text/configure/clear` only — no `pending` accessor. |
| Breaking test fails pre-fix at the draft, not elsewhere | Verified experimentally | See "Test honesty" below. |
| Suite is 969/0/0/10 | Verified | Ran `busted tests` at current HEAD: `969 successes / 0 failures / 0 errors / 10 pending`. |

## Findings

**None that block.** Two non-blocking documentation items:

1. **[minor] Stale doc, contradicts the PR's own correction** —
   `doc/development/internals/user_input.md:710`: *"`compy.input`
   is a table created once per project environment
   (`get_compy_input()`, `consoleController.lua:601-635`...)"*.
   This is the exact false premise `abadf244` corrects in
   `technical_debt/input.md` ("the call graph says the
   opposite"), left standing unedited ~700 lines earlier in the
   *same file* that `bd2a5d49` itself touches (for the
   `configure(config)` section, which now correctly says
   "run-scoped"). A reader who hits `:710` first gets the old,
   now-known-false story. The line-number citation
   (`:601-635`, current code is `:775-817`) is also stale, though
   that predates this PR.
   Failure scenario: a future contributor reads
   `internals/user_input.md` top-to-bottom (its intended use,
   per `agents/rules.md`'s "read the doc first"), reaches `:710`
   before the `configure(config)` section, and re-derives the
   same wrong premise the ledger entry just spent a paragraph
   retracting.

2. **[nit, opinion] `pending` field added to all four
   `UserInputController` construction sites, used by one** —
   `userInputController.lua:49` puts `pending = { }` in the
   shared `new()`, so the console's own input (`consoleController.lua:44`),
   and both editor inputs (`editorController.lua:12,16`) each
   carry an unused, never-read, never-cleared `pending` table.
   Harmless (nothing ever writes to it, so nothing leaks), but it
   is dead weight on a class used by three consumers that have no
   concept of a hidden-configure draft. No failure scenario — this
   is an opinion, not a defect.

## The two judgment questions

**Was the design choice right?** Yes. `callbacks` already
established the exact pattern being reused: a private,
compy.input-owned store that has to be per-run actually lives on
the boot-provisioned widget by reference, wiped in place at
teardown, because the closure that builds `compy.input` outlives
every project. Moving `pending` there is not a new mechanism, it's
the second instance of an existing one — which is the cheaper move
under a "fewer moving parts" mandate than the alternative (publish
a teardown handle from the closure to the framework, which invents
a registry pattern that doesn't exist yet, for a problem the
existing pattern already solves). The debt entry's own "Revisit"
clause agrees: a *third* run-scoped store should prompt reconsidering
the whole arrangement, not this one. I'd have made the same call.
The only cost is finding 2 above (three unused fields), which is
too small to justify a parallel mechanism.

**Is the vocabulary sound? ("draft")** No — it collides with an
existing, different sense of the same word in the same codebase.
`userInputController.lua:209` already defines
`UserInputController:discard_draft()`, and `doc/input_api.md:45`
already tells project authors that `after_submit` "clears the next
draft" — in both places "draft" means *the text the user is
currently typing, not yet submitted*. This PR's "hidden-configure
draft" means the opposite direction: a *programmer-supplied*
`prompt`/`text`/`cursor` staged for the *next* `show()`, never
touched by the user. Both meanings live in the same file
(`userInputController.lua:42` vs `:209`) and the payload of both is
literally a `text` field, so "the draft's text" is genuinely
ambiguous without context. A stranger meeting `clear_pending` next
to `discard_draft` would reasonably guess they're the same
mechanism or at least closely related; they aren't. This doesn't
change my verdict (the review prompt says vocabulary is under
separate ruling), but as a first read it did not land clearly.

## What I could not check

- Whether `close_project()` can be invoked without first calling
  `stop_project_run()` while a project is genuinely `'running'`
  with an unspent draft (it's reachable from `open_project`
  switching projects, and from the console's own `close_project`
  command). I traced this as far as the routing model: while
  `'running'`, keyboard/text handlers are occupied by the project
  route (`decisions/input.md`'s Decision-11 discussion,
  `controller.lua`'s `occupy_input`/`set_handlers`), so the
  console's own command line — where `close_project()` lives — has
  no path to receive input until a route-releasing transition
  (which *is* `stop_project_run`) happens first. I could not
  exercise this live (no display, and the fixture drives
  `stop_project_run` directly rather than through real routing), so
  this is inference from the code, not an observed run. If it's
  wrong, it's a pre-existing gap shared identically by `shortcuts`/
  `hooks`/`callbacks`, not something this PR introduced or missed
  relative to its siblings.
- The `lua-lsp` MCP is down as stated; all call-graph claims
  above were confirmed by `grep` across `src/` and `tests/` plus
  full reads of every hit, not by references/call-hierarchy
  queries.
