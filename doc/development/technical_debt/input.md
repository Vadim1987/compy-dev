---
description: Input subsystem debt — sorted ACTIVE / BACKLOG / RETIRED by release scope
status: active
audience: developer
authored: llm
reviewed: none
---

> REVIEW: drop everything resolved, actualize the list, and maybe make it a bit more comprehensive (less prose, more facts). ToC (list) at the beginning would also help
> REVIEW: absolutely no mentioning of particular commits is allowed, they will be reassembled for the PR

# Input subsystem

Keyboard/text/pointer routing, the console and project input controllers
(`src/controller/controller.lua`, `userInputController.lua`,
`projectInputController.lua`, `consoleController.lua`), and the project-facing
`compy.input` surface. Cross-reference: `internals/user_input.md`,
`../input_api.md`. "The input API" below means the `compy.input` surface
introduced in **1.0.0-rc20260712**.

Three sections below, in release-scope order — not severity, not intent:
**ACTIVE** must be resolved before this release ships. **BACKLOG** is real and
acknowledged, but deliberately deferred past this release. **RETIRED** is
paid, or turned out not to be debt.

---

## ACTIVE

**Empty as of 2026-09-03** — every entry **in this file** that had to be resolved before this
release ships is paid, and each is in `RETIRED` below with what paid it. The section being empty is
a state, not an omission: `BACKLOG` is still full, deliberately, and nothing there blocks the
release.

**This file is not the whole of the release's input obligations.** Two of the three `ACTIVE`
entries in [`general.md`](general.md) are this work's, filed there because they are cross-cutting
rather than input-specific: **`T-NEVER-SHIPPED`** (scoped to *this file's* `RETIRED` section) and
**`T-ARGUES-INTERIM`** (`../decisions/input.md`). A reader scanning for *what is still owed* reads
both files. *(Two more were paid on 2026-09-03: the version question, which the owner ruled, and the
verification of this file's `RETIRED` claims, which `FIX-02-05` ran.)*


## BACKLOG

### Two shipped example READMEs still teach the removed polling idiom

- **Where:** `src/examples/repl/README.md` — the *"How this translates into code"* block
  (`r = user_input()`, `r:is_empty()`, `local input = r()`) and the two-options list under it
  (`input_text()`, `input_code()`); `src/examples/valid/README.md` — the opening sentence and the
  worked snippet (`user_input()`, `validated_input({non_empty})`).
- **State:** both examples' `main.lua` **are** onboarded onto `compy.input`. Only the READMEs were
  left behind, so each project ships working code beside a document teaching an API that no longer
  exists — a reader following the README calls a `nil`.
- **Why this is not the entry beside it.** *"Per-example internals docs still describe a retired
  polling idiom"* covers `../internals/examples/*.md`, a different set of files in the development
  corpus. These two ship **inside the example project**, which is the first place a project author
  looks, and neither entry's sweep would have found the other's files.
- **Size: not a find/replace.** `repl`'s README is a tutorial whose narrative *is* the poll loop —
  create a handle, test it for emptiness, read the value — and the replacement has no handle and no
  polling at all. Each needs a real rewrite, the same conclusion the internals-docs entry reached
  about its own set.
- **Found:** 2026-09-03, while base-checking `FIX-02-17` by differencing `project_env`'s keys at
  `3256aac` against HEAD. Nothing was looking for it; the retired names simply still had hits.
- **Revisit:** whether this is release scope is the **owner's call** — it is documentation rather
  than behaviour, which argues for deferring, and it is *shipped, project-author-facing*
  documentation that is now false, which argues the other way. Filed `BACKLOG` because a slug is
  the commitment to fix.

### `release_keyboard_route` is named for a lifecycle step that no longer exists

- **Where:** `controller.lua`, `Controller.release_keyboard_route`. One call
  site: `consoleController.lua`, `run_project`'s failure branch.
- **State:** the name asserts three things that are not true. It is **not
  keyboard-specific** — it calls `project_input:deactivate()`, dropping the
  whole route, and empties the derived click slots. It is **not a lifecycle
  release** — the `'running' → 'project_open'` release is gone and every channel
  shares one lifetime ending at the project's stop (`../decisions/input.md`,
  D-ROUTE-LIFETIME as amended). And it is **not reached on the transition it
  names**: the crash path is its only caller.
- **Why this is not simply a rename, which is why `FIX-02-06` left it.** The
  caller follows it immediately with `clear_user_handlers`, which clears every
  bindable channel; the two together are the crash teardown, and this one covers
  the part the other does not. Naming it accurately means first deciding whether
  they should be **one** function — a design call, not a docs sweep. A rename
  chosen without that decision would just be a second inaccurate name.
- **What it costs today:** the doc comment now opens with *"NOT a lifecycle
  step, despite the name"*. That is a comment paying rent for a name, which is
  the smell — not a defect. No behaviour is wrong and no reader is misled now
  that the comment says so.
- **Trigger:** revisit when the crash teardown is touched, or if
  `clear_user_handlers` changes. Found 2026-09-02 at `FIX-02-06`, whose own
  triage (`ACC-01-02-findings-triage.md`, old `FIX-02-14`) proposed the rename
  and did not have this dependency in view.
- **Not slugged** — no commitment to fix before release.

### `_set_text_line` has an unreachable table branch

- **Where:** `src/model/input/userInputModel.lua` —
  `UserInputModel:_set_text_line`, where
  `elseif type(text) == 'table' and ln == 1 then` is nested **inside**
  `if type(text) == 'string' then`, so its guard can never hold.
- **State:** dead code that reads as a supported shape. A reader looking for
  "can `_set_text_line` take a list?" finds a branch saying yes, and it has
  never run.
- **Provenance: pre-existing**, and the same fossil family as the dead
  `_update_cursor` call `BUG-02-01` retired — a shape carried through a
  migration and never re-checked. Found by that row's cold peer review,
  2026-09-01.
- **Not slugged**; nothing depends on it and no behaviour changes when it goes.
- **Revisit:** a one-line deletion inside the `_update_cursor` review below —
  same function, same pass, and the two should not be walked twice.

### Content normalisation treats `\n` but not `\r`

- **Where:** `src/util/string/string.lua` — `string.lines` splits on `'\n'`;
  nothing in `src/model/input/`, the string utilities or
  `userInputController.lua` mentions `'\r'` at all.
- **State:** `set_text("a\r\nb")` yields `{"a\r", "b"}`. The stray `\r` stays
  inside a line and the model counts it as an ordinary column, so the line
  measures one character longer than it displays and the caret can be seated on
  a position that renders nowhere. That is precisely the ambiguity
  **D-CONTENT-NORM** says normalisation removes — the decision is now scoped to
  `\n` explicitly because that is what the code implements.
- **Reachable:** a project setting content it read from a CRLF file. Whether the
  clipboard path is exposed is **unverified** — SDL may normalise
  `love.system.getClipboardText`, and nothing in the tree states either way; the
  project-sets-a-CRLF-string path needs no such assumption.
- **Provenance: pre-existing**, and not `#77`'s. `string.lines` has always split
  on `'\n'` alone. Found by the cold peer review of `BUG-02-01`, 2026-09-01.
- **Not slugged** — no commitment to fix; the release does not depend on it, and
  no shipped example reads CRLF content.
- **Revisit:** with the `_update_cursor` pass below, if one happens — both are
  about the model's idea of what a line is. Note the fix is **not** obviously
  "split on `\r\n` too": stripping a lone `\r` is a content change, and whether
  the framework should silently rewrite what a project set is the same
  tolerance question D-CONTENT-NORM bounds.

### `_update_cursor` measures the column on the wrong line

- **Where:** `src/model/input/userInputModel.lua` — `UserInputModel:_update_cursor`.
- **State:** it sets `cursor.c` from `t[cl]`, the line the caret was on
  *before* the change, and `cursor.l` to `#t`, the last line of the content
  *after* it. When those differ the result is a column measured on one line and
  reported against another, and it can be **out of range**: on
  `{'one','twotwo','xx'}` with the caret on line 2, it yields `(3, 7)` — line 3
  is `"xx"`, whose caret positions are `1..3`. Probed, not inferred.
- **The intent is not in doubt, and the function used to satisfy it.** Before
  multiline it read, in full:
  `self.cursor.c = utf8.len(t) + 1` over a **string** `self.entered` — *seat the
  caret at the end of the content*, which is exactly what `jump_end` now does
  for a line list. The multiline commit (`19351528`, 2023-07-17, *"add multiline
  input representation"*) rewrote it to index a list and **measured the wrong
  line**: to preserve the intent it needed `t[#t]`, the line `.l` is being set
  to, and it used `t[cl]`.
- **The empty `else` is not a missing feature**, though it reads like one. The
  pre-multiline version was `if destructive then … end` with no `else` at all;
  the migration wrote the no-op branch out longhand and left it empty. Nothing
  has ever depended on it, in any revision.
- **Why it is BACKLOG and not ACTIVE: nothing observes it today.** After
  `BUG-02-01` deleted the `set_text` call, two call sites remain and neither
  exposes the defect. `_set_text_line`'s is guarded by `if not keep_cursor` and
  **all seven of its callers pass `true`**, so it is unreachable. `clear_input`
  reaches it, but on empty content every line measures zero, so the wrong line
  cannot give a wrong answer — it lands at `(1,1)`, which is correct by
  accident rather than by construction.
- **Why it is still debt:** it is a trap with no warning sign. The first caller
  to pass `keep_cursor = false` to `_set_text_line`, or the first content change
  that leaves `clear_input` non-empty, gets an out-of-range cursor with no raise
  — and the function's name and privacy marker both suggest it is a settled
  primitive.
- **The mechanism is that it bypasses the validated path.** `move_cursor` is the
  model's checked mover: it rejects an out-of-range line or column, falling back
  to the previous value, and it measures the line length **on the line it is
  moving to**. `_update_cursor` writes `self.cursor.l` and `self.cursor.c` as
  raw fields instead, so nothing catches the mismatch. Routed through
  `move_cursor` the bad `(3,7)` above could not have been produced, which is the
  same statement as saying `jump_end` already does this correctly: it computes
  `#ent` and `ulen(ent[last_line]) + 1` from the *same* line and hands both to
  `move_cursor`.
- **There are THREE raw writers, not two, and the third is on a hot path.
  Corrected 2026-09-01 by cold peer review**, which refuted this entry's
  original claim that `_update_cursor` and `_advance_cursor` were "the only two".
  `UserInputModel:insert_text_line` does `self.cursor.l = l + 1` unvalidated, and
  it is reached on **every Shift+Enter** (`UserInputModel:line_feed`) and by
  Ctrl+D duplicate-line (`userInputController.lua`, the `modify` handler in
  `_normal_mode_keys`) — where the other two are reached rarely or not at all.
  The correction **strengthens** this entry's disposition rather than weakening
  it: the population to review is three, one of them live on ordinary editing,
  so *"review the cursor writers"* is a bigger and better-justified pass than
  *"repair this body"*. (`UserInputModel:set_cursor` also replaces the whole
  `Cursor` with no check, but it takes a constructed `Cursor` rather than
  writing fields, so it is a different shape.)
- **The likelier disposition is not a repair at all: this is a partial,
  unvalidated duplicate of `jump_end`, and what wants reviewing is its USAGE.**
  Both exist to seat the caret at the end of the content — that is what
  `_update_cursor` did correctly when it was single-line, and it is what
  `jump_end` does now. `jump_end` computes `#ent` and
  `string.ulen(ent[last_line]) + 1` **from the same line**, routes both through
  the checked `move_cursor`, and finishes the job: it settles the selection and
  moves the visible range. `_update_cursor` derives half its answer from a
  different line, writes raw fields, and does neither. So the review to run is
  *"does each call site want `jump_end`?"* rather than *"is this body right?"*,
  and repairing `t[cl]` to `t[#t]` in place would leave a second way to do one
  thing — which is what D-CONTENT-NORM's structural half exists to stop.
- **It is not a drop-in swap, which is why this is a review and not an edit.**
  At `clear_input` — the only reachable call site — `jump_end` would land the
  caret identically at `(1,1)`, but it also calls `end_selection` and
  `visible:to_end()`. `clear_input` already calls `clear_selection()` just
  above, so the first is redundant rather than wrong; whether the visible-range
  reset is *wanted* on a clear is a real question and has not been checked.
  Answer it before swapping, not after.
- **The narrow repair stays on the table** — `t[#t]` for the column, one token
  — as the answer if the review finds a caller that genuinely wants a raw,
  unvalidated seat. Nothing today does.
- Either way it touches a shared model primitive rather than this feature's own
  surface, which is why it is not being decided inside `#77`.
- **Provenance: pre-existing, and not this feature's.** The slip is from 2023,
  three years before this branch, and `#77` neither introduced nor widened it —
  it only deleted the one call site that made the asymmetry visible.
- **Not slugged** — a slug is the commitment to fix, and whether this is fixed
  before the release is not decided. Nothing user-visible depends on it.
- **Revisit: a pure-refactoring pass over the cursor writers, not a bug fix**
  (owner, 2026-09-01) — it does no harm unless another caller reaches it or the
  call sites change, so it waits for the pass that would review
  `_update_cursor` against `jump_end` and decide whether the first should exist
  at all. Marked at the site with a `DEBT:` comment so a reader of the code
  meets the entry rather than the bug.

### The error highlight compares a byte column against a character index

- **Where:** `src/view/input/userInputView.lua` — `ec = perr.c` is read off the
  parse error, and the draw loop that counts `tl = string.ulen(s)` compares its
  character index against it.
- **State:** the parser reports an error column as a **byte** offset
  (`model/lang/lua/parser.lua`, `get_error`, read out of metalua's message),
  while the loop that colours the line counts **characters**. On a line holding
  multi-byte content the byte column exceeds the character index it is compared
  with, so the error colouring starts further right than the error is. On ASCII
  the two coincide and it looks correct, which is why nobody has seen it.
- **Sibling, already fixed:** the same byte column reached the **caret** through
  `_apply_eval`, where the new character bound refused it outright and the caret
  stopped moving. That was a live regression and was fixed with a `char_col`
  conversion. This site is the other consumer of the same value, found by the
  same review.
- **Why it stands (owner ruling, 2026-08-31):** deferred past this release. It
  is cosmetic — a wrong colour extent, never wrong content and never a crash —
  it reaches only the console and editor error display, and it is not the input
  API's surface. **No slug**, by the convention that a slug is the commitment to
  fix.
- **What the guide promises, and why that promise still holds.** `../input_api.md`
  (*"Characters, not bytes"*) says *"every cursor position the widget reports or
  accepts is counted this way"*. The sprint's peer review read that as
  over-reaching, on the argument that an error column is a position the widget
  accepts. It is not one: `ec`/`el` reach `userInputView` only to choose a
  colour, and no project-facing call reports or accepts them — `get_cursor`,
  `set_cursor` and `show{cursor}` are the whole surface the sentence governs,
  and all three now count characters. The sentence stands as written; it is
  recorded here because the reasoning is not obvious from either document and
  the next reader will otherwise re-open the question.
- **Shape when taken:** reuse `char_col` (`model/input/userInputModel.lua`), or
  lift it where the model and the view can both call it. Do not fix the view
  alone — the unit should be settled once, at the boundary where the parser's
  answer enters the input subsystem, rather than at each consumer.
- **Revisit:** when the error display is next touched, or if mis-coloured errors
  are reported on non-ASCII source.

### D-ROUTE-OWNS — console/editor convergence onto the shared chain is unimplemented

- **Where:** `src/controller/consoleController.lua` (`ConsoleController:keypressed`,
  `:1516`) and `src/controller/editorController.lua`
  (`EditorController:keypressed`, `:825`) — each still runs its own narrow,
  single-argument dispatch, not the project route's `dispatch(shortcuts, hooks,
  widget, event, trigger, ...)` chain.
- **State:** D-ROUTE-OWNS (`../decisions/input.md`) names this convergence as
  "deliberately left as a follow-on, not attempted," and D-LOVE-ARGS and
  D-EXACT-RESERVE repeat the same scope note in different words. The decision text
  is honest about the gap; the gap itself is still open.
- **Why it stands:** out of this feature's mandate — scoped out on filing, not
  an oversight found later.
- **Revisit:** when the console/editor routes are migrated onto the combo
  mechanism. See also "Console and editor route handlers bind by hand-written
  modifier tests," which is this gap's symptom one layer down.
- **Release scope:** **BACKLOG, not ACTIVE** — the decision itself calls the convergence a
  deliberate follow-on, so it is deferred past this release by the ruling that created it.
  Re-sorted 2026-08-27 by the cross-check in `agents/rules/ledgers.md` §5: it was the one
  ACTIVE entry with no roadmap row, and the absence was the symptom, not the cause.

### Widget sink reaches the singleton via `love.state` global + nil-guard (RESOLVED-IN-PART by the input-API redesign)

- **Where:** was `src/controller/projectInputController.lua`, `_sink` — read
  `love.state.user_input_controller` on each call and guarded it with
  `if ui then …`.
- **Old state:** The old tier-4 `_sink` reached the widget through a global
  rather than an injected instance field (`self.input`), and defended with
  a nil-check against a value the singleton convention said was always
  present.
- **Resolution:** The sink is gone. `dispatch` (the free-function extraction
  recorded as an implementation note in `decisions/input.md`,
  `projectInputController.lua:74-86`) is now a free function that takes the
  widget **as a parameter** rather than reaching for a global itself — the
  concern moves one level up, to `ProjectInputController:_dispatch`
  (`:93-97`), which is the one remaining place that resolves
  `love.state.user_input_controller`. The nil-guard (`if widget and
  widget:is_shown()`) is carried at that boundary, not inside the reusable
  mechanism.
- **Revisit:** Whether `_dispatch` itself should inject `self.input` at
  construction instead of reading the global, and turn its nil-guard into
  an assertion, remains open — the same question, one layer up.

### The Web build has no coverage, and carried a feature-era regression unseen

- **State:** nothing in `busted tests` exercises the `_G.web` branch. A
  defect reachable only on the Web build is therefore invisible to every
  check this project runs.
- **Amended 2026-08-28:** this entry used to add "and the suite runs on
  LuaJIT". It does not — it runs on whatever interpreter the developer's
  `busted` uses, and on the owner's machine that is PUC Lua 5.1. That is how
  the retired `wrap` arity defect surfaced. The lint proposed below would
  not have caught it either: the call was not bare, it was on the guarded
  branch. A second interpreter in CI remains the only check that would.
- **The worked example, found 2026-08-03:** the dispatch chain introduced by
  `56c4284f` wrapped project keyboard handlers in a **bare**
  `xpcall(fn, handler, unpack(args))`, with no web branch. On PUC Lua 5.1 —
  what the Web build runs — `xpcall` drops the trailing arguments, so every
  adopted `love.keypressed` / `textinput` / `keyreleased` would have been
  called with nil for `key`, the held-key view and `isrepeat`. Before the
  feature there was exactly **one** `xpcall` in `controller.lua`, inside
  `wrap`'s guarded branch; the feature added a second, unguarded one. The
  wrapper collapse (`f1dc6aee`) removed it again, so the count is back to one
  — the regression is fixed, but it lived undetected for the whole feature
  because no check could see it.
- **Why it stands:** running the suite against PUC Lua 5.1, or building and
  driving love.js in CI, is infrastructure this project does not have, and
  neither is in this feature's scope.
- **Shape:** cheapest useful step is a lint or a review checklist item —
  **no bare `xpcall` with arguments in `src/`**; argument-forwarding goes
  through `wrap`. A grep is enough to enforce it and would have caught this.
- **Revisit:** if a Web build is released, or when CI grows a second
  interpreter.

### A project that raises leaves global device state dirty; no force-reset exists

- **State:** the sandbox deep-clones the `love` table but shares leaf C
  functions, so a project's imperative `love.*` calls — `setKeyRepeat`,
  `setTextInput`, `setRelativeMode`, raw audio — mutate real SDL/LÖVE state.
  The only mechanism that restores any of it is the project's own
  `compy.before_exit`, and by ratified contract that hook fires on **stop**
  paths only; crash is explicitly out of its scope. A project that mutates
  global state in top-level code and then raises therefore never restores it:
  `run_project`'s failed-run branch drops to `project_open` without ever
  calling `stop_project_run`, so nothing fires, and the dirty state bleeds
  into the next run. `examples/keyboard` is the canonical mutator — it calls
  `love.keyboard.setTextInput(true)` and `love.mouse.setRelativeMode(true)`
  at startup. *(This entry used to name `setKeyRepeat(false)` there; that
  call has never existed in that repo's history — checked with `git log -S`
  across all refs. The platform's `src/main.lua:297` is the only
  `setKeyRepeat` caller and it turns repeat **on**, corrected 2026-08-12.)*
- **Why it stands:** two separate rulings, both deliberate. The hook is scoped
  to stop paths by design — crash/hard-kill was called out as a later layer,
  not an oversight. And firing a *partially initialised* project's teardown
  was ruled against (owner, 2026-08-03): no proper start, no contract is
  expected to run. Resetting the slot is a different question and IS done —
  a dead project's hook must not survive to fire against the next project's
  state (fixed 2026-08-03, `226628ae`).
- **Shape:** a framework-owned **force-reset** of the global surfaces the
  sandbox shares, run on every run-ending path including the crash ones, and
  independent of `compy.before_exit` — a project that crashed cannot be
  trusted to clean up after itself, which is exactly why its own hook is the
  wrong instrument here.
- **Revisit:** owner ruled 2026-08-03 to record it and implement the
  force-reset later; revisit when that work is scheduled.
- **The stop path is project-by-project until then (2026-08-12).**
  `examples/keyboard` now restores relative mode in its own
  `compy.before_exit` (P-18-05), which closes the leak for that project on
  every stop path and for no other. The framework-side question — should the
  platform tear down device modes a project changed, rather than trusting
  each project to — is the "Shape" bullet above, and is not answered by that
  fix. It is worth noting that the example's comment asserted for months that
  *"the runner restores it on exit"*: a project author's reasonable
  assumption about a platform that in fact restores nothing.
- **Where it goes when built (2026-08-07):** `framework_before_exit`
  (`consoleController.lua`) is now the framework's own teardown function and
  the only caller of a project's hook (D-STOP-IS-FW). It is the seam this entry
  has been describing — a framework-owned step, adjacent to but independent of
  `compy.before_exit`. Note the crash path still does not reach it: it calls
  `reset_before_exit` only, deliberately, since a partially initialised project
  runs no teardown. Wiring the force-reset means calling the framework half on
  the crash path too, which is a decision this entry does not pre-empt.

### `compy.before_exit` is a closure slot

- **Where:** `src/controller/consoleController.lua`, `get_compy_namespace` —
  `before_exit` is a metatable-intercepted upvalue rather than a field of the
  namespace table.
- **State:** `table.clone` copies with `pairs` and reuses the metatable **by
  reference**, so a closure-captured slot is invisible to the copy and every
  clone of the namespace shares one variable. `base_env.compy.before_exit` and
  `project_env.compy.before_exit` are therefore the same slot, permanently. A
  plain field would be deep-copied per clone instead.
- **Why it stands:** Nothing tests, documents or depends on the sharing, and
  the suite passes with a plain field — so on its own it reads accidental. But
  `compy.input` survives cloning by the *same* mechanism, so a plain field
  would make `before_exit` the odd member of the namespace, and the sharing may
  be load-bearing for a path not yet identified.
- **Revisit:** Decide whether the sharing is intended. If it is, say so where
  the slot is built; if not, a plain field is simpler. Evidence, with probe
  transcripts: the frozen-surface audit run in session27.
- **Not to be confused with** the crashes fixed on 2026-08-07: the call site is
  now guarded against both an absent hook and a raising one, which is orthogonal
  to how the slot is stored.

### A truthy `hooks[event]` return silently disables `on_limit_reached`

- **Where:** `src/controller/projectInputController.lua` (the free-function
  `dispatch`) — `hooks[event]` runs before the widget; `userInputController.lua`
  (`emit_limit`) fires `on_limit_reached` only from inside the widget itself.
- **State:** A project that sets `compy.input.hooks.keypressed` (or the
  text/release siblings) and returns truthy consumes the event at the
  hooks step, so `dispatch` never reaches the widget and the widget's
  `on_limit_reached` callback never fires for that keystroke — no
  error, warning, or other signal marks the drop. Carried through the
  input-API redesign unchanged — renamed from the old tier-3/tier-4
  vocabulary to hooks/widget, but the underlying coupling is the same.
- **Why it stands:** The truthy-consume shape (decisions/input.md,
  D-CHAIN-OF-3) is working as designed; it just wasn't checked against
  this specific hooks/widget interaction. No dedicated guard exists.
- **Revisit:** Note the coupling wherever `on_limit_reached` is
  documented for project authors, or decide it needs a guard.

### A raise from project top-level and from a handler surface differently

- **Status:** owner ruled (2026-07-31) to leave the behaviour as-is and refer
  the question to stakeholders; recorded here with the options as ruled.
- **Where:** `consoleController.lua` `run_project` / `run_user_code` versus
  `controller.lua` `user_error_handler`.
- **State:** the same authoring error reaches the author two different ways,
  decided by which `pcall` catches it. Raised from **top-level project code**:
  `run_user_code`'s `pcall` returns, `run_project` prints `'Error: ' .. msg`
  and drops to `project_open` — one console line, the project still open,
  nothing else on screen. Raised from a **`love.*` handler or hook**: `wrap`
  → `user_error_handler` → `suspend_run(msg)` → the error window over the
  project's last frame.
- **Why it matters:** balloons (smoke report 5) passed a lifecycle callback
  inside `show{}`, which D-UNKNOWN-RAISES makes a raise. The raise printed its line
  and left the user "in a console that gave no signal they were still inside a
  project" — which is the failure mode D-UNKNOWN-RAISES's own rationale ("explicit
  failure mode") is meant to prevent.
- **Options:** (a) route a top-level raise through the same suspend/error
  window path as a handler raise — one failure surface for one class of
  failure; (b) keep the console line but make the state legible (name the open
  project and how to leave it); (c) leave as is. **Recommended: (a)** — the
  asymmetry is an accident of which `pcall` caught it, not a decision anyone
  took, and (b) preserves the accident while adding words to it.
- **Revisit:** AFTER the PR merges, not during its review (owner,
  2026-08-03). Deferred deliberately to keep the PR's scope to the
  stakeholders' ask, and to leave them room to contest the suggested fix —
  a glitch may have had a reason nobody here can see.

### `close_project` bypasses the run's exit path

- **Status:** open — needs one ruling, either way.
- **Where:** `consoleController.lua` `close_project`, reachable from a running
  project's own env and from the console during `inspect`.
- **State:** it sets `app_state = 'ready'` and returns. `stop_project_run` is
  never called, so `compy.before_exit` never fires and handler teardown never
  runs. `quit_project` does it correctly (stop, then close); the bare path does
  not. The widget half is now handled at the call site (it destroys its own
  widget) — the rest of the exit path is not.
- **Decide:** either `close_project` runs the normal exit path, **or** the
  omission is confirmed deliberate and the reason is written down here. It is
  currently neither, which is why this entry exists.
- **Revisit:** with the next change to project lifecycle.

### A raise at `project_open` is swallowed whole, so pen-and-paper projects report errors worse than any other kind

- **Status:** open — found while probing the dispatch path's nil-safety during
  the widget-lifetime work; **not a feature regression**, the gate below is
  verbatim at the PR base. Sibling of the entry above: same class (what the
  author sees depends on something they did not choose), different cause —
  there it is *which `pcall` caught it*, here it is *what `app_state` happened
  to be*.
- **Where:** `controller.lua` `user_error_handler` → `consoleController.lua`
  `suspend_run`, whose first act is `if love.state.app_state ~= 'running' then
  return end`.
- **State:** a raise inside a hook or a `love.*` handler reaches
  `user_error_handler`, which calls `suspend_run` — and `suspend_run` does
  nothing unless the app is in `'running'`. A **non-blocking** project settles
  in `'project_open'` and lives there (see "Input-only / pointer-only projects
  stay live in `project_open`"), so for that whole lifetime a raise produces
  **no error window and no state change**. The only trace is the console line
  `user_error_handler` prints afterwards, and in pen-and-paper mode the
  project's canvas is what the user is looking at.
- **Confirmed by probe, not by reading:** the same raise in the same hook sets
  `suspend_msg` while `'running'` and sets nothing at `'project_open'`.
- **Why it matters:** this is the class of project — `sapper` is the shipped
  example — whose *entire* logic runs in hooks. Every authoring error in the
  part of the program that does the work is invisible, while the same error in
  the same project's top-level code is not. The gate reads as a guard against
  suspending something that is not running; the projects it silences are
  running in every sense the author cares about.
- **Options:** (a) drop the `'running'` gate and let `suspend_run` fire from
  `'project_open'` too — needs a check that the snapshot/resume path is sane
  from that state; (b) leave the gate and give the `project_open` case its own
  surfacing; (c) leave as is. No recommendation yet: (a) is small but touches
  the suspend path, which is not this feature's territory.
- **Revisit:** with the entry above — same decision-maker, same session,
  **after the PR merges**. Both are pre-feature behaviour and neither belongs
  in the stakeholders' ask.

### The error lock is correct, documented, and hostile

- **Status:** owner ruled (2026-07-31): behaviour is pre-feature, so leave it;
  record the UX concern with options for stakeholder review.
- **Where:** `userInputController.lua` — while `model:has_error()` holds,
  `textinput` is dropped and `keypressed` is swallowed except Enter / Space /
  arrows, which clear the error.
- **State:** to a user this is a freeze with no stated exit. It is what
  smoke reports 1 (guess, "froze after entering a symbol") and 9 (valid,
  "entering '1' stops processing any input") describe. The error band itself
  IS rendered and, since the widget-paint fix, IS visible; nothing in it says
  which keys resume.
- **Pre-feature check (asked for at the ruling):** nothing to reproduce. At
  the PR base `3256aac` the same lock exists and is **stricter** — only Enter,
  Up and Down cleared it, where today's also accepts Left, Right and Space.
  The band's invisibility was equally pre-existing (same render path, same
  unpainted widget). The input API neither introduced the lock nor narrowed
  its exits; it widened them.
- **Is the widening drift? No — it is the ratified behaviour, and it also
  matches what the docs already claimed.** The frozen design (`§10 Edge
  cases`) reads "input locked until acknowledged **(Enter/Space/arrows)**",
  and the widening landed under that AC with the reason in its commit message
  (`9bb6d29`, "Widen the sink's has_error() lock-clear gate to
  Space/Left/Right"). It is not a side effect of the 2D cursor/limit work —
  no other commit touches that key list. Independently, `internals/user_input.md`
  described the exit set as "Enter, space, or arrow keys" **at the PR base**,
  while the code did Enter/Up/Down: the change aligned code with both the spec
  and the doc. Narrowing it now would be a design change to a frozen document,
  not a drift fix.
- **The quirk worth naming:** an arrow key *acknowledges* the error and is
  then swallowed — it does not also move the caret to the offending character,
  which is what a user pressing Left after "not allowed" is trying to do. And
  `keyreleased` clears on Space as well, so Space acknowledges twice
  (harmless, but the two handlers duplicate the rule).
- **Options:** (a) append a hint line to the rendered error band ("Enter or
  Space to continue") — smallest change, no semantics touched;
  (b) clear the error on the next `textinput`, which makes a rejected line
  silently editable and drops what the lock is for; (c) leave it documented
  only. **Recommended: (a)**.
- **Revisit:** AFTER the PR merges, not during its review (owner,
  2026-08-03). Deferred deliberately to keep the PR's scope to the
  stakeholders' ask, and to leave them room to contest the suggested fix —
  a glitch may have had a reason nobody here can see.

### `repl` does not evaluate, and its name says it does

- **Status:** owner ruled (2026-07-31): behaviour is pre-feature, so keep it;
  record the UX concern for stakeholder review.
- **Where:** `src/examples/repl/main.lua`.
- **State:** the example prints each submitted line back — `on_text_entered`
  pipes lines to `print`, and the widget runs the plain-text evaluator
  (`InputEvalText`), which has no parser. `x = 2 + 3` returns the characters,
  not a binding.
- **Pre-feature check (asked for at the ruling):** the same. At `3256aac` the
  example is `r = user_input()` plus an update loop doing `input_text()` /
  `print(r())` — reprint, not evaluate. The migration preserved the behaviour
  exactly.
- **Why it is a concern anyway:** evaluating Lua and printing a result is what
  the **console** does, and until the two fixes of 2026-07-31 (a refused
  widget after a project stop, and a project widget that was never painted at all)
  a project's input surface was visually indistinguishable from the console —
  same input line, no signal. An author testing `repl` could reasonably
  believe it evaluated, having been typing at the console. Both causes are
  fixed, so the modes now look different; the name still promises a
  read-**eval**-print loop the example does not provide.
- **Options:** (a) make it evaluate — the project env already exposes `eval`,
  so it is one line in `on_text_entered`; (b) keep the echo and rename the
  example (`echo`); (c) keep both, documented as-is (today's state).
- **Revisit:** AFTER the PR merges, not during its review (owner,
  2026-08-03). Deferred deliberately to keep the PR's scope to the
  stakeholders' ask, and to leave them room to contest the suggested fix —
  a glitch may have had a reason nobody here can see.

### A widget opened from a key can receive that key's own echo

- **Status:** answered by a **documented project idiom**, not by a framework
  mechanism (owner, 2026-08-03) — `../../input_api.md`, *"Worked example: the trigger key
  echoes into the widget it opened"*, pinned by `tests/input/input_widget_control_spec.lua`, group
  *"the documented echo guard"*, and used by `src/examples/turtle`. A
  framework fix was implemented and then reverted (2026-08-01) because its
  design had never been ruled. What remains open is whether the framework
  should ever take this over; the entry stays for that question.
- **Where:** `src/controller/controller.lua` (the `keypressed` / `textinput` /
  `keyreleased` gateways) and `src/controller/userInputController.lua` (the
  show path and the three widget handlers).
- **State:** LÖVE delivers a `keypressed` **and** a `textinput` for one
  physical key and guarantees nothing about their order. A project that opens
  the widget from a key therefore races its own trigger: measured — open on
  `keypressed('i')`, and the `textinput('i')` of the same press lands in the
  field, so the widget comes up already containing `i`. Opening on
  `keyreleased` (what `examples/turtle` does) is safe only because the echo
  usually arrives first; with the `textinput` delivered last it fails
  identically.
- **Why a project cannot fix it for itself:** it would have to consume a
  `textinput` whose text it cannot derive from the key name (`space` → `" "`,
  `shift+i` → `"I"`, anything an IME emits), and every project that opens a
  widget from a key would re-implement it.
- **Options:** (a) seal the widget for the rest of the event batch that
  opened it, released at the start of `love.update` — order-independent and
  needs no key→text mapping, but it also swallows an unrelated key typed
  within the same frame and assumes the stock run loop is the only pump;
  (b) match the trigger key's echo specifically — narrower, but needs the
  key→text mapping (a) avoids; (c) arm only on `keypressed`, leaving
  open-on-`keyreleased` projects racing; (d) no framework change, and the API
  documents an idiom projects follow instead — the workable one being a
  **paired shortcut**: register the trigger on both channels, where
  `shortcuts.keypressed[combo]` opens and `shortcuts.textinput[combo]`
  swallows the echo and unregisters itself, re-armed by whatever closes the
  widget. Verified in both delivery orders. Its limit: the re-arm has no
  single home (Escape clears without hiding, and there is no close callback).
  *(It was also confined to **bare** combos, by `T-COMBO-CASE`; that half is
  gone — dispatch lower-cases the trigger, so a `shift+i` registration now
  matches the `"I"` echo. A modified trigger additionally needs the modifier
  still held when the echo lands, which `BUG-01-04` did not test.)*
- **Revisit:** a design pass on the run loop's event-batch guarantees — the
  choice between (a)–(d) turns on what the framework is willing to promise
  about batch boundaries, which is a design question, not a bug fix.

### Combo triggers are key-name-only; positional bindings have no vocabulary

- **Where:** `src/controller/controller.lua`, `combo_string` — a combo's
  trigger is the LÖVE **key name**, which is layout-dependent, and the
  scancode is discarded at the gateway (`set_love_keypressed`:
  `local function keypressed(k, _, isr)`), so it reaches neither the routes
  nor the dispatch chain.
- **State:** compy has both audiences and serves only one. *Mnemonic*
  bindings — `ctrl+s` for save, `examples/turtle`'s `i` for input — want the
  key name, because the user's keycap says S. *Positional* bindings — a
  game's WASD — want the scancode, because on AZERTY `w` bound by name lands
  under the player's little finger. LÖVE exposes both for exactly this
  reason; the input API exposes only the first.
- **Why it stands (owner ruling, 2026-08-03):** not now, and **never as a
  swap** — a swap fixes one audience by breaking the other. No layout
  complaint exists in the record; this is a hypothesis about non-QWERTY
  users, not a report from one. Any future answer is **additive**: a second
  registration vocabulary (`shortcuts.scancode.*`, or an `sc:` prefix inside
  the combo string), never a change to what an existing combo means.
- **Also note it cannot help the textinput channel at all:**
  `love.textinput(text)` carries no scancode — one string, the character
  produced after layout, modifiers and IME. So scancodes cannot unify the
  keyboard and text channels; they would widen the gap between them.
- **Cost, if it is ever taken:** threading the scancode from the gateway
  through `forward_*` and the routes to the chain, and a scancode-keyed held
  set — `combo_string` builds its modifier prefixes from key names, so a
  scancode combo would otherwise be a hybrid (modifiers by name, trigger by
  position).
- **Revisit:** when a project needs layout-independent positional keys.

### A keyboard-hooks-only project does not count as interactive

- **Where:** `src/controller/controller.lua`, `user_is_blocking()` /
  `user_is_interactive()`, consulted by `ConsoleController:run_project` after
  the project's top-level code runs.
- **State:** the route is kept when the project replaced `love.update` or
  `love.draw` (blocking), or when it has a widget or a pointer handler
  (interactive). Keyboard hooks are neither. So a project whose only
  interaction surface is `love.keypressed`/`keyreleased`/`textinput` — no
  draw, no update, no widget, no pointer — hands the keyboard back to the
  console, and the hooks the framework captured for it (D-HOOKS-SEEDED) can
  never fire. `examples/keyboard` is *not* an instance: it defines
  `love.update` and `love.draw`, so it is blocking and keeps the route.
- **Why it stands:** hypothetical. No such project exists in the tree, and one
  would be invisible by construction — its only outputs would be sound or
  console text.
- **Revisit:** if a keyboard-only project appears, or when ruling (a)'s
  "interaction surface" definition is next revisited; the fix would be to
  count seeded hooks alongside the widget and pointer tests.

### `gui` is supportable as a modifier, and deliberately not supported

- **Not a defect, and not deferred work.** `gui` (super / cmd / win) is outside
  the modifier set by decision (`../decisions/input.md`, **D-THREE-MODS**), which
  carries the rationale: never requested, added only for symmetry with the
  table-driven builder D-ASK-THE-DEVICE dissolves. This entry exists so the option is
  discoverable from the debt side; the decision is the authority.
- **What it costs today:** nothing observable. No shipped project or example
  registers a `gui` combo. `gui+s` is refused at registration (it names two
  triggers, D-COMBO-SHAPE) and `lgui` is bindable as an ordinary trigger.
- **What re-adding takes:** a `gui()` accessor beside `ctrl()`/`alt()`/`shift()`
  in `src/util/key.lua`, the pair restored to `mod_triples` and the fold table,
  and the precedence list extended. Bounded and additive.
- **Revisit: when a requirement asks for it** — not for symmetry, which is what
  put it there the first time. Whether the answer is a modifier at all is the
  wider question in "Service keys have no special treatment" below; this entry
  states only what re-adding `gui` *as a modifier* would cost.

### Service keys have no special treatment: `capslock`, `tab`, `lgui`/`rgui`

- **Where:** `src/util/key.lua` — `Key.is_mod` recognises exactly the `ctrl`,
  `alt` and `shift` pairs, and the combo grammar (`split_combo`/`check_combo`)
  treats every other token as a trigger. Verified: **no code outside
  `src/examples/` mentions `capslock` or `tab` at all**, and `lgui`/`rgui`
  appear nowhere in the framework's own dispatch.
- **State:** these keys therefore bind and dispatch exactly like `a` or `f5`.
  Each of them is unlike an ordinary key on real hardware, in a different way:
  `capslock` carries a lock state the framework cannot query and whose release
  is not reliably delivered; `tab` is a traversal key that a UI layer may want
  to claim before a binding sees it; `lgui`/`rgui` are owned in part by the
  desktop environment, which may consume a chord before the app is told.
- **Why it stands:** nothing is broken by it, and nothing has needed it. No
  shipped project or example binds any of the three as anything but a plain
  key.
- **Why it is written down:** the framework has **no vocabulary** for this
  group — they are neither modifiers nor ordinary character keys, and the
  input model currently has only those two categories. That is the observation;
  the shape of any answer is deliberately left open.
- **Revisit: worth one review, at no scheduled point.** At least three
  directions are open and this entry favours none of them — widen the modifier
  set, keep it deliberately narrow (which is the standing position,
  `../decisions/input.md`, D-THREE-MODS), or introduce a distinct class for
  service keys with its own rules.

### The widget-handle shape test exercises a stub, not the real draw wiring

- **Where:** the `love.state.user_input` handle is asserted only for shape — that
  `love.state.user_input` is set and callable while the widget is shown
  (e.g. `tests/input/input_widget_callbacks_spec.lua`). The dedicated
  `overlay_spec.lua` that built an ad-hoc controller over a `draw`-only
  stub view was removed when the suite was re-authored; the gap below is
  what survived it, not the file.
- **State:** Guards against the handle being re-narrowed, but does not
  exercise the app's startup widget-instance wiring or the real
  draw wrapper `set_love_draw` installs in `controller.lua` — the exact path a
  past regression faulted at. Runtime spot-checks have covered that path
  manually; the automated suite has not.
- **Why it stands:** Driving that real draw wrapper from a unit
  test needs app-bootstrap wiring the input suite does not currently stand
  up.
- **Revisit:** When a change next touches the widget/dispatch wiring — add
  a test that drives the actual draw wrapper against the widget instance.

### `Esc` clears the input in place without hiding the terminal (turtle)

- **Where:** the turtle example's input surface; likely the controller's
  `cancel()` path (`userInputController.lua`).
- **State:** Pressing `Esc` empties the input buffer but leaves the
  terminal open. This is the opposite of the editor's own `Esc` behaviour
  (below), so the two surfaces disagree on what `Esc` means.
- **Why it stands:** Intent unverified; may be deliberate (clear-in-place
  to retype) or incidental.
- **Revisit:** Characterise the intended `Esc` semantics for the input
  surface and reconcile with the editor's behaviour; decide whether they
  should converge.

### Editor input buffer not cleared on Escape

- **Where:** the editor input buffer.
- **State:** After Escape in the editor, the buffer retains its content
  rather than emptying. A fix was believed to exist at one point but is not
  present in the current tree — may live elsewhere or may never have
  landed.
- **Why it stands:** Unconfirmed whether this is a regression or a
  missing fix; needs a history search before filing as a defect.
- **Revisit:** Search history for the believed fix; if genuinely absent and
  reproducible, file as a defect.

### tixy shift+click example-sequence behaviour unclear

- **Where:** the tixy example project, running.
- **State:** Shift+click is expected to advance through the built-in
  example sequence, but the intended order is not obvious from the UI and
  may not match expectations. Observed once; not reproduced or
  characterised.
- **Why it stands:** Uncharacterised; may be a UX wrinkle in the example
  rather than an input-API defect.
- **Revisit:** Investigate before the input surface is considered stable
  for project authors; characterise reproducibly, then decide defect vs.
  expected.

### Touch delivery is not black-box expressible today

- **Where:** `tests/input/input_routing_spec.lua` — the pointer
  exclusivity block carries `pending('touch reaches the active route')`.
- **State:** Both the widget's and the route's touch handlers are no-op
  TODO stubs, so touch delivery mutates no observable state anywhere; a
  delivery probe would have to spy on method names, which the suite's own
  conventions forbid.
- **Why it stands:** No observable seam exists until a touch consumer
  lands; carrying it `pending` keeps the gap visible without a mechanism
  spy.
- **Revisit:** Green the row when a real touch consumer is wired.

### maze's Lua-command path is not black-box characterizable

- **Where:** `src/examples/maze` — the project's own `ctrl_update` /
  Lua-command dispatch.
- **State:** This path is not exercised by the input contract suite
  without loading the full project; routing to the project route in
  general is covered by other tests, but maze's own command interpretation
  is not.
- **Why it stands:** Would need project-loading scaffolding the contract
  suite does not currently have.
- **Revisit:** When example-project behaviour is next characterised as a
  body of work.

### Test-fixture standup boilerplate / naming

- **Where:** `tests/helpers/input_fixture.lua` — the module-standup
  boilerplate and the `F` table name.
- **State:** Open question whether the standup should reference exact
  bootstrap lines directly or be wrapped in a named seam, and whether `F` /
  `compy_input`-style names risk confusion with the real `compy` namespace.
- **Why it stands:** Cosmetic/ergonomic; does not affect correctness or
  coverage.
- **Revisit:** If the fixture's standup grows harder to trace, or the
  naming causes real confusion, address opportunistically.

### Force-path "does not warn" coverage gap

- **Where:** the config-suppression warning test coverage
  (`tests/input/input_widget_control_spec.lua`, the `show(): activation and reset` group).
- **State:** The suite covers "a non-forced re-show while active warns
  once", but there is no explicit assertion that the sanctioned `force`
  override path warns zero times. That guarantee is the inverse of the
  kept row and is currently only implied, not directly pinned.
- **Why it stands:** Low risk; the warn-don't-swallow guarantee is still
  covered by the kept non-force row.
- **Revisit:** Restore an explicit force-path no-warn assertion if the
  reconfigure surface evolves and the boundary needs re-pinning.

### Editor sets its input-widget cursor outside the project cursor API

- **Where:** the editor sets the cursor inside its input widget via its
  own internal path; the project-facing cursor surface is
  `compy.input.get_cursor`/`set_cursor`.
- **State:** Two code paths can move the same widget cursor — the
  editor's internal one, and the project-facing API. Not a dropped
  requirement; the question is whether the editor's own cursor-setting
  should consolidate onto the public API or stay separate.
- **Why it stands:** An open consistency call with no forcing deadline.
- **Revisit:** When the cursor API surface is next touched — decide
  consolidate-vs-separate and record it.

### Per-example internals docs still describe a retired polling idiom

- **Where:** `doc/development/internals/examples/{tixy,balloons,turtle,
  valid,repl,guess,index}.md`.
- **State:** The cross-cutting input docs (`internals/user_input.md`,
  `internals/console.md`) were synced to the current `compy.input.*`
  surface, but the per-example internals docs still carry prose and code
  blocks describing the retired `r = user_input()` poll-loop idiom. Each
  needs a real per-file rewrite, not a mechanical find/replace.
- **Why it stands:** Doc drift; does not affect running code.
- **Revisit:** A follow-up documentation pass across the example docs.

### Untracked scratch examples call removed input globals

- **Where:** `src/vadexamples/{guess,repl,turtle,tixy,valid}/main.lua` (and
  their READMEs) — git-untracked, parallel to the shipped `src/examples/`
  tree.
- **State:** These still call `user_input()`/`input_text()`/`input_code()`/
  `write_to_input()`/`validated_input()`, globals that no longer exist;
  they will fail if ever run as-is.
- **Why it stands:** Not part of the shipped example set; nobody currently
  runs them.
- **Revisit:** Migrate or delete at will; not blocking anything.

### PROPOSAL: if event-sourced held state is ever needed, it belongs to the framework

- **Status:** owner's direction, 2026-08-11. **Not a commitment**, and explicitly not this
  release; recorded so that the day someone needs it, they do not each build their own.
- **The rule it follows from** (`../decisions/input.md`, D-USAGE-SHAPE.5): a project does not
  reconstruct "what is held" from `keypressed`/`keyreleased`, nor the mouse equivalent, unless it
  is a deliberate decision taken in awareness of the drift — virtual mutable state with no path
  back to the truth, wrong after a focus change or a processing hiccup, and silently so.
- **The shape, if the need is ever demonstrated.** One **event-sourced** view maintained
  centrally by the framework and **exposed for reads** to projects — so the bookkeeping, and its
  reconciliation problem, exists once rather than per project.
- **The constraint that matters most: it stays SEPARATE from the physical polling surface.** A
  reader must always know which question they are asking — *what the event stream says is held*,
  or *what the device says is held*. The two answers legitimately differ, and conflating them is
  the "two clocks" problem this feature spent its length removing (D-ASK-THE-DEVICE, *"what it
  withdraws"*). One surface answering both, or silently switching between them, would rebuild it
  under a new name.
- **What would have to be true first.** A real consumer that cannot be served by a device poll —
  which is *not* what the example corpus showed: every held-state read in it is a "right now"
  question the device answers. Until such a consumer exists, this stays a direction.

### PROPOSAL: `compy.input.keys`, a held-state surface that hides its implementation

- **Status:** owner's proposal, 2026-08-10. **Not this release** — recorded so the shape is not
  re-derived, and because it reframes a question this feature spent a long time on.
- **The shape.** A proxy table on the input surface answering *"is this key held"*:
  `compy.input.keys.h` resolves to `love.keyboard.isDown('h')`, and the foldable names —
  `keys.shift` / `keys.ctrl` / `keys.alt` — resolve to `Key.shift()` / `Key.ctrl()` /
  `Key.alt()`, so the left/right pair folds exactly as it does in a combo string. One vocabulary,
  read the same way from a handler and from `love.draw`.
- **Why it is worth having, in evidence rather than in principle.** Every input-heavy project
  re-derives this. The keyboard example built a proxy of exactly this shape **twice** — first over
  a mirror it maintained itself, then over the framework's tracked set — `maze` wrote
  `is_shift_down()` by hand, and `turtle`, `clock` and `sapper` each spell out
  `love.keyboard.isDown` or `Key.*` at their call sites. The convergence is the argument.
- **The property that matters most: it makes polling-versus-tracking an implementation detail.**
  Today it proxies straight to the device. If a mirror populated from `keypressed`/`keyreleased`
  is ever genuinely needed, it can be swapped in **behind the same surface**, transparently to
  every project — which is precisely what a bare `keys_pressed` table could not do, because the
  table *was* the contract. D-ASK-THE-DEVICE removed a model kept beside the device; this proposal
  removes the need to ever expose which one is in use.
- **Two optional extensions, later and only if a need appears:**
  - **An enumerator** — "list every key currently held". This is the one capability a device poll
    genuinely cannot provide (you can ask about a key, not for the set), and providing it centrally
    is cheaper than each project keeping its own bookkeeping to get it.
  - **`compy.states`, a writable surface** — a project registers an arbitrary state-polling
    function under a name and gets **on/off callbacks at the transitions** of that condition,
    centrally evaluated. That generalises the held-chord gap below from keys to *any* condition,
    and moves the evaluation loop out of project machinery into the framework.

    **[Owner's remark, 2026-08-10] This half is not an input mechanism and should not be scoped
    as one.** *"State-polling can be generally useful in a wider class of situations than just
    key-state queries."* The pattern it replaces — *evaluate a predicate every frame, keep a
    boolean mirroring it, and act on the moments it flips* — is what an input-heavy project
    happens to need most visibly, but nothing about it is specific to keys: a pointer entering a
    region, a value crossing a threshold, a game predicate becoming true are all the same shape,
    and each is written out by hand today with its own mirrored flag. That is why the owner named
    it **`compy.states`** rather than `compy.input.states`, and the naming should be read as the
    scoping decision it is. It also means the mirrored-flag bug class this sprint spent its
    length removing from the framework is, in projects, a *general* pattern with no vocabulary —
    the keys case is one instance of it, not the whole of it.
- **Design questions it would have to answer, named so they are not discovered late:**
  - **Name space.** `keys.shift` means the fold, but `lshift`/`rshift` are also real LÖVE key
    names — the surface must say which names are folds and which are keys, or the two collide.
  - **Silent nil.** A proxy that returns nothing for an unknown name turns a typo (`keys.shfit`)
    into "not held", with no error, in a value used directly in conditionals. A fixed key-name
    vocabulary exists, so raising on an unknown name is available and probably right.
  - **Property or call.** `keys.shift` reads as state, which is what makes it pleasant, and also
    what hides that each read is a device call.
- **Revisit:** when a project needs held-state vocabulary that today it must build for itself —
  which, on the evidence above, is most input-heavy projects. See also the entry below, whose
  on/off transition problem the `compy.states` half of this proposal is the general answer to.
- **CONDITION — this proposal carries something for another decision, and dropping it silently
  would leave that unanswered.** D-ASK-THE-DEVICE (`../decisions/input.md`) dissolved the framework's
  tracked held-key set. It was challenged on the ground that the biggest input-heavy example had
  *independently* grown a model of the same shape, which is evidence of an unmet need. The
  challenge was examined and the decision stands: what that example's model was actually reaching
  for was **edge detection** — answered by the `isrepeat` flag the API delivers, and its own fix
  reached for no held-state at all — plus **foldable held-state convenience**, which a stateless
  device poll answers and which *this proposal* is the durable answer to.
  **So if this proposal is dropped, deferred indefinitely, or replaced by something that does not
  answer the convenience half, that convergence evidence stops being addressed and D-ASK-THE-DEVICE's
  standing should be re-examined at that point.** Recorded here rather than in a review document
  because reviews are transient and this is the condition, not the argument.

### A chord that gates a state while it is held has no vocabulary

- **Where:** the shortcuts mechanism generally (`src/controller/projectInputController.lua`,
  `find_shortcut`; `src/controller/controller.lua`, `combo_string`), and
  `doc/input_api.md`, "Choosing the mechanism: transitions,
  state, and what not to build".
- **The rule this rests on, stated because the API does not state it (owner, 2026-08-10):**
  **a combo can only reliably serve an atomic transition — a one-off shot, stateless in
  itself. It must not be used to toggle a long-lived state that depends on the combo still
  being held.** The reason is mechanical, not stylistic: a combo is serialised from its
  trigger plus the modifiers held **at that instant**, so the event that would *end* the
  state may serialise differently from the one that began it, and the ending binding is
  simply missed.
- **The two ways it bites, both real:**
  - *A modifier released first.* `keypressed['alt+h']` sets a flag; the player lets go of Alt
    before `h`, so `keyreleased('h')` serialises as plain `'h'` and the `'alt+h'` binding never
    fires. **No second binding closes it** — a modifier's own release has no expressible combo
    at all (D-COMBO-SHAPE: one trigger, so `'alt+lalt'` and bare `'lalt'` both raise).
  - *An unrelated modifier pressed mid-hold.* The guide's own flag example binds bare
    `'space'` on both channels; press Space, then press Ctrl, then release Space, and the
    release serialises as `'ctrl+space'`, missing the `'space'` clearing binding. **The
    documented pattern has the defect it is documented to solve.**
  - Both leak the same way on focus loss, where no release is delivered at all.
- **What is missing, sketched (owner, 2026-08-10):** an abstraction for *"this chord is
  currently held"* — evaluated on update, with **two callbacks, on and off**, fired when the
  condition starts and stops being true. Machinery and syntax could mirror shortcuts; only the
  integration differs — instead of one callback on an event channel, a pair on a transition of
  a *condition*. It would replace held-state `if` cascades sprawling through project code, and
  the same shape serves *"Ctrl held during a drag"*, which today every project re-derives.
- **Why it stands:** **not this release.** It is new API surface, and the feature's mandate is a
  simpler and more robust input API, not a larger one. Recorded so the idea is not re-derived,
  and so the rule above is available to anyone reaching for a combo to hold a state.
- **Revisit:** when a project needs held-chord state and the honest answer is still a poll —
  which is what the keyboard example's help overlay does today, deliberately.

### sapper's modifier click path is a touch fallback, and converting it needs the platform's help

- **Where:** `src/examples/sapper/main.lua` — the two guarded click hooks and `love.mousepressed`.
- **What it is.** Shift+press flags and Ctrl+press unlocks, each guarded as *this modifier and
  none of the other two*; the plain click hooks act only when nothing is held. **Its purpose is
  the timing** (author, 2026-08-10): on touch devices a single tap is often accidental and a
  double tap unreliable, so the modifier-held **press** is the dependable route to both actions.
  That rationale is not written in the code, and its absence already caused one wrong change.
- **The obvious conversion is wrong, and was made and reverted (2026-08-10).** Moving the two
  variants to `shortcuts.singleclick['shift+*']` / `['ctrl+*']` is faithful to the *shape* — a
  class key means exactly "this modifier set and no other" — and destroys the *purpose*: derived
  clicks are button 1 only, counted on release, resolved only after the double-click window, and
  **discarded if the pointer drifts**, which is the mechanism the press path exists to bypass.
- **What a correct conversion looks like, and the hole it still has.** Keep the press path as
  `shortcuts.mousepressed['shift+*']` / `['ctrl+*']` — on a channel *with* a trigger the class key
  falls back correctly, so this reproduces "any button, at press time" exactly — and **swallow the
  derived echo** with `shortcuts.singleclick['shift+*'] = fn.stop_here()`, because **consuming a
  press does not prevent the derived click**: the gateway counts clicks in its own
  `mousereleased` handler, before and regardless of anything the project consumed.
  **The residual hole:** a derived click's modifiers are sampled **at synthesis time**, after the
  double-click window — so releasing the modifier during that window makes the echo serialise
  unmodified, miss the swallow, reach the plain hook, and act a second time. On a touch device,
  where the modifier is a key held in the other hand, that is a realistic sequence.
- **THE HOLE IS ALREADY IN THE SHIPPED EXAMPLE — it is not a property of any conversion**
  (verified 2026-08-11). Shift+press flags the cell immediately; the gateway synthesises the
  single click **0.4 s later** (`controller.lua`, `click_delay`); if Shift is released inside that
  window the derived click serialises with **no modifiers**, passes the hook's own *"nothing
  held"* guard, and runs the action a second time — and because flagging **toggles**
  (`actionFlag` → `flowToggleFlag`), the second run **un-flags the cell**. **Net effect:
  shift-click appears to do nothing if the player lets go of Shift promptly.** A live,
  user-visible defect in the example as written, predating this feature entirely.
- **Ruling, 2026-08-15:** retain the fallback. The rare delayed echo is
  accepted without a project-side guard: the damage is negligible and a flag
  would add more machinery than it removes.
- **Revisit:** only if user reports show the echo is material. A platform
  change preserving the originating press's modifiers remains outside this
  feature's scope.

### Modified shortcut families need explicit fall-through policy

- **Where:** project `compy.input.shortcuts` beside ordinary hooks or captured
  `love.keypressed` / `love.textinput` handlers.
- **State:** shortcuts match one exact modifier set. A project that wants a
  shortcut family to claim every modified form must register every meaningful
  and meaningless combination; otherwise an unclaimed combination reaches its
  ordinary keyboard or text-input handling.
- **Why it stands:** the explicit registrations make every claimed combo
  visible, but example grooming has shown that redundant no-op combinations
  quickly become noise.
- **Revisit:** after embedded-example grooming. Evaluate an opt-in wrapper
  such as `compy.input.fn.if_no_modkeys(fn)` that suppresses an event whenever
  a modifier is held, against the risk of hiding a deliberately modified input.

### Examples are not onboarded onto the new input API

- **Where:** `src/examples/{maze,keyboard,turtle,clock}` — the sites listed
  below. The three detached repos (`keyboard`, `maze`, `balloons`) have
  their own remotes and no test suite; `balloons` reads no held state at
  all and appears nowhere here.
- **State:** The examples were reconciled with the removal of the tracked
  held-key set and with the guide's recommendation ladder
  (`doc/input_api.md`, "Held keys"): every read now sits at a rung that is
  correct rather than one that is gone. Several of them are still a rung
  below the one the API offers — a poll answering a question `shortcuts`
  answers directly, or a modifier test that is a combo written out. Each
  conversion below was **considered and declined during the reconciliation**
  because it is a behaviour change, a control-flow restructure, or both, in
  a repo where the only gate is running the app by hand.
- **The sites, and what each would become:**
  - `maze/main.lua:568` — `k == "escape" and not Key.shift()` inside
    `love.keypressed` is two bindings: Shift+Escape quits, bare Escape is
    ignored. The combo form moves `escape` out of `SYSTEM_KEYS` and depends
    on shortcut-before-hook ordering.
  - `maze/main.lua:514-526` — `poll_tab_progression` polls `tab` every
    frame and keeps a `tab_was_down` mirror to derive an edge;
    `shortcuts.keypressed['tab']` is the edge. It also carries the bug
    class the platform just removed: a flag mirroring a key, with nothing
    to reconcile it. The edge feeds two different actions depending on
    game state, so the restructure is not a one-liner. **A bare-key combo
    is legal** — modifiers are optional and only a bare `'*'` is refused —
    **but it narrows the trigger, and that is a behaviour change to state
    rather than discover.** The poll fires on Tab whatever else is held;
    a `'tab'` binding is an exact match on the serialised combo, so
    Ctrl+Tab and Shift+Tab serialise as `'ctrl+tab'` / `'shift+tab'`,
    miss it, and fall through to the hook. Probably an improvement here —
    a stray modified Tab should not skip a level — but it is a decision,
    not a detail.
  - `maze/macro.lua:74,89` — `macro_state.shift_held` is a held-modifier
    mirror maintained across `keypressed`/`keyreleased`, the same shape.
    **Listed by adjacency, not by the same trigger as the rest:** it reads
    no device and never touched the framework's set — the flag is set from
    the event's own key name against a static table (`SHIFT_KEYS`) — so it
    was outside the reconciliation's mandate and is here because it is the
    pattern that mandate kept meeting. It is also not a pure read: the
    release runs `finish_recording()`, so replacing the mirror with
    `Key.shift()` is not behaviour-preserving on its own.
  - `keyboard/alt.lua:203` — `k == "h" and INPUT.ctrl and INPUT.alt`
    hand-matches the combo its own comment calls "Ctrl+Alt+H". Its natural
    form is a shortcut registration; the scene's key routing is what the
    `textinput` heal rewrites, so it waits for that.
  - ~~`keyboard/help.lua:16-19`~~ — **RESOLVED 2026-08-11: the poll is
    correct and stays.** This entry previously called the flag-shortcut shape
    its top rung; the usage principles invert that. The overlay is up while a
    chord is *held*, which is continuous state, and a mirrored
    press/release pair cannot close reliably here at all — a modifier's own
    release has no bindable combo. See `doc/input_api.md`, "Choosing the
    mechanism".
  - `keyboard/input.lua:109` — `isMod` re-implements `Key.is_mod`. Not a
    held-state read, so outside the reconciliation's sweep, but the same
    duplication: it is used in `alt.lua`, `findkey.lua` and `hunt.lua`.
  - `turtle/main.lua:34` — `Key.shift()` inside `love.keypressed` guards
    `shift+r`. It remains because turtle demonstrates captured callbacks.
  - ~~`clock/main.lua:69,78`~~ — **RESOLVED 2026-08-11 by deciding not to
    convert, with the reason written into the file.** `space`,
    `shift+space` and `shift+r` name themselves like combos, but a
    shortcut matches its modifier set exactly, so a `'space'` binding
    would stop firing while any unrelated modifier is held, where the
    hook fires regardless. The narrowing is invisible in the diff that
    would introduce it and nobody asked for it.
- **Why it stands:** Deliberate scope. The reconciliation's mandate was two
  named platform changes; converting an example to the API's better shape is
  a different job, and doing both at once turns a reconciliation into a
  rewrite. Nothing here is broken — each site works as written.
- **Revisit:** This section is the work list for the example onboarding work
  that follows, which reads it entry by entry. That work is split by weight:
  the in-repo examples are a sweep, while `keyboard` and `maze` each get their
  own pass, since each holds conversions that need planning rather than
  applying. A site may be declined again with
  fuller reasoning; what it may not do is disappear silently.

### `compy.input` is built once for the application, not per project run

- **Where:** `src/controller/consoleController.lua` — `get_compy_input()` runs
  inside `prepare_project_env`, which `ConsoleController.new` calls **once**, at
  construction. Every project run therefore shares one surface and one private
  `state`. Env cloning does not separate them either: `table.clone` copies the
  surface's metatable, and that metatable closes over the same `state`.
- **Corrected 2026-08-26.** This entry previously claimed the opposite — *"the
  function that builds `compy.input` is called every time a project environment
  is prepared"* — and accepted the debt on that premise. The call graph
  contradicts it, and the wrong premise closed the question: it is what made an
  application-lifetime store look run-scoped, which is how the hidden-`configure`
  draft came to survive a project stop (fixed; see `internals/user_input.md`,
  *`configure(config)` — the live-reconfigure surface*).
- **Disposition:** Accepted, no action expected — but for a different reason than
  the one recorded before. The `show`/`hide` closures resolve the live widget at
  call time, so a build-once surface still reaches the current widget. What the
  arrangement costs is that **every store the closure owns outlives every
  project**, so anything run-scoped must live on the widget (where teardown
  reaches it) rather than in `state`. `callbacks` and `pending` both do;
  `shortcuts` and `hooks` are wiped by name at teardown instead.
- **Revisit:** if a third run-scoped store is ever added here, prefer moving the
  whole `state` to a per-run lifetime over adding a third teardown arrangement.

### Console debug hotkeys are ad-hoc `if`-navigation

- **Where:** `src/controller/controller.lua`, `set_love_keypressed` — the
  `Ctrl+Shift+<n>` / `Ctrl+Alt+d` debug toggles are a nest of `if k == …`
  branches ahead of the route forward.
- **State:** These branches are exactly the shape combos exist to replace —
  falsey-return, fall-through participants keyed on a serialised combo. They
  predate the combo mechanism and were left in place.
- **Why it stands:** Cosmetic; the branches work and run only under
  `love.DEBUG`. Not worth a behavioural change on its own.
- **Revisit:** When this handler is next touched — lift the debug toggles
  onto the combo-table mechanism (D-COMBO-TABLES), or a `toggle_debug(k)` helper.

### Per-event `set_love_*` installers are lexically isomorphic

- **Where:** `src/controller/controller.lua`, `set_default_handlers` — ten
  near-identical `Controller.set_love_<event>(CC)` calls, each backed by an
  equally near-identical `set_love_<event>` installer.
- **State:** The installers differ only by event name; the repetition invites
  a table of per-event entries driven by one iterator. Flagged inline as a
  code-hygiene concern, not a correctness one.
- **Why it stands:** The explicit form is readable and predates this note;
  collapsing it is a refactor with no behavioural payoff.
- **Revisit:** If the installer set grows or is next restructured — drive it
  from a `{ event → installer }` table.

### Discovered, de-facto behaviours pinned during the un-fork (rationale note)

The un-fork's preservation tests froze several behaviours that are **not designed
contracts** but were **discovered as existing behaviour with no mandate to alter**
— treated as de-facto standards per the implementation and pinned so they can't
be silently narrowed later (any change is a separate, owner-gated decision):

- **Non-shift Enter submits** — Ctrl+Enter and Alt+Enter submit, not only bare
  Enter (guard is `is_enter and not shift`; also consistent with
  `doc/development/decisions/input.md` D-NO-FW-TIER). Pinned for widget + console.
- **`SearchController:keypressed` returns a jump target** (`{block, line}`) up its
  caller on Enter — the same "keypress return carries a domain result" shape the
  shared widget's limit-flag return was retired for (D-TWO-SURFACES). Left as
  is because `SearchController` is a different class, out of scope here.
- **The project widget's view skips the per-frame `update_view()` workaround by
  widget *identity*** (`userInputView.lua:draw`, `self.controller ~=
  love.state.user_input_controller`) — an identity check standing in for the old
  `oneshot` flag. Its survival under a console/editor re-plug remains a
  tracked future concern, out of the input API's scope.

### paint's `useCanvas(btn)` means a mouse button on one path and a click count on the other (pre-existing)

`src/examples/paint/main.lua` calls `useCanvas(x, y, btn)` from two places, and `btn` means
something different in each:

- **the drag path** — `compy.input.hooks.mousemoved` polls `love.mouse.isDown(btn)` for `btn = 1, 2` and
  passes the held button through. Here `btn` is a real LÖVE mouse button.
- **the click path** — `point(x, y, btn)`, reached from `hooks.singleclick` and
  `hooks.doubleclick`. Here the number is **paint's own action selector, written as a literal
  in each binding**: `1` for the primary gesture, `2` for the secondary. The framework passes
  the two hooks `(x, y)` and nothing else — no button, no count — so nothing hands paint a `2`
  to misread. Paint picks it.

So the function reads as button-aware, and half its callers cannot supply a button.

**This is not a case of a receiver misinterpreting a value it was sent** — the question is
worth stating because the coincidence invites it. `doubleclick` does not deliver "button 2";
it delivers `(x, y)`, and paint's handler body chooses to call the secondary action `2`. Had
the framework been passing a click count into a button parameter, that would be a defect; it
never did, at the PR base or now. What is left is a latent trap: one parameter, a real LÖVE
button on the drag path and a hand-picked constant on the click path, with the two meanings
agreeing by luck (`2` = "secondary" in both readings). The
consequences a user meets: right-**drag** on the canvas paints with the background colour,
right-**click** does nothing, and double-click paints with the background colour — one effect,
two unrelated gestures, plus a third gesture that looks like it should work and does not. The
same conflation runs through `setColor`, whose `btn > 1` branch is reachable only by double
click, so "secondary colour" is bound to double-click rather than to the secondary button.

**Pre-existing, not a migration artefact.** At the PR base (`3256aac`) the drag path is
byte-identical and the click path bound `compy.singleclick` / `compy.doubleclick` with the same
hardcoded 1 and 2. This feature renamed the bindings (`compy.X` →
`compy.input.hooks.X`) and changed nothing about the meaning.

**Why it cannot simply be fixed by binding the button.** The derived clicks name no button by
ratified decision (`../decisions/input.md`, D-BUTTON-TRIGGER, "The derived clicks keep `(x, y)` and
name no button"): they are not LÖVE events and the click timer synthesises them from
left-button releases only. A project that needs to know which button produced a click binds
`mousereleased` and does its own timing — which is exactly what the framework's timer does on
the project's behalf for the left button.

**Ruled not to change paint (owner, 2026-08-07):** the example never intended a secondary-button
gesture, secondary-button availability is not uniform across environments, and mapping the
secondary action onto a double-click may well be deliberate. Recorded because the parameter's
double meaning is a trap for the next person to edit this example, not because the behaviour is
wrong today.

**Recommendation, for whenever paint is next opened.** Nothing here is urgent — the example
works, and this is about how easy it is to keep working.

1. **Name the two layers.** `1` and `2` appear as bare literals in the two click bindings and
   again as branch conditions in `setColor` and `useCanvas`, so the meaning lives in the
   reader's head rather than in the code. `local FOREGROUND, BACKGROUND = 1, 2` — or better, a
   value that cannot be confused with a button at all, such as the strings `'fg'` / `'bg'` —
   makes each site say what it does. This is the cheap half and it removes most of the risk on
   its own.
2. **Stop using a button number as the layer identifier.** Even named, `btn` is fragile
   precisely because one of its two call paths really is a LÖVE button: a future edit that
   passes a genuine `3` (middle click) or that reads `btn` as a button on the click path will
   be wrong in a way nothing catches. Splitting the parameter — the drag path translating the
   held button into a layer before calling — keeps the button at the edge, where it belongs.
3. **A modifier may be the better metaphor for "background".** Ctrl-draw or Alt-draw is a
   conventional secondary-action gesture, it reads the same on a trackpad and on hardware with
   no reliable second button, and the input API expresses it directly:
   `shortcuts.mousepressed['ctrl+mouse1']` is a ctrl-click and `shortcuts.mousemoved['ctrl+*']`
   a ctrl-drag (`../decisions/input.md`, D-BUTTON-TRIGGER). That would also let double-click go back
   to meaning something double-click-shaped, instead of standing in for a button paint cannot
   observe.

Points 1 and 3 are independent: naming the layers is worth doing even if the gesture never
changes.

### A modifier accessor answers truthy/falsy, not a boolean

- **Where:** `src/util/key.lua` — `ctrl`/`alt`/`shift` return
  `love.keyboard.isDown(...)` straight through, and are annotated
  `@return boolean`. Real LÖVE honours that; the annotation is **not enforced**
  for anything that replaces `isDown`.
- **The one known offender is fixed (2026-08-16).** Harmony's lock-mode patch
  used to fall off its own end for an unheld key, returning **no value** rather
  than `false`, and Lua adjusts that to `nil` at a call site. It now returns a
  boolean on every path (`src/harmony/init.lua`, `patch_isDown`), on the ground
  that a mock matches the signature of the thing it mocks. What remains is the
  general exposure below, not a live instance.
- **State:** harmless to every `if Key.ctrl() then` in the tree, since `nil` and
  `false` are both falsy. It bites the moment a device read is **compared**
  rather than tested: `Key.ctrl() == false` is `false` under harmony, and
  `Key.ctrl()` spliced as a call's last argument contributes **no argument at
  all**. The live exposure is the second, at six call sites that pass a modifier
  read as a trailing argument (`editorController.lua:466,470,772,776`,
  `searchController.lua:101,105`), none of which is affected today because the
  callee only tests the value for truthiness. The comparison form was observed
  once, in the gate's `only_mods` helper, which normalised with `not not`; that
  helper no longer exists (D-RESERVE-TABLE replaced the predicate cascade with a
  combo-string table), so **no site in the tree compares a modifier read today**.
- **Why it stands:** nothing is wrong under a real device, no patcher offends
  today, and no caller compares. Changing the accessors is a small edit with a
  wide blast radius — every caller's return type would become guaranteed, which
  is desirable but wants its own pass and its own tests.
- **Shape, if it is answered:** normalise inside `Key` — `return not not
  love.keyboard.isDown(...)` in each of the three accessors — so the
  `@return boolean` annotation becomes true for every consumer, and no future
  caller has to remember `not not` to compare safely.
- **Revisit:** when `Key`'s accessors are next touched, or the first time a site
  compares a modifier read rather than testing it.

### Console and editor route handlers bind by hand-written modifier tests

- **Where:** `editorController.lua` (~33 tests), `searchController.lua` (5) and
  `consoleController.lua` (4) — `if Key.ctrl() and not Key.shift() and not
  Key.alt() and Key.is_enter(k)`, and the same shape for Escape, paste, scroll
  and the debug toggles. Six further reads are **not** this debt: `_scroll('up',
  Key.ctrl())` passes a held modifier as continuous state, which D-USAGE-SHAPE
  rules correct.
- **State:** these are combos written the long way, at the one layer the feature
  did not convert. Two costs, and the second is the live one:
  - **Nothing can list them.** A combo table is enumerable — that is why the
    input guide can print what the platform reserves. A cascade of `if`s can
    only be read.
  - **Each test claims every modifier it does not name.** The editor's `load()`
    tests Ctrl and Shift but not Alt, so **Alt+Escape loads the selection**; the
    console's `if Key.ctrl() then if k == "l"` makes **Ctrl+Shift+L and
    Ctrl+Alt+L clear the output**. This is exactly the tolerance D-EXACT-RESERVE
    outlawed for the pre-dispatch gate, still present one layer down — and the
    same handlers write the exact form (`not Key.shift() and not Key.alt()`)
    elsewhere, so the inconsistency is within a single file.
- **Why it stands:** no project competes for these keys — the console owns the
  route precisely when no project runs — so nothing is broken today, and
  D-EXACT-RESERVE's scope clause deliberately left this layer out. It is soft debt:
  a consistency and legibility cost, not a defect.
- **Shape, if it is answered:** register these as combo tables on the
  controllers, the way a project registers its own. That is the console/editor
  adoption D-ROUTE-OWNS defers, and it subsumes the debug-toggle entry above.
- **Revisit:** with the console/editor migration, or the first time one of these
  handlers has to state what it claims — a tolerant test is invisible until a
  chord that extends it is wanted.

### A gesture that tolerates a modifier costs one registration per variant

- **Where:** `compy.input.shortcuts` and the combo grammar (`src/util/key.lua`,
  `split_combo`/`check_combo`). A combo is its modifier set **exactly**
  (D-COMBO-SHAPE), and the `'*'` class key is a class of one modifier set too —
  `'alt+*'` does not match `alt+shift+key`.
- **State:** a project that wants *"Ctrl+Alt+Up, and I do not care whether
  Shift is also down"* must register `ctrl+alt+up` **and**
  `ctrl+alt+shift+up`. `examples/keyboard` needs six such tolerant gestures
  and pays **twelve** registrations for them (`input.lua`,
  `register_reserved`). Nothing is broken by this and every binding is
  explicit, which is the model's virtue.
- **Why it is written down (2026-08-12):** the cost is not the typing, it is
  that *a missing variant is silent and looks exactly like the code being
  right*. Converting this one example's hand-written modifier tests to combos
  dropped **six** gestures; four were caught by one cold review, the fifth by
  a second, and the sixth by a third — each time after a fix for the previous
  one had been written by someone who had just read the rule and the bindings
  together. That is three independent reviews to converge on one file's
  twelve lines, and the register should say so before the next project
  migrates.
- **Shape, if it is ever answered:** a tolerance marker in the combo grammar
  (something like `'ctrl+alt+shift?+up'`), or a registration helper that
  expands one gesture into its variants. **Neither is proposed here** — the
  explicitness of the current model is a deliberate property and a tolerance
  syntax trades it away.
- **Revisit:** when a second project hits it, or when the input guide gains
  its reserved-combo section (P10) and has to explain the double binding
  anyway.

## RETIRED

### The guide and the CHANGELOG carried a migration from an `eval` key no project could write (RESOLVED, 2026-09-03)

- **Where:** `../../input_api.md`, *"Migration from the legacy globals"* (two rows) and
  `../../../CHANGELOG.md`, the closed-config-table bullet (*"the retired `eval` and `result`
  keys"*).
- **State:** neither was ever a key of `compy.input.show` or `configure`. **No commit made one** —
  `git log -S"'eval'"` and `-S"'result'"` over `consoleController.lua` are both empty — and at the
  PR base the evaluator was chosen by *which global you called* (`input(InputEvalLua, prompt,
  init)`), never passed in: no example writes `eval =`, and the config table a project could reach
  did not exist yet. The names are **internal**, from the pre-feature implementation and the design
  discussion — the evaluator object, and `input_ref` passed as *"the `result`"*
  (`design/notes/decisions.md`) — restated in two project-facing documents as though they had been
  project keys. A migration row for a shape nobody could have written is worse than silence: it
  tells a reader they may have used it.
- **Owner's question is what settled it** (2026-09-03): *"I do not think it was used and not sure
  where it came from. Can we check if it was in the original requirements or grew spontaneously?"*
  **It grew spontaneously.** The frozen `design/spec.md` names `validator` / `highlighter` as the
  project-facing configuration and never an `eval` key, and its own migration table maps
  `input_text(prompt, init)` to `validator`, not to an evaluator.
- **Resolution.** Both rows dropped from the guide; the clause dropped from the CHANGELOG. The
  raise itself is unaffected and undocumented on purpose — the config table is **closed**, so `eval`
  raises like any other unknown key, without being advertised as a retired one.
- **What was checked and correctly stays:** the `| result = ... |` row in the same table. `result`
  is not a config key either, but it *was* project-visible — `user_input()` and `input_text()`
  returned `input_ref` and a project polled it (`turtle/main.lua:51` at base, `r =
  input_text("TURTLE")`). That row migrates from something real, and the entry above it is exactly
  the reason to check each row rather than sweep the table. The caution paragraph naming the
  evaluator globals stays too: those are real globals, and the row above it mentions
  `LuaHighlighter`, so a porting reader can plausibly reach for one.
- **Provenance: introduced in this branch.** Both documents are the branch's own — there is no
  `CHANGELOG.md` and no `doc/input_api.md` at `3256aac`.

### A project cannot read the widget's content except at submit (RESOLVED, 2026-09-03)

**Filed as `T-CONTENT-READ`.** Everything down to **Resolution** is the filing as written.

- **Where:** the `compy.input` surface — `consoleController.lua`, `build_widget_api`. It exposes
  `show`, `hide`, `is_shown`, `get_cursor`, `set_cursor`, `set_text`, `clear` and `configure`, and
  **no reader**. Content reaches project code only through `on_text_entered` and `after_submit`,
  both inside `UserInputController:submit_flow` (`userInputController.lua`); `cancel_flow` delivers
  nothing.
- **What is owed:** `compy.input.get_text()`, read-only, symmetrical with `get_cursor` — `nil`
  while hidden rather than a warning, because a read of *"nothing to report"* is not a refused
  mutation, the rule `get_cursor` already follows (`../internals/user_input.md`, *"Cursor
  manipulation and \"reset\""*). It is an **addition to the public surface**, so it owes its guide
  entry and a CHANGELOG line with the function itself, and `doc/input_api.md`'s `hide()` section
  currently discloses the gap and stops being true when this lands.
- **Why it is an entry:** a **self-describing gap in a shipped surface** — no decision produced it,
  and the decision it bears on (`../decisions/input.md`, **D-CFG-BOUNDARY**) rests on it being
  small. That ruling retired the ratified requirement that content survive `hide` → `show`, on the
  ground that a project which ever needs it can keep the content itself. **That fallback covers the
  cursor and not the text:** `get_cursor()` exists, so the caret round-trips and the content does
  not. The ruling's own evidence is unaffected — the two `hide()` call sites in the tree
  (`maze_main.lua:126`, `draw_main.lua:233`) both abandon the prompt for a menu and *want* the
  clearing — so the gap is in the fallback offered as consolation, not in the decision.
- **Why ACTIVE, and it was BACKLOG until 2026-09-03.** Filed 2026-09-02 as *"PROPOSAL: a read-only
  content getter — the half of the save-it-yourself fallback that does not exist"*, unslugged and
  explicitly not a commitment, on the reasoning that no consumer had asked. The delivery
  revalidation then found the guide instructing an author to *"keep it yourself"* — advice the
  surface does not permit — and escalated whether the release closes the gap or documents it. **The
  owner ruled it release scope** (2026-09-03): *"write it as active technical debt to be resolved
  before release; disclose the gap but mark it as defect fixable with getter until ruled
  otherwise."* So the disclosure in the guide stands as the interim state and this is the fix.
- **The consumer is not the hide/show case** (owner, 2026-09-02). Today a project learns the
  content only at **submit** — that one moment is the entire read surface. A getter is what it
  needs to read at a moment of *its own* choosing: **on a timeout** (take whatever has been typed
  when the clock runs out), or **from a process the project launched itself**, e.g. off a hotkey,
  that wants the current text without making the user submit first. That is a more ordinary shape
  than restoring a draft across a hide, and sizing this from the hide/show framing under-prices it.
- **And explicitly not the alternative.** Restoring preservation across `hide` → `show` is a
  content-**lifetime** rule that every call seating content would have to agree with; a getter is
  one function that adds no rule. This is paid as the getter.
- **It is a class, not an instance — three earlier mentions, none of them an entry.** The absence is
  cited as a *supporting fact* inside `set_text`'s list branch does not split embedded newlines
  (*"nothing could read it back … so there is no set/get round-trip"*), inside the `oneshot` →
  `auto_hide` entry (*"nothing could read that draft back first"*, an entry `LEDGER-02` is scheduled
  to vacuum), and in the roadmap's `BUG-02-01` row. Three unrelated routes reached the same missing
  function and each treated it as background.
- **Roadmap:** `FEAT-03`.

- **Resolution.** `compy.input.get_text()` shipped the same day it was filed, `FEAT-03`. Five
  breaking tests first, each seen to fail with *"attempt to call field 'get_text' (a nil value)"*;
  suite 1050 → **1055**. It answers **one string** with `\n` between lines — `on_text_entered`'s
  spelling, and the one `set_text` takes back unchanged, so it round-trips without naming a type the
  guide does not have and hands a project no internal object (`after_submit`'s `InputText` was the
  alternative and was declined for that reason). `''` when the widget is up and empty, `nil` while
  hidden, silently: the pair lets a project tell *nothing typed* from *nothing to report*. Documented
  in `../../input_api.md` (the surface list, *"Live changes"*, and the `hide()` section, which now
  carries the worked save-and-restore example instead of advice a project could not follow) and in
  `../internals/user_input.md`; `Added` line in `CHANGELOG.md`. **The three restatements of the
  absence were swept with it** — `../decisions/input.md`'s `D-CFG-BOUNDARY`, which now describes the
  whole fallback rather than half of one, this file's `set_text` list-branch entry, and the
  roadmap's `BUG-02-01` cell; the two register sites are past-tensed rather than deleted, because
  each was true when its argument was made.

### The class diagrams show a model field that no longer exists (RESOLVED, 2026-09-02 — and the premise was half wrong)

**Filed as `T-MERMAID-MODEL`.** Everything down to **Resolution** is the filing as written.

- **Where:** `../mermaid/input.md`, `../mermaid/editor.md`, `../mermaid/classes.md` — the
  `InputModel` / `UserInputModel` class blocks.
- **State:** all three list `oneshot: boolean` as a model field. It is **gone**: at the PR base
  it was a constructor argument (`UserInputModel.new(cfg, eval, oneshot, custom_label)`)
  distinguishing the transient prompt widget from the console's permanent one, and this feature
  removed it — `new(cfg, eval, custom_label)` today. The `auto_hide` key that replaced the
  *capability* lives on the **controller**, not the model, so the diagrams do not merely use an
  old name; they show a field on the wrong class. `custom_label`, a live field, is missing from
  the same blocks.
- **Why it stands:** the diagrams were never re-checked against the model after the input work.
  The drift is presumed wider than the one field — nobody has walked them — so the row is
  *verify all three against the current classes*, not *delete one line*.
- **Reader risk:** a diagram is what someone opens **before** reading code, and it carries no
  hedge. A field shown there reads as current in a way a stale sentence does not.
- **Resolution — `FIX-02-24`. The diagrams are marked historical, not corrected.**
  Was `T-MERMAID-MODEL`. Owner's call: *"if it's not the live doc and never was, maybe we should
  not update it, just mark (historical)?"* `doc/mermaid/README.md` carries the reasoning and each
  of the seven files got a one-line banner. No diagram content was rewritten.
- **The premise this entry was filed on does not survive the check.** It reads *"the model lost
  that constructor argument in this feature"* and *"the diagrams show a field on the wrong class
  rather than an old name"*. `InputModel` — the class carrying `oneshot` in `classes.md` and
  `input.md` — **did not exist at the PR base `3256aac` either**, together with
  `InterpreterModel`, `InterpreterController`, `InputController`, `InputView`, `InterpreterView`,
  `EvalBase` and `EditorInterpreter`. The diagrams are `aldum`'s — four added 2024-07-29 and
  three (`eval.md`, `input.md`, `scratch.md`) on 2024-12-18 as *"unfinished docs"* — and last
  meaningfully updated 2025-01-13. They were stale a year before this feature began.
- **Exactly one line of 32 class blocks was ours**, and it is deleted: `editor.md`'s `oneshot` on
  `UserInputModel`, a live class whose field did exist at base. A historical marker excuses
  inherited drift, not drift you caused. `custom_label`'s absence, `evaluator: EvalBase` and the
  `wrapped_error`/`error` conflation were each checked against base and are identical there.
- **Evidence:** a field-by-field audit of all seven files, 32 class blocks
  ([`../wip/77-new-input-api/validation/outcomes/S67-mermaid-audit.md`](../wip/77-new-input-api/validation/outcomes/S67-mermaid-audit.md)).
  It also found the source-annotation drift now recorded in `general.md`, and that `eval.md`'s
  section headed *"Current"* describes a hierarchy never built while its *"Planned refactor"*
  section is closer to what shipped — which is the argument for keeping these files intact:
  they are the record of intent, and a correction pass would have deleted it.

### The guide never says a project's own keys stay live while the widget is shown (RESOLVED, 2026-09-02)

**Filed as `T-GUARD-LIVE`.** Everything down to **Resolution** is the filing as written.

- **Where:** `../input_api.md` — the `is_shown` paragraph, and *"Why the
  widget sits at tier 3"*.
- **State:** the guide documents the **mechanism** (three consumers, tried in
  order, the shown widget always consumes at tier 3) and one **case** —
  guarding the trigger key so a later press does not re-open the prompt. It
  never states the consequence that falls out of the two: while the widget is
  shown, a project's *unrelated* keys are still live, because tier 2 runs
  above it. An unguarded native handler acts on the keys the user is typing —
  a space toggles a mode, a capital `R` moves the world — and the event still
  reaches the widget, so nothing looks wrong from either side. **The remedy —
  an early return on `is_shown()` covering the whole handler — is never named
  either**, though the suite pins it as the idiom
  (`tests/input/input_widget_control_spec.lua`, *"the guard the ruling asks an
  example to write"*).
- **What is NOT missing, corrected 2026-08-30:** an earlier draft of this entry
  claimed the guide never says a framework reservation is beyond a project's
  reach. It does — *"Combos the framework keeps"* says a reservation is
  answered before the project's route exists and cannot be overridden, and
  tables `ctrl+pause` with the rest. The entry is narrower than first written:
  what is missing is the *consequence for a shown widget*, not the
  reservation rule.
- **Why it stands:** `turtle` shipped unguarded for months (`T-TURTLE-DUP`),
  and a reader of the guide alone would not have known to write the guard that
  fixed it.
- **Resolution — `FIX-02-23`, and it is prose.** Was `T-GUARD-LIVE`.
  `../input_api.md`'s `is_shown` paragraph now states the consequence (hooks sit
  above the widget, so an unguarded handler acts on the user's typing while the
  widget is shown), names the remedy (an early return on `is_shown()` covering
  the **whole** handler), and distinguishes it from the narrow guard on the key
  that opens the widget — two guards, two jobs.
- **The reassurance is pointed at rather than restated**, as this entry's own
  2026-08-30 correction asked: *"Combos the framework keeps"* already says a
  reservation is answered before the project's route exists.
- **One mechanism error was caught in the drafting and is worth keeping.** The
  first draft said the platform's combos survive a blanket guard because they
  never reach the project's handler. It is the other way round: a reservation
  **acts and passes the key on**, never consuming, so what survives the guard is
  the platform's action and not the project's binding. The guide uses
  `ctrl+escape` as the example because it is the one reservation marked
  *"always"* rather than development-only.

### The set of accepted config keys has no single home (RESOLVED, 2026-09-02)

**Filed as `T-KEYSET-SPLIT`.** Everything down to **Resolution** is the filing as
written, present tense and all — *"No such test exists"* was true when it was
written and is the record of why the work was scheduled. The Resolution bullets
are what happened.

- **Where:** `consoleController.lua` decides what `show` / `configure` **accept**
  (`CALLBACK_KEYS`, `WIDGET_KEYS`, and the `CONFIGURE_KEYS` / `SHOW_KEYS` sets
  built from them); `userInputController.lua` decides what they **apply**
  (`CONFIG_CALLBACKS` and the named branches at the top of `configure_core`).
  Nothing ties the two sides together.
- **State — one real duplication and one weaker coupling, and they are not the
  same defect.** `CALLBACK_KEYS` and `CONFIG_CALLBACKS` are two lists holding
  the same four strings — `validator`, `on_text_entered`, `on_limit_reached`,
  `highlighter` — maintained separately, each for its own job: the first backs
  the sticky `state.callbacks` store the surface merges from
  (`merge_callback_keys`), the second assigns onto the widget's own
  `self.callbacks`. `WIDGET_KEYS` against `configure_core` is **membership
  duplication, not list duplication**: `prompt` and `auto_hide` reach
  *different destinations* (`model.custom_label`, `self.auto_hide`), so there is
  no list to share — only the fact that both calls take them.
- **Why it matters: the failure is silent and one-directional.** A key added to
  the accept side alone is taken by the surface and ignored by the widget, with
  no raise and no warning — the config table is strictly validated against a set
  that does not know what the widget implements. That is a drift source, and it
  is the same family as `FIX-02-08`/`-09`: one fact stated twice, with nothing
  reconciling the statements.
- **It has already drifted in the way that counts** (2026-08-31). Not the
  values, which have never diverged, but the *shape*: `FEAT-02` had to add an
  entry on each side for `auto_hide`, and the entry that should have caught it
  said only *"revisit when either list changes"* — a trigger that fires only if
  someone remembers to look.
- **The fix is a test, not a refactor** — deliberately, and the refactor is
  named here as the thing not being done. Unifying the lists means one module
  importing the other's across the surface/widget boundary the architecture
  keeps separate, which is a larger change than the defect and reads worse on
  review than the duplication does. Instead: **assert that every key the surface
  accepts is a key the widget applies.** No such test exists — each key is
  covered behaviourally and individually, and nothing asserts the *set* is
  closed. A few lines, no behaviour change, and it turns an invisible coupling
  into an executable one.
- **Resolution — `FIX-02-25`, and it is a test.** Was `T-KEYSET-SPLIT`.
  `tests/input/input_config_key_agreement_spec.lua` **reads the real accepted
  set out of the surface** — `show` → `api_show` → `SHOW_KEYS`, and the
  `configure` equivalent, by upvalue and by name — and requires every member
  to carry a proof there that the key reaches the widget. A third hand-written
  copy of the list was rejected for the reason this entry exists: it cannot
  fail on a key it does not know about, which is the whole defect.
- **Mutation-tested in both directions.** Adding `'ghost'` to `WIDGET_KEYS`
  with no `configure_core` branch fails both cases naming the key; renaming
  `SHOW_KEYS` fails with *"upvalue SHOW_KEYS is gone; fix this reader"*
  instead of silently checking an empty set. That second one is why the reader
  asserts rather than returning nil.
- **No production defect was found.** The two sides agree today, so nothing was
  changed: the row allowed for a divergence and there is none. What is fixed is
  that the next divergence cannot be silent.
- **The refactor named here is still not done, deliberately** — unifying the
  lists remains the larger change this entry rejected.

### A citation edit left half a sentence asserting the opposite of the statement it cites (RESOLVED, 2026-09-02)

- **Where:** `tests/input/input_widget_callbacks_spec.lua`, the `auto_hide` block's
  raise case.
- **The defect:** `d0f4e66c` re-pointed *"D-AUTO-HIDE, ruled edge 4 -- the one REVERSED
  from the entry's own recommendation"* onto the numbered statement, and stopped at the
  clause boundary. What stood afterwards was *"statement 5 -- the widget survives a
  raise; entry's own recommendation."* — a fragment reading as a claim that statement 5
  **is** the entry's recommendation, when the entry's recommendation was the opposite
  and its reversal is exactly the churn `D-AUTO-HIDE`'s rewrite retired. Silent: the
  comment is prose, the case passes either way.
- **Resolution:** the fragment removed and the block rewrapped; two neighbouring blocks
  left ragged by the same substitution were rewrapped with it, wording untouched.
- **The rule it fails is one the same session wrote:** *prove a mechanical edit, do not
  eyeball it.* The 68 reflowed comment blocks were proved word-for-word; these thirteen
  citation edits were read. **A substitution that shortens a sentence must be read to the
  end of the sentence**, not to the end of the token it replaced.

- **Where:** `../../input_api.md`, *"The input widget — opening it and changing it"*.
- **The defect:** *"To close it after a submit, make that choice explicit"* followed by
  `after_submit = hide`, with *"Or pass `auto_hide` and let `show` do it"* trailing it. Nothing
  false — but `FEAT-01`/`FEAT-02` made `auto_hide` the recommended form, and a reader following the
  guide's own ordering writes the superseded idiom. **A recommendation drifts by staying still
  while the surface moves**, which is why no grep for a wrong statement would have found it.
- **Resolution:** the paragraph leads with `auto_hide` and keeps the hand-written form as what the
  key *does* — it is still the anchor the *"Asking one question"* section uses to predict the
  edges, so it could not simply be deleted.
- **Found by the owner reading the guide**, not by any planned row: `FEAT-01-05` and `FEAT-02-04`
  each documented the new key and neither re-read what the old idiom's own paragraph now implied.
  **Adding a surface does not re-rank the advice around it** — worth carrying into `DOC-01`.

### The deviation justifications live only in the PR description — NOT DEBT, the premise was false (2026-09-01)

- **Was `T-DEVIATION-WHY`**, filed and refuted the same day.
- **The claim:** the PR description's *"Ratified deviations"* table holds six technical
  justifications that die with the feature's working tree, while the decisions they belong to
  argue why today's shape is right and never say what it replaced.
- **The second half is false, and it was checkable.** Every one of the five outstanding
  arguments is already in its own decision, in more depth than the table's one-sentence cell:
  `D-ROUTE-LIFETIME` marks itself SUPERSEDED IN PART, quotes the superseded claim verbatim and
  records the base check that killed it; `D-NO-LOG-NOISE` has a *"What this settles"* naming the
  design's proposed debug log and a *"Why the log is declined"*; `D-HOOKS-SEEDED` argues the
  one-time seed against a precedence rule by name; `D-NO-FW-TIER` argues the framework tier was
  covering a leak; `D-ONE-LIFETIME` already carried the base-check provenance. The table
  **summarises** the ledger; it is not a unique home for anything.
- **And the first half wanted the wrong thing anyway** (owner, 2026-09-01): *"we do not make
  archaeology"* — `../../../agents/rules/ledgers.md`, *"What a decision records about its own
  past"*. Lifting more reversal narration in is the opposite of what the corpus needs; the real
  work is `T-ARGUES-INTERIM`, which takes it out.
- **Why it is recorded rather than deleted:** a defect refuted at its premise gets re-filed by the
  next reader who notices the same surface. The surface is real — a reviewer's table and a ledger
  do overlap — and the reason it is not a defect is the part worth keeping.
- **Cost of the error:** one paragraph written into `D-ONE-LIFETIME` (`e9a3501a`) and removed
  again (`cd1264da`), and a roadmap row filed and withdrawn.

### The callable config keys are unchecked (WONTFIX by owner ruling, 2026-09-01 — the premise was wrong)

- **Resolution: `wontfix`, by owner ruling, and the entry's framing was wrong
  before its facts were.** *"I'd just not enroll too much input checking
  ceremony beyond necessary. its edu project, not space rocket navigation."*
- **What the entry got wrong:** it read the checked pair as *one class closed
  one key at a time* — `BUG-01-08` for `cursor`, `BUG-02-02` for `text`, "still
  open on the remaining keys". That is patch archaeology, and it is not what
  happened. **`text` and `cursor` are the user's content; every other key is
  project-owned**, and that line is ratified as **D-CFG-BOUNDARY**, *"the
  configuration boundary: the user's content is `show`'s alone"* — the same
  split that decides which keys `configure` may touch and which reset on each
  `show`. The boundary checks the content class **completely**. There is no
  half-closed class.
- **And the two classes deserve different treatment, which is the owner's
  argument:** *"pass wrong text and you confuse the user, pass wrong validator
  and you confuse yourself."* A bad `text` reaches a person who did not write
  it and cannot fix it, so it is refused at the door. A bad `validator` reaches
  the project author, in their own code, and the raise names `validator` — the
  very key they set. That is self-diagnosing, which is why *loud and late* is
  an acceptable answer here and *silent* was not.
- **Facts, kept because they are still true:** `show{validator = 42}` raises
  `attempt to call local 'validator' (a number value)` at submit
  (`userInputController.lua:417`, and the same for `cb` at `:437`); the same
  holds for `highlighter`, `on_text_entered` and `on_limit_reached`;
  `prompt = 42` is assigned to `custom_label` unchecked and flows into the draw
  path where the annotation promises `string?`. Nothing in-tree passes a
  non-callable and every shipped example passes functions.
- **No guide sentence either.** Documenting *"these keys are not checked"*
  would be the same ceremony in prose, and it would teach a distinction the
  reader does not need: the guide already frames content and configuration as
  different things.
- **Provenance:** `#77`'s own surface. Found by the second cold peer review of
  `BUG-02-02`, 2026-09-01; re-raised as a delivery question by the session64
  revalidation the same day and ruled the same day.

### Six line citations into `userInputModel.lua` were stale on arrival (RESOLVED, 2026-09-01)

- **Resolution:** all six replaced with **function names**, which do not
  drift — `UserInputModel:insert_text_line`, `:line_feed`, `:set_cursor`,
  `:_set_text_line`, `:history_back` and `:history_fwd`, plus the Ctrl+D site
  named as the `modify` handler inside `_normal_mode_keys`.
- **What was wrong, and the mechanism** (corrected in the pass that filed it —
  the first version of this entry named the wrong cause and the wrong count):
  commit `e3484987` **trimmed the `set_text` doc comment from six lines to
  three** at `:157`, its own finding F7. Everything below moved **up by 3**,
  and the citations it wrote or carried in that same commit were numbered
  against the pre-trim file. Affected: `:224`, `:263`, `:546`, `:196-198` in
  two entries, and `:475`/`:487` in a third (the `set_text` caller
  enumeration). The real lines are `221`, `260`, `543`, `193-195`, `472` and
  `484`. None ever resolved; they pointed a reader at `end`, at a blank line,
  at `--- @private`, and at `self:clear_input()` in place of the history
  restore it claimed to cite.
- **Why it was worth fixing rather than filing:** a citation that does not
  resolve *reads as authoritative* — the standing objection in
  `agents/validation.md`, *"Comment References"*. And the rule was already
  ours: session61 replaced this same file's `set_cursor_pos` line citation with
  a function name **one day earlier**, giving this reason verbatim.
- **A line citation is not verified by reading a range around it.** `:475` was
  first checked by printing `472..478`, seeing `set_text` in the output, and
  calling it correct; it is `end`, and `set_text` is at `472`. Resolve the
  exact line or resolve nothing.
- **Scope checked, not assumed:** the corpus's citations into
  `editorController.lua` (`:336`, `:602`, and the census's `:590-604`,
  `:628-633`) and `userInputController.lua:316` resolve, being in files that
  commit did not touch. The wider population is **not** clean — see `general.md`,
  *"Line citations across the persistent corpus are unverified, and a fifth of
  the checkable ones do not resolve"*.
- **Provenance: ours**, 2026-09-01, all six traceable to one commit. Found by
  the session64 delivery revalidation and fixed on the owner's go.

### The programmatic-cursor census omitted the one writer on a hot path (RESOLVED, 2026-09-01)

- **Resolution:** `internals/user_input.md`, *"Cursor access exists at three
  layers"*, now carries the field-writers as a **second, explicitly separate
  population** — `_update_cursor`, `_advance_cursor`, `insert_text_line` — with
  the note that the last runs on every Shift+Enter and on Ctrl+D, and a
  cross-reference to *"`_update_cursor` measures the column on the wrong line"*.
  The census's own parenthesis was widened from *"an arrow/Home/End keypress"*
  to *"a cursor-movement keypress"*, which is what it always meant.
- **What was wrong:** the census said four programmatic call sites and
  `insert_text_line` was not among them, though it writes `self.cursor.l`
  unvalidated and its exclusion was not covered by the parenthesis. The corpus
  answered *"what moves the cursor?"* two ways, 90 lines apart in two files.
- **Why it was worth fixing rather than filing:** the census exists **because a
  sweep consults it instead of re-deriving** — the argument its previous
  correction was made on (session61, `ba09edcc`, which added `_apply_eval`
  after a sweep had missed it). It then missed a second site the same way, and
  that site is the only cursor writer live on ordinary editing. The two lists
  are now stated as different kinds — *callers of the cursor API* against
  *writers of the field* — because conflating them is what let a site fall
  between them.
- **Provenance: ours.** The census paragraph is `#77`'s writing; the omitted
  fact came from `#77`'s own second cold peer review, 2026-09-01, and was
  recorded in this register without anyone returning to the census. Found by
  the session64 delivery revalidation the same day and fixed on the owner's go.

### `set_text` answered a malformed content element three different ways (RESOLVED, 2026-09-01)

- **Resolution:** fixed at `BUG-02-02` — the step the owner added to `BUG-02`'s
  scope on the ground that *"it's our own interim defect which this feature
  introduced, and it does not go into release"*. `checked_text` sits beside
  `checked_cursor` at the project boundary (`consoleController.lua`) and refuses
  any `text` that is not a string or a list of strings, raising
  `compy.input.set_text: text must be a string or a list of line strings` — or
  the same message under `compy.input.show` — at the same level-4 depth. The
  surface's `set_text` was lifted into an `api_set_text` for that depth rule, as
  `api_set_cursor` already was.
- **The three behaviours it replaced**, all silent or unhelpful, none announced:
  `{'a', 42}` **silently dropped** the number, `{42}` **wiped the content** to
  `{''}`, and `{'a', true}` raised `bad argument #1 to 'len'` from inside
  `sanitize_utf8` — naming a function the project author never called.
- **Provenance, and why it was fixed rather than filed.** The raw raise is
  pre-existing; **the drop and the wipe were this feature's own**, introduced
  hours earlier the same day by `BUG-02-01`'s fix, when `string.lines` began
  type-checking elements that `InputText` had previously stored as-is. An
  interim regression that never reached a release is not debt to weigh — it is
  work to finish, which is the owner's ruling above.
- **The rule it settles is D-CONTENT-NORM's boundary: normalise representation,
  refuse structure.** A string against a list, an embedded newline, an invalid
  byte — one value spelled differently, and normalised silently. A number,
  boolean or table where a line belongs is not text at all. Coercing it would be
  tolerance producing a lie: the contract is documented and closed, so a value
  outside it can only be a mistake, and rendering `42` as a visible line hides
  that behind content which looks deliberate. **Corrected 2026-09-01 by the
  second cold review:** this entry first argued from `{'a', 42}` matching
  `UserInputModel:insert_text_line(text, li)`'s arguments, and cited
  `pong/main.lua:104` as a project converting numbers itself. Both are wrong —
  `insert_text_line` is a model method a sandboxed project can neither see nor
  call, and that `pong` line calls pong's **own** `set_text(name, str)`
  (`:95`), a `gfx.newText` wrapper unrelated to `compy.input`. **No in-tree
  project passes a number to `compy.input.set_text` in either direction**, and
  saying that plainly is stronger than either citation was.
- **Precedent followed, not invented:** `BUG-01-08` settled this class for
  `cursor` — a malformed value on the public surface earns one message naming
  the call and the expected shape, never a raw Lua error from inside the
  framework and never a silent repair.
- **Where:** `src/controller/consoleController.lua` (`checked_text`,
  `api_set_text`, `api_show`, `is_line_list`),
  `tests/input/input_cursor_text_spec.lua` (*"refuses a non-string element"*),
  `../../input_api.md` (*"Live changes"*), `../decisions/input.md` (D-CONTENT-NORM).
- **The first fix was incomplete, and the second cold review caught it**
  (2026-09-01). `checked_text` walked the list with `ipairs`, which stops at the
  first hole and never sees a non-integer key, so `{[1]='a', [3]=42}` was
  accepted and dropped the number, and `{foo = 42}` was accepted and wiped the
  content — **both silent symptoms, one spelling further out**, through `show`
  as well as `set_text`. A hole is not exotic: a `pairs` loop over a sparse
  source builds one in a line of ordinary project code. `is_line_list` now
  counts every key and requires `1..n` to be strings, which is what *"a list of
  line strings"* implies and what an `ipairs` prefix-test never checked.
- **`normalized_lines` deliberately keeps its `ipairs` walk.** The boundary
  refuses structure and the model normalises representation (D-CONTENT-NORM); the
  only callers reaching the model without passing the boundary are
  framework-internal (editor, history) and pass dense lists. Duplicating the
  validation into the model would blur that split.
- **A second behaviour changed with the lift and was not noticed at the time:**
  `show{text = false}` went from *"the previous content survives"* to *"the
  field opens empty"*, because `checked_text` normalises falsy to `nil` and
  `reset_content` branches on `cfg.text == nil`. The new behaviour is the
  correct one — D-CFG-BOUNDARY statement 1 makes an absent `text` an empty field
  and statement 3 makes `false` the uniform unset — so a second defect closed
  by accident. It is now documented in `../../input_api.md` and pinned by a
  test, having shipped as neither.

### `set_text`'s list branch does not split embedded newlines (RESOLVED, 2026-09-01)

- **Resolution:** fixed at `BUG-02-01`. The `type(text) == 'table'` branch hands
  its sanitised list to `string.lines`, which is polymorphic over
  `string | string[]` and delegates a list to `string.split_array` — so each
  element splits and empty elements are preserved. `set_text("a\nb")`,
  `set_text({"a\nb"})` and `set_text({"a","b"})` now produce the same two lines
  and the same cursor. One call; the two branches converge on the function the
  string branch already used instead of stating the rule twice.
- **Never slugged, and correctly so.** A slug is the commitment to fix and is
  earned when an entry becomes `ACTIVE`; this one was ruled and fixed in the
  same session, so it went `BACKLOG` → `RETIRED` without passing through.
- **The rule behind it is the owner's** (2026-09-01) and is now ratified as
  **D-CONTENT-NORM**, `../decisions/input.md`. It is the same rule the UTF-8
  sanitisation on this path already served: **the cursor addresses content as
  `(line, column)`, so content that is not normalised makes that address
  ambiguous.** Invalid bytes leave a column's *length* undefined; a newline
  inside a line leaves its *position* undefined — the caret could sit past a
  line terminator. Neither normalisation is a convenience, and they are now
  symmetric across both spellings. Written up in
  `../internals/user_input.md`, *"Multiline input"*, and stated for a project
  author in `../../input_api.md`, *"Live changes"*.
- **The two branches are now one path preceded by a normalisation step** (owner,
  2026-09-01), which is D-CONTENT-NORM's structural half: per-spelling branches
  that each decide what to normalise are what let UTF-8 and newlines drift onto
  different rules in the first place. `normalized_lines` returns the lines,
  `set_text` stores them, and there is one place left where either could drift.
- **The defect it closed:** the two branches of one function disagreed about
  what a newline means. `set_text({"a\nb"})` yielded **one** line holding a raw
  newline, which the model counted as an ordinary character — three characters
  long, caret positions `1..4`.
- **What was observable, established at the weighing** — more than the entry
  first claimed. The content round-trips through `string.unlines`, so
  `on_text_entered` could not tell the two apart; but `after_submit` receives
  the line list itself (D-PAYLOAD-SPLIT's payload split), so the spellings handed a
  project `{"a","b"}` versus `{"a\nb"}`. The validator runs per line and would
  have measured the concatenation and named the wrong line. And the rendering —
  recorded as *"needs a display"* — was read out of the draw code instead: both
  paths reach `gfx.print`, which honours the newline, and they corrupt it
  **differently**. `ViewUtils.write_line` draws the tail one row down at `x = 0`
  over its neighbour while the model still believes it drew one row, so the
  cursor, the visible window and the scroll arithmetic all disagree with the
  screen; the highlighted path prints character by character at explicit
  coordinates, so the newline draws nothing and reads as a blank column. Not
  display-verified — read from the draw code, which is why it was fixed rather
  than left described.
- **Why it was still narrow:** no in-tree caller could reach it. The three
  **project-facing** ones (`maze/core_editor.lua`, `tixy/main.lua` twice) pass
  either a raw string or `string.lines(…)`, and `string.lines` never emits an
  element containing a newline. **The enumeration was incomplete as first
  written** (cold peer review, 2026-09-01): the model's `set_text` is also
  called from `editorController.lua:336` and `:602`, from
  `UserInputModel:history_back` and `:history_fwd` (history restore) and from
  `userInputController.lua:316` (`show`'s `cfg.text`). All five were checked and the conclusion survives — `pprint`
  returns `string.lines(src)`, and buffer lines and history entries are already
  split — but "all three" would have let a reader think they did not exist. Nor could a user: `add_text` splits, and the paste path pre-joins
  with `string.unlines` at the controller before the model sees it. A project
  had to hand-build such a list, and **nothing could read it back** — the
  `compy.input` surface had no content getter when this landed, so there was
  no set/get round-trip the normalisation could break. (`get_text` arrived
  2026-09-03 and answers the normalised content, so the round-trip that exists
  now agrees with what this fix established rather than contradicting it.)
- **Provenance: pre-existing.** At the PR base `3256aac` the table branch is
  `InputText(text)` — no split, no sanitise. This feature fixed the *string*
  half (`T-MULTILINE-STR`) and thereby made the two halves visibly disagree; it
  did not introduce the branch. Two refinements found at the weighing: the
  per-element sanitise pass **is** ours, so the branch carrying the split is
  code this feature wrote, and the asymmetry — UTF-8 on both spellings,
  newlines on one — was its own choice rather than an inheritance. Found by the
  cold peer review of the fix that exposed it.
- **Where:** `src/model/input/userInputModel.lua` (`set_text`),
  `tests/input/user_input_model_spec.lua` (*"embedded newlines"*, three cases),
  `tests/input/input_cursor_text_spec.lua` (the surface case, beside its string
  twin), `../../input_api.md`, `../internals/user_input.md`, `../../../CHANGELOG.md`.

### `set_text`'s two branches disagreed about the cursor, and the call was dead (RESOLVED, 2026-09-01)

- **Resolution:** fixed at `BUG-02-01`, in the same unit as the entry above and
  on the owner's direction — *"either discard or cursor movement should be
  deleted, and in either case both paths should be unified"*. The call is
  **deleted** and the two branches are now **one path preceded by a
  normalisation step** (`normalized_lines`). Ratified as **D-CONTENT-NORM**,
  `../decisions/input.md`, closing section.
- **Registered here rather than left in a session track** (owner, 2026-09-01):
  a finding parked in a track dies with the session, so it goes in the ledger
  even when it is fixed the same day.
- **The defect:** `UserInputModel:set_text`'s string branch called
  `_update_cursor(true)` when `keep_cursor` was falsy; the list branch never
  did. The call was **inert on this path**, so the asymmetry was invisible:
  `_update_cursor` sets `cursor.c` from the line at the *old* cursor index in
  the *new* text and `cursor.l` to `#t` — a column from one line and a line
  from another, incoherent by construction — and `set_text` then runs
  `init_visible`, which replaces the whole `VisibleContent`, and `jump_end`,
  which overwrites both cursor fields with coherent ones. Every effect,
  including the visible-range move `text_change`'s `_follow_cursor` makes from
  it, is discarded before the call returns to its caller.
- **It never worked.** The commit that introduced the call (`472c6bba`, the
  transitional UserInput triplet) already ended `set_text` with an
  unconditional `jump_end()`. There is no revision in which it had an effect,
  which is why the branch lacking it behaved identically and the disagreement
  survived unnoticed. Shape copied from `_set_text_line`, where the call **is**
  live, into a function that already seated the cursor.
- **Mutation-tested before deletion, not reasoned about only:** five cases
  chosen to expose it — shorter replacement with the caret parked past the new
  end, longer replacement, and a 20-line buffer collapsing to one line, each in
  both spellings — produce byte-identical cursor and visible-range snapshots
  with the call and without it, and the suite is green either way. The
  **behaviour** is now pinned by tests (*"both land at the end of shorter
  content"*); **the deletion is not, and cannot be** — an inert call is
  indistinguishable from its absence, so restoring it leaves the suite fully
  green. Reintroduction is not test-detectable, which is worth knowing before
  anyone reads those tests as a guard against it (cold peer review, 2026-09-01).
- **`_update_cursor` itself stays, and only the `set_text` call site was
  deleted. Corrected 2026-09-01, same day:** this entry first said
  `_set_text_line` and `clear_input` "both call it live", which is wrong about
  the first. `_set_text_line` guards the call with `if not keep_cursor`, and
  **all seven of its callers pass `true`** — so that call is unreachable, and
  `clear_input` is the only reachable one. The correction matters because the
  claim would tell a later reader that path is exercised when nothing exercises
  it. What the function owes beyond that is its own entry, below.
- **Provenance: pre-existing**, inherited from the transitional triplet and
  present at the PR base in the same shape.
- **Where:** `src/model/input/userInputModel.lua` (`set_text`,
  `normalized_lines`), `tests/input/user_input_model_spec.lua`
  (*"embedded newlines"*).

### T-MAZE-NEUTRALIZE — `maze` neutralises two hook sites by clearing a flag, not by the widget guard (NOT DEBT, 2026-08-31)

- **Resolution: `wontfix`, by owner ruling — and the entry's premise was wrong.**
  The row opened by weighing rather than by fixing, and the weighing found
  nothing to weigh. No code changed in `maze`.
- **`ctrl_pressed` is maze's control-mode slot, not a neutralisation idiom.**
  `controls.lua` defines the modes and each one assigns it — `keys()` sets
  `handle_key`, `plan()` sets `plan_key` with a matching `ctrl_update`. Clearing
  it says *no control mode is active*, which is a statement about the game.
- **The contrast the entry drew inverts.** It read `core_editor.lua` as the file
  doing it the other way; `arm_editor` there is itself `ctrl_pressed = nil`. And
  that file's `is_shown` call is a **show-vs-configure** branch — *is there a
  field to reconfigure?* — not a double-handling guard, which is a different
  shape from `turtle`'s whole-handler early return.
- **Double-handling is prevented on the paths that occur — but by level
  ordering, not by structure.** The weighing first claimed "by construction";
  the sprint's peer review falsified that and it is corrected here. The hook
  fires while the widget is shown, finds `SYSTEM_KEYS[k]` nil — that table is
  only ever populated by member name — and `ctrl_pressed` nil, so the keystroke
  reaches the widget alone. **But `jump_level` → `start_level` → `cur_controls()`
  re-arms `ctrl_pressed` and hides nothing** (`compy.input.hide()` appears only
  in the two menu exits), so a jump from an editor level to a `controls = keys`
  level would leave both live. **Reported in maze's own `ISSUES.md`, not fixed** —
  it is that repo's defect and that repo's readers need to find it, where this
  ledger is ephemeral to them.
- **The shape is the one the guide advises** (owner, 2026-08-31): read the
  hardware early and turn the result into a deterministic variable the rest of
  the logic runs on — `../../input_api.md`, *"Perform hardware polling before
  complex processing"*. The only thing to say against it is that the variable
  is named after the keyboard where its role is mode selection (`special_mode`
  would say it) — **semantics and taste, explicitly not fixed**, in another
  repo's working code.
- **Where:** nothing changed. Evidence:
  `wip/77-new-input-api/validation/notes/BUG-01-11-maze-neutralisation-weighing.md`.

### T-BALLOON-LABEL — balloons keeps a shadow copy of the widget's label, re-pushed every cycle (RESOLVED, 2026-08-31)

- **Resolution:** fixed at `BUG-01-07`, in the **balloons repo** (a separate
  repo with its own remote, which opens its own PR alongside the platform one).
  `ui_messages.hint` and `ui_draw_hint` are gone; `ui_set_hint` writes straight
  through to the widget, with a comment carrying the reason the indirection
  existed.
- **Why it could go:** the copy had **no second reader** — it was written and
  read only inside the `ui_set_hint` → `ui_draw_hint` pair, so collapsing them
  loses no state. It existed because in the legacy era the label died with each
  `input_text()` call; with label stickiness ratified the widget owns the label
  and a prompt persists until replaced.
- **Three fossils went with it:** the `-- NOTE: won't work if there was no real
  input` comment (it described the flush-dependent redraw), `terminal_write`'s
  never-read `flushed` parameter, and the second argument passed to
  `ui_set_hint`, which takes one. The unused `SPLASH_HINT_START` seed went too;
  the constant stays, because the splash screen reads it directly.
- **Not runtime-verified:** balloons has no suite and needs a display. Desk-
  checked and parses; the manual smoke pass is where it is exercised.
- **A second defect was found here, raised, and then fixed on the owner's
  ruling.** `ui_draw_status` read `ui_messages.results`, which nothing ever sets
  — `ui_status_finalize` writes `ui_messages.result`, singular. It was reported
  rather than filed (`agents/development.md`: report non-blocking debt), and the
  owner ruled: *fix it if it is clearly a typo, delete it if it is clearly dead
  code.* It is the second, so the branch was **deleted** in the balloons repo.
- **Why deleting was right and repairing was not.** The two names are a
  self-consistent *pair* — `ui_status_reset` cleared `results`, `ui_draw_status`
  read it — so "repair the typo to `result`" would have changed nothing during
  play (`ui_status_finalize` sets the result immediately before the state
  becomes finished, where the splash renders instead of the status bar) and
  would have been a **regression across games** (`result` is never cleared, so
  game two's status bar would show game one's stats). Ask what the repaired code
  would *do* before repairing.

### T-CURSOR-BYTES — `set_cursor` clamps by byte offset; the boundary event measures characters (RESOLVED, 2026-08-31)

- **Resolution:** fixed at `BUG-01-05`. All three byte-bounded cursor clamps
  now count characters with `string.ulen`.
- **It was not an undecided design call.** The unit was already decided
  everywhere else: `jump_end`, `jump_line_end`, `is_at_limit`,
  `_update_cursor`, `cursor_left`/`right`, `cursor_vertical_move`, the
  mouse-to-cursor translation and the view's pixel math all count characters.
  Three clamps were the outlier, so the fix was to make them agree, not to pick
  a winner between two equal conventions.
- **The defect it closed:** on the six-character, twelve-byte `'привет'`,
  `compy.input.set_cursor(1, 10)` was accepted — the byte bound allows 13 —
  leaving the caret four positions past the end of the line and reporting 10
  back from `get_cursor()`.
- **Provenance, and it is mixed.** `UserInputModel:move_cursor`'s bound is
  PRE-EXISTING and unchanged at the PR base `3256aac`; its 18 internal callers
  all pass character values, so the gap was inert. `set_cursor_pos` and
  `_clamp_cursor_pos` are OURS — absent at base — and were written to copy the
  byte convention deliberately. They are what made the gap externally
  reachable. All three were fixed, because leaving the outlier would make our
  two differ from the function they were written to match.
- **The bound only narrows** (`ulen` ≤ `#`), and internal callers pass
  character values, so nothing that passed before is refused now.
- **Where:** `model/input/userInputModel.lua` (`move_cursor`,
  `_clamp_cursor_pos`), `controller/userInputController.lua`
  (`set_cursor_pos`), `tests/input/input_cursor_text_spec.lua`,
  `../../input_api.md` (*"Live changes"* — which had contradicted itself,
  calling `col` a caret position between characters and then ranging it over
  `1 .. #line + 1`).

### T-COMBO-CASE — `combo_string` does not normalise the case of a textinput token (RESOLVED, 2026-08-31)

- **Resolution:** fixed at `BUG-01-04`. `combo_string` (`controller.lua`) now
  lower-cases the trigger, so dispatch emits what registration stores.
  D-COMBO-TABLES already ratified the rule — "a project can register `['Ctrl+S']`
  and still match" — this only makes the dispatch half implement it.
- **The defect it closed:** registration canonicalises the whole combo
  (`key.lua`, `combo:lower()` inside `split_combo`), dispatch did not, so
  `shortcuts.textinput['Shift+I']` was stored as `shift+i` while typing `I`
  looked up `shift+I`. The slot was **unreachable**, not awkward: writable,
  never fireable, silent. `normalize_combo`'s own docstring asserted the
  agreement that did not hold.
- **Narrow by construction:** only textinput delivers a cased trigger.
  `keypressed`/`keyreleased` carry LÖVE key constants, already lower, and the
  reservation tables have no textinput channel; `'*'` lower-cases to itself.
- **It was OURS.** At the PR base `3256aac` `src/util/key.lua` is 53 lines with
  no combo machinery and `controller.lua` has neither `combo_string` nor
  `RESERVED`. This feature introduced **both halves** of the asymmetry — it is
  not inherited drift, which is the opposite of `T-MULTILINE-STR` above.
- **The limitation it makes explicit:** a shortcut cannot tell `I` from `i`.
  That was already true of every registration and is now true of dispatch;
  a project needing the distinction reads the character in `hooks.textinput`.
  Written down in `../../input_api.md`, *"Event hooks and shortcuts — when to
  use which"*.
- **Where:** `controller/controller.lua` (`combo_string`),
  `tests/input/input_combo_serialisation_spec.lua`,
  `tests/input/input_events_spec.lua`, `../../input_api.md`.

### T-MULTILINE-STR — `set_text` silently ignores a multi-line *string* (RESOLVED, 2026-08-31)

- **Resolution:** fixed at `BUG-01-09`. The string branch of
  `UserInputModel:set_text` now splits with `string.lines` and hands every line
  to `InputText`, which is where the table branch already handed its list. A
  single-line string yields a one-element list, so that path is unchanged.
  **The table branch did not itself split** — fixing this half is what made the
  two visibly disagree, and that is the entry above,
  *"`set_text`'s list branch does not split embedded newlines"*.
- **The defect it closed:** `self.entered` was assigned only when the string
  held one line, so a string with a newline matched no branch, nothing was
  written, and the previous session's content survived into the new one — with
  no warn and no raise. Reachable from `show{text = …}` and the live
  `compy.input.set_text`. **Corrected 2026-08-31** by the sprint's peer review:
  the fix commit's message also named `configure{text = …}`, which in fact
  **raises** — `text` is in `SHOW_ONLY_KEYS` (`consoleController.lua`) — and
  named `apply_config`, which no longer exists; the path is `api_show` →
  `open_widget` → `reset_content`. Both are wrong in the commit message, which
  cannot be amended, so the correction lives here, where the PR description
  will read it.
- **It was PRE-EXISTING, not ours.** The `#string.lines(text) == 1` guard is at
  the PR base `3256aac` in the same shape. What this feature added is the
  documented shape (`../../input_api.md`, *"The input widget — opening it and
  changing it"*: "a string or list of line strings") and the project-facing
  surface that reaches it — which is why it was fixed here rather than left
  described.
- **Where:** `model/input/userInputModel.lua` (`set_text`),
  `tests/input/input_widget_control_spec.lua`,
  `tests/input/input_cursor_text_spec.lua`, `../../../CHANGELOG.md` (*"Fixed"*).

### T-ONESHOT-SCOPE — the `show`-only `oneshot` becomes `auto_hide`, a widget property (RESOLVED, 2026-08-30)

- **Resolution:** built at `FEAT-02` on the owner's ruling, the same day the edge it
  amends was made. The key is **`auto_hide`**, it left `SHOW_ONLY_KEYS` for
  `configure_core`, and `show` and `configure` both set it, set-if-given, with
  `false` as the unset. It **persists until replaced**, like `validator`: it
  configures a *type of behaviour*, not one show/hide cycle, so it needs no
  clearing rule and no category of its own. No reader was added — a query earns
  its place when the framework can change the value, and nothing but the project
  writes this one.
- **The defect it closed:** disarming used to require `show{force}`, a full
  re-setup that clears the user's draft — and nothing could read that draft back
  first (no text getter on the surface; a project's `love` is a sandboxed clone,
  D-ONE-STATE-ASK). `configure{auto_hide = false}` now disarms without touching it.
- **What it did NOT fix, deliberately:** a follow-up `show{force}` from inside the
  submit chain is still closed by the submit in progress unless it passes
  `auto_hide = false`. Owning the close by the submit that armed it needs a
  generation token, judged not worth the state; the guide carries the idiom.
- **Where:** `consoleController.lua` (`SHOW_ONLY_KEYS`, `WIDGET_KEYS`),
  `userInputController.lua` (`configure_core`, `submit_flow`), `../input_api.md`
  (*"Asking one question"*), `../internals/user_input.md`, D-AUTO-HIDE,
  `../../CHANGELOG.md`.

### T-ONESHOT — `oneshot` is ruled in and nothing implements it (RESOLVED, 2026-08-30)

- **Resolution:** built at `FEAT-01-02` after `FEAT-01-01` ratified the edges —
  three as first recommended, one **reversed**: it closes on a *clean*
  submit only, because the error boundary the recommendation stood on wraps the
  route rather than the submit chain. `show{ oneshot = true }` seats the flag at
  activation and `submit_flow` spends it after `after_submit`; `configure{oneshot}`
  raises as a `show`-only key. Documented at `FEAT-01-05`, including the dismissal
  asymmetry Escape leaves standing.
- **Where:** `userInputController.lua` (`open_widget`, `submit_flow`),
  `consoleController.lua` (`SHOW_ONLY_KEYS`), `../input_api.md`
  (*"Asking one question"*), D-AUTO-HIDE.
- **Read the paragraph above as history, not as behaviour** (2026-08-30, the same
  day): `T-ONESHOT-SCOPE` and `FEAT-02` replaced that shape. The key is
  **`auto_hide`**, it is project-owned and settable at `configure`, and it
  **persists until set to `false`** rather than being spent by its own `show`.

### T-PLAINTEXT-ENTERED — the two submit callbacks receive identical payloads (RESOLVED, 2026-08-30)

- **Resolution:** built at `FEAT-01-04` per D-PAYLOAD-SPLIT — `on_text_entered`
  receives the joined string, `after_submit` the line list, and that difference is
  what tells them apart. This also closed **`FIX-02-01`**, which asked whether the
  two were one callback set two ways; the answer needed the write-up as much as
  the ruling, so `FEAT-01-06` carries the *recommended, not enforced* convention.
- **The migration was not uniform, which the entry originally missed.** `unlines`
  is idempotent over a string, so the four consumers that joined kept working
  untouched and were rewired at `FEAT-01-07` for clarity alone; the three that
  indexed (`turtle`, `valid`, `guess`) broke **silently** and migrated with the
  framework.
- **Where:** `userInputController.lua` (submit flow), `../input_api.md`,
  `CHANGELOG.md` (`Changed`, leading with the migration), D-PAYLOAD-SPLIT.

### T-TURTLE-DUP — `turtle` double-handles its own keys (RESOLVED, 2026-08-28)

- **Resolution:** `if compy.input.is_shown() then return end` guard added to `love.keypressed` in `src/examples/turtle/main.lua` to match `love.keyreleased` and prevent double-handling when prompt is open.
- **Where:** `src/examples/turtle/main.lua`.

### `wrap` guards the `xpcall` arity hazard on the platform, not the capability (RESOLVED, 2026-08-28)

- **Resolution:** the branch is gone rather than re-guarded. `wrap` now
  closes the arguments over a nullary function and calls
  `xpcall(fn, on_error)`, which asks nothing of the runtime — so there is no
  platform test left to disagree with the capability. Was `T-XPCALL-GUARD`.
- **Where it was:** `src/controller/controller.lua`, `wrap` — the `_G.web`
  branch, whose `pcall` side was correct for the Web build and unreachable
  for `busted` on PUC Lua 5.1, which is not the Web build. There the route
  was entered with nil arguments: **107 failures**, all under
  `tests/input/`, on a suite green on LuaJIT.
- **Not introduced by this feature.** `master` carries the same guarded
  `xpcall`, reached through `error_wrapper`/`set_handlers`, so on PUC 5.1 an
  adopted `love.keypressed`/`textinput`/`keyreleased` and `love.update`'s
  `dt` already arrived nil. The feature inherited the defect, widened it to
  every shortcut, hook and the widget, and supplied the first tests that
  could see it. The fix is therefore cumulative against the last release,
  not a repair of this branch's own regression — which is how `CHANGELOG.md`
  states it.
- **Guarded by:** `input_route_lifecycle_spec.lua`, "the boundary carries
  arguments on any runtime" — two cases driving a real keystroke with the
  global `xpcall` swapped for PUC 5.1's arity.

### The `show`/`configure` content-ownership boundary was not built (RESOLVED, 2026-08-27)

- **Resolution:** built as sprint `ARC-02`, the implementing pass D-CFG-BOUNDARY's
  own text named as not yet landed. `configure` refuses `text`/`cursor` as
  `show`-only keys, the hidden-`configure` stash is gone with `state.pending`
  entirely, and a forced `show` with no `text` clears. Was `T-CFG-BOUNDARY`.
- **Where it was:** `consoleController.lua` (`PER_SHOW_KEYS`, `check_keys`,
  `stash_hidden_configure`) and `userInputController.lua` (`re_show`).
- **Note:** the two behaviour changes against stakeholder-seen text — the
  clearing forced `show`, and the dropped stash — are recorded in D-CFG-BOUNDARY,
  which is the deviation record for them.

### A highlighter could not be turned off — `false` already did it, unratified (RESOLVED, 2026-08-27)

- **Resolution:** ratified rather than built. D-CFG-BOUNDARY, statement 3 makes
  `false` the uniform unset for every project-owned field, and
  `doc/input_api.md` documents it with the `computed or false` idiom. No code
  changed: every consumer already tested truthiness, so a stored `false`
  always took the absent branch. `prompt`'s two spellings are documented
  beside it — `''` is an empty label, `false` restores the default.
  Was `T-HL-UNSET`.
- **Where it was:** `userInputController.lua`, the shared config path.

### `show{force = true}` applied some keys, dropped one, deferred another (RESOLVED, 2026-08-27)

- **Resolution:** dissolved rather than patched, as the row predicted. A
  forced `show` now takes the ordinary activation path, so there is no
  separate `force` path left to have its own behaviour for a key.
  Was `T-FORCE-PARTIAL`.
- **Where it was:** `userInputController.lua`, `re_show` — deleted.

### `show{cursor = {}}` raised a raw Lua error from inside the framework (RESOLVED, 2026-08-27)

- **Resolution:** `checked_cursor` at the project boundary refuses a malformed
  pair with a framework message naming the shape, on both public paths
  (`show`'s config key and `compy.input.set_cursor`). Out-of-range numbers are
  untouched and still clamp, which is the distinction the guide promises.
  `cursor = false` is the uniform unset rather than an error.
  Was `T-CURSOR-SHAPE`.
- **Where it was:** `userInputController.lua`, `set_cursor_pos` — reached with
  nil or a non-table and dying inside `math.min`.

### The highlighter had two homes, and one of them lagged (RESOLVED, 2026-08-27)

- **Resolution:** one home, per the owner's ruling. The widget's `callbacks`
  slot is the source of truth and the evaluator RESOLVES it
  (`UserInputController:bind_highlighter`) rather than holding a copy, so a
  direct assignment and a `show`/`configure` key are the same write by
  construction. Resolution rather than a forwarding closure, because the model
  branches on the truth of `ev.highlighter` and it must stay nil when unset or
  the validation-colouring fallback stops running. Bound only where the
  evaluator is the widget's own — console and editor share theirs and it
  carries a language highlighter. The drift it replaces is written up in
  `internals/user_input.md`, "One home for the highlighter".
  Was `T-HL-TWO-HOMES`.
- **Where it was:** the widget's `callbacks` table and `model.evaluator`, with
  only the shared config path copying between them.


### `wrap`'s error handler is called with the wrong arity, so project raises vanish (RESOLVED, 2026-08-03)

- **Resolution:** `wrap` binds CC in a closure used by both branches
  (`2554d2e3`), so a raise anywhere in project code now reaches
  `user_error_handler` and suspends the run. Three rows pin it — pointer,
  `love.update`, and a keyboard hook as the control that the other two are not
  asserting something impossible. Owner ruling: a certainly-wrong behaviour is
  not preserved on the grounds that changing it was never approved, even
  though it is pre-feature.
- **Where it was:** `src/controller/controller.lua`, `wrap` — the non-web
  branch was
  `return xpcall(f, user_error_handler, ...)`. `xpcall` invokes a message
  handler with exactly **one** argument (the error), but the signature is
  `user_error_handler(CC, msg)`. So `CC` binds to the error string, `msg` is
  nil, and `'user error: ' .. msg` raises *inside* the message handler, where
  `xpcall` swallows it. Nothing reaches `suspend_run`.
- **Measured effect** (probe run 2026-08-03, asserting the handler executed
  before the raise): a raise in a project's **pointer handler** or in its
  **`love.update`** runs the handler, then vanishes — no error window, no
  console line, `app_state` still `'running'`. A raise in a **keyboard hook**
  suspends correctly, because that path goes through `chain_native`, which
  binds CC in a closure (`xpcall(fn, function(m) user_error_handler(CC, m)
  end, ...)`) and gets the arity right.
- **`_G.web` is falsy on the desktop build, so the broken branch was the live
  one.** The web branch passed both arguments and never had the arity
  problem. Its own flaw — returning bare `r` where the other branch returned
  `xpcall`'s `ok, res...` tuple, so the `@return` annotation described only
  one of them — was fixed alongside the wrapper collapse (`f1dc6aee`).
- **Why the web branch exists at all, established 2026-08-03:** it is not a
  stylistic duplicate. `xpcall(f, h, ...)` forwarding arguments to `f` is a
  LuaJIT / Lua 5.2 extension; PUC Lua 5.1 takes exactly two arguments and
  drops the rest, so on that runtime every handler would be invoked with nil
  for all of its parameters. `pcall(f, ...)` forwards on both. Measured here:
  LuaJIT gives `1, 2`; 5.1 semantics give `nil, nil`. The branch is therefore
  **load-bearing and must not be collapsed away** — a warning to that effect
  now sits on it in code.
- **Reach at the time:** `wrap` had three call sites — `wrapped_native`
  (pointer handlers), the loader, and the project `update` wrapper — plus
  `CC:wrap_handler`, which took `wrap` as its error handler, for the compy
  click handlers. All of those except the loader and the update wrapper have
  since been replaced by `guarded`.
- **Pre-feature, verified:** `wrap` and `user_error_handler` are
  byte-identical at the PR base `3256aac`. The input API neither introduced
  nor worsened this; it only made the contrast visible, because the keyboard
  chain's own wrapper does it correctly.
- **Consequence for the docs:** "A raise from project top-level and from a
  handler surface differently" (below) describes the handler path as
  reaching the error window. That holds for keyboard hooks only.
- **Kept as a closed entry** because two things in it are still live
  knowledge: why the web branch exists (above), and the fact that this
  subsystem's error path had a defect no test could see for the length of the
  feature — the argument for the Web-coverage entry that opens this section.

### `compy.before_exit` is absent from the persistent API docs (RESOLVED, 2026-08-03)

- **Resolution:** documented as `doc/input_api.md`, "Stop hook —
  `compy.before_exit`" (owner ruled 2026-08-03), covering signature, ignored
  return, timing before framework teardown, which stop paths fire it, that a
  raise is **not** one of them, and the reset. Every clause is pinned in
  `tests/input/input_route_lifecycle_spec.lua`; the not-fired-on-raise claim
  was mutation-checked rather than read.
- **What it was:** a public, project-settable lifecycle slot whose only
  specification lived in the feature's ephemeral working tree, which is
  scheduled for deletion — while the PR is meant to be reviewable from
  `doc/input_api.md` plus the description alone. The entry above also depends
  on that contract being findable.

### Future input unification (RESOLVED, 2026-08-03)

- **Resolution:** done, and in the direction this entry doubted. Every
  channel — keyboard, text, pointer, and the derived singleclick/doubleclick
  events — routes through one chain with one error boundary and one lifetime
  (`../decisions/input.md`, D-ONE-LIFETIME). The derived clicks did fold into
  hooks: `compy.singleclick` is gone and `compy.input.hooks.singleclick`
  replaces it.
- **Where this entry was wrong, worth keeping:** it recorded the asymmetry as
  predating the input API. It did not. At the PR base every event installed
  through one path and none was released before stop; the split was
  introduced by this feature (D-ROUTE-LIFETIME, amended). The entry then reasoned
  from the false premise to "folding clicks into hooks would falsely imply" a
  shared contract — when a shared contract was in fact the pre-existing state.
- **What genuinely remains unproven** and is recorded separately: pointer
  combos, and whether a shown widget should consume clicks within its bounds.
  See "Pointer delivery is an unstructured broadcast" below.

### Project-handler wrapping: dedup the guard, drop the misleading `keyboard_` name (RESOLVED, 2026-08-03)

- **Resolution:** the two builders are one. `chain_project_handler(CC, fn)`
  wraps, `project_handler(userlove, CC, key)` guards, and both the keyboard
  participants (`project_handlers`) and the pointer installs (`hook_pointer`)
  use it. The guard exists once. `wrapped_native` / `keyboard_native` /
  `chain_native` are gone, and with them the `native` label and the
  keyboard-specific name on a function that was never keyboard-specific.
- **What made the collapse possible:** the split was justified by return
  policy — `CC:wrap_handler` discards the return by construction, and a chain
  participant's return is its consume signal. That was never a real
  constraint: a returning wrapper is usable where the return is ignored,
  which is exactly what a pointer handler installed on `love.*` does. The
  genuine obstacle was that the two paths had *different error handling*, one
  of which was broken — see the arity entry above, fixed first so the
  collapse could be behaviour-preserving rather than a fix in disguise.
- `CC:wrap_handler` survived this step for the compy single/double click
  handlers, then went with them when the clicks became ordinary events
  (D-ONE-LIFETIME). Nothing wraps project code any other way now: `guarded`
  (`controller.lua`), applied where a route is entered, is the only one.
- **Verified behaviour-preserving:** suite 911/0/0/3 across the change, and
  the pointer path now propagates a return value that both `love.handlers`
  and the poll loop discard.
- **What it was:** two builders adapting a project's own `love.*` handlers —
  `wrapped_native` (via `CC:wrap_handler`, return discarded, installed
  straight onto `love.*` by `hook_pointer`) and `keyboard_native` (via
  `chain_native`, return propagated, seeded as `hooks[event]` by
  `occupy_keyboard`) — carrying the **identical** guard
  (`orig and new and orig ~= new`) and differing only in the wrapper they
  called. `keyboard_native` was misnamed: nothing about it was
  keyboard-specific. Deferred out of the D5 vocabulary rename (2026-07-21)
  on the reasoning that renaming under a mechanical sweep would either bless
  the smell with fresh names or smuggle a behaviour-touching refactor into a
  rename commit — which is why it waited for a pass of its own.

### `love.handlers.userinput` is dead code (RESOLVED, 2026-08-07)

Deleted, with the local `clear_user_input` that existed only to feed it. Both
`love.event.push('userinput')` sites were present at the PR base
(`3256aac:userInputModel.lua`) and were removed by this feature, leaving the
consumer installed — the same shape as `wrap_handler`. Kept as a resolved entry
because the pattern recurs: when a producer goes, grep for its consumer.

### Input-only / pointer-only projects stay live in `project_open` (RESOLVED, ruling a)

- **Where:** `consoleController.lua` `run_project`
  (`consoleController.lua:260-269`), `controller.lua`
  `user_is_interactive` (`controller.lua:1112-1113`),
  `user_pointer` / `hook_pointer` (`controller.lua:68`,
  `:238-249`), `set_default_handlers`
  (`controller.lua:778-824`, resets `user_pointer`), and
  `love.quit` (`controller.lua:733-758`).
- **State (old, broken behaviour):** A non-blocking project (no
  `update`/`draw` hooked) always dropped to `'project_open'` with
  the project route unconditionally released
  (`release_keyboard_route`). For a project whose entire UI was
  the input widget (`examples/guess`) or a pointer handler
  (`examples/sapper`), this meant (1) submit was dead — typing
  still reached the widget but Enter never fired, because
  submit/cancel (then a non-overridable framework tier, since
  retired — D-CHAIN-OF-3) lives in the *project*
  route, which `project_open` disconnected — and (2) Ctrl+Esc quit the whole
  app instead of returning to the console, because `love.quit`
  only stopped-to-console while `app_state == 'running'`.
- **Confirmed pre-existing:** this was verified byte-identical on
  `master` (pre-`0022004`) — not an input-API regression. The
  `release_keyboard_route` call site is new in 1.0.0-rc20260712
  (route-lifecycle rework, AC-27/28), but the lifecycle split it
  slots into predates the feature.
- **Resolution:** owner ruled (a) — an input-only / pointer-only
  project is "live" without hooking `update`/`draw`. New
  predicate `Controller.user_is_interactive()` returns
  `love.state.user_input ~= nil or user_pointer`, where the
  module-local `user_pointer` flag is set in `hook_pointer` when
  a project installs any pointer/click handler and reset in
  `set_default_handlers`. `run_project` now releases the keyboard
  route only when `not user_is_interactive()` — an interactive
  non-blocking project keeps the project route, so submit/cancel
  keep working (`app_state` still becomes `'project_open'`
  either way, since quickswitch relies on that). `love.quit` now
  stops-to-console for `app_state == 'running'` OR
  (`'project_open'` AND `user_is_interactive()`); an idle console
  (`'project_open'`, nothing interactive) still lets the app
  quit.
- **Carried-forward limitation:** a non-blocking project with
  *no* interaction surface at all (no widget shown, no pointer
  handler, no update/draw) still gets `release_keyboard_route` —
  the keyboard goes back to the console. This is intended, not a
  gap: such a project has nothing left to be interactive with.

### `compy.keys_pressed` is not exposed to projects (RESOLVED, 2026-08-03)

- **Where:** the project-facing `compy` namespace (`consoleController.lua`,
  the function that assembles it) exposes `terminal`, `audio`, `graphics`,
  `fonts`, `input`, and a `before_exit` slot — no `keys_pressed`. Held-key
  access exists framework-side (`Controller.keys_pressed`, the `held_keys()`
  read-only pressed-keys view) and via the per-event callback argument, but a project cannot poll
  currently-held keys from inside its own `update()`.
- **Why it stands:** Open design question — expose a read-only held-key view
  to projects, or treat callback-arg access as the sanctioned shape and amend
  the documented contract to say so explicitly.
- **A real consumer now exists, and it rules out the second option**
  (2026-08-03): the `keyboard` example maintains its own `INPUT.held` /
  `INPUT.shift` mirror and reads it **during draw**, to decide whether to
  render shifted key labels. A per-event argument cannot serve a per-frame
  renderer, so callback-arg access alone is insufficient for any project that
  *renders* held state rather than reacting to it.
- **Resolution:** owner ruled to expose it — `compy.input.keys_pressed`, the
  same read-only view the chain handed participants, resolved per access so it
  could not go stale. (That ruling had a decision of its own; it was withdrawn
  whole with the rest of the held-key arc and the entry is gone — see the
  supersession below.) Placed on
  `compy.input` rather than at the top of `compy`: it is input state, and the
  input guide is where a reader looks for it.
- **Resolution superseded** (`../decisions/input.md`, D-ASK-THE-DEVICE): the view is
  dissolved and no held-key surface is exposed. **The need this entry recorded
  is still met, by a different answer** — the renderer that ruled out
  callback-arg access asks the device instead (`love.keyboard.isDown`), which a
  per-frame draw can do as freely as a handler can. The entry stays RESOLVED;
  only what resolves it has changed.

### Shortcuts key-repeat semantics are shipped unsettled (RESOLVED, 2026-08-03)

- **Where:** `src/controller/projectInputController.lua`, `:keypressed` —
  `isrepeat` is threaded through to `hooks[event]` dispatch only; `shortcuts`
  fire on every OS key-repeat with no `isrepeat` gate.
- **Why it stands:** Whether shortcuts dispatch should also gate on
  `isrepeat` (fire once per physical press) or intentionally fire on every
  repeat is an open behavioural call, shipped open by design.
- **The first real consumer wants once-per-press** (2026-08-03): `keyboard`'s
  reserved chords (`shift+escape`, `ctrl+alt+up`/`down`) are now shortcuts,
  and each wraps itself in a `if not isr then … end` gate — otherwise holding
  `ctrl+alt+up` ramps the notch every frame. The flag *is* delivered to
  shortcuts, so the workaround is three lines; the question is whether every
  consumer should have to write them.
- **Resolution:** owner ruled that dispatch keeps firing on every repeat and a
  binding opts out for itself — `compy.input.fn.ignore_repeat(fn)`
  (`../decisions/input.md`, D-IGNORE-REPEAT), with `fn.stop_here` alongside it
  when the binding also claims the key (D-STOP-AND-SIDE). Filtering inside the shortcut tier
  was rejected for two reasons: it suppresses with no way to recover a
  hold-to-act binding, and it would leave the same hand-written check in
  `hooks.keypressed`, where commands are equally idiomatically bound. The
  wrapper has one signature and composes across all three tiers.

### No public `is_active()`-shaped visibility query (RESOLVED, 2026-07-31)

- **Where:** the `compy.input` project surface (`consoleController.lua`) had
  no `is_shown`/`is_active`/`is_visible`, though an internal
  `UserInputController:is_shown()` existed.
- **State (old), and worse than this entry recorded:** the entry said example
  projects read `love.state.user_input` directly, as if that were a working
  workaround. **It is not.** A project's `love` is a sandboxed deep clone
  (`../internals/project_sandbox_env.md`), so `love.state.user_input` read
  from inside a project is always `nil` — the framework writes the real
  global, the project sees its copy. `examples/maze/main.lua:497` guards a
  re-show with exactly that read: dead code that never fires, which is why
  maze re-shows the widget on every tick.
- **Resolution:** owner ruled to expose it —
  `compy.input.is_shown()` (`../decisions/input.md`, D-ONE-STATE-ASK), returning
  the widget's own flag so it cannot drift from the one the dispatch walk
  reads. Used by `examples/turtle` for its open-only-if-closed guard.

### On the console route, a hidden widget's input falls to the console line (RESOLVED, 2026-08-03)

- **Resolution:** settled by construction — the console route no longer has a
  widget step at all. The three `forward_*` functions that implemented it were
  deleted, so every keyboard/text event on that route goes to `CC:keypressed` /
  `CC:textinput` (the console line, or the editor fork), hidden widget or
  shown. D-ROUTE-OWNS's "widget visibility is never a routing condition" now
  holds on both routes. The two routes still read differently — the project
  route ends an unclaimed event in the chain, the console route ends it in its
  own input surface — but that is each route's own terminal, not two answers
  to one question.
- **The rows that pinned it are re-sited, not deleted** (2026-08-03). They had
  gone vacuous: with no widget step on the console route, a *shown* widget
  would have satisfied them there too. On the project route a hidden widget is
  a real decision — the walk skips it and reports not-consumed — so they now
  discriminate on the widget's own text, with a third row as the control that
  the same keystroke edits a shown widget. The `#disputable` tag is gone: the
  question it marked is answered, not merely pinned.
- **Where it was:** `src/controller/controller.lua` — `forward_keypressed` /
  `forward_textinput` / `forward_keyreleased` handed the event to the widget
  only while `love.state.user_input` was set, which `hide()` clears; the
  console-route defaults then fell back to `CC:keypressed` / `CC:textinput`.
- **Why it stands:** The general principle — *input the widget declined
  should have no effect* — was ruled for the **project** route only:
  D-ROUTE-LIFETIME ("Changed baseline behaviour", `../decisions/input.md`) gives
  a running project's route every keyboard/text event, so an event no
  shortcut, hook, or shown widget takes simply ends there, instead of
  accumulating in the console behind the project's screen. The **console**
  route kept the old shape, and it is not obviously wrong there: the console
  line is that route's own input surface, so "the widget is down, type into
  the terminal" is arguably the correct reading, not a leak. What is unruled
  is whether the two routes should read the same way.
- **Reachability:** No leak path through a *running* project is known today
  — the running case is D-ROUTE-LIFETIME's, and the `project_open` case is
  narrowed by ruling (a) above (`user_is_interactive`), which keeps the
  project route for any project with a widget or a pointer handler. The
  open question is therefore a contract question first: two routes, two
  answers to the same question, only one of them written down.
- **Revisit:** At the next ruling pass over route symmetry — either sanction
  the console fallback explicitly in the contract doc, or give the console
  route the project route's "declined means no effect" shape.

### A bare `*` shortcut is legal, and ruled that it should not be (RESOLVED, 2026-08-03)

- **Resolution:** `check_combo` (`src/util/key.lua`) now raises on a `*`
  trigger with no modifiers, naming the alternative in the message ("for every
  key, use `compy.input.hooks`"). D-COMBO-SHAPE and `doc/input_api.md` carry the
  rule, and two rows pin it — the raise, and the control that `shift+*` is
  still accepted, so the check cannot pass by rejecting classes generally.
- **What it was (measured 2026-08-03):** `shortcuts.keypressed['*']`
  registered without raising and caught every **unmodified** key — `q` fired
  it, `ctrl+s` did not, that belonging to the `ctrl+*` class. Coherent with
  D-COMBO-SHAPE (a class is its modifier set exactly, and the empty set is a
  class), but undocumented, untested, and a second spelling for what a hook
  already expresses.
- The entry was kept here rather than in `../decisions/input.md` while it was
  unimplemented, deliberately: a ratified entry describing behaviour the code
  lacks is the exact error this phase spent a session undoing.
- Corrected while closing: the session25 claim that the multi-trigger raise
  "settles whether a bare `*` is legal" was wrong. It permitted it.

### A multi-trigger combo is silently truncated at registration (RESOLVED, 2026-08-03)

- **Where:** `src/util/key.lua`, `normalize_combo` / `split_combo` — the
  trigger is "the last non-modifier token wins", with no complaint about the
  earlier ones.
- **State (measured 2026-08-03):** `ctrl+a+b` is stored as `ctrl+b`, and
  `a+b+*` is stored as **`*`** — a string an author wrote to mean the
  narrowest possible binding registers the widest possible one. Nothing warns.
  The grammar is *modifiers plus exactly one trigger*: `combo_string` prepends
  only the four modifier classes, so a held non-modifier key never enters the
  combo string at all (measured: `a` and `b` held, `b` pressed → `ctrl+alt+b`,
  no trace of `a`). Multi-key chords are outside the grammar; a project that
  wants "a and b held together" asks the device for the second key inside the
  hook or shortcut that handles the first (`doc/input_api.md`, "Choosing the
  mechanism"). Reconstructing it from a pair of flag-setting shortcuts is
  **not** the answer — that shape is now named as an antipattern there.
- **Resolution:** registration now **raises** on a combo naming more than one
  trigger, or none (`../decisions/input.md`, D-COMBO-SHAPE) — the same treatment
  `show`/`configure` give an unrecognised key. `a+b+*` no longer registers the
  widest possible binding; it is refused with the legal shape in the message.

### A combo table cannot express a modifier-class rule (RESOLVED, 2026-08-03)

- **Where:** `compy.input.shortcuts[event]` (`../decisions/input.md`,
  D-COMBO-TABLES) — `Key.new_handler_table`, an exact canonical lookup keyed by
  one full combo string.
- **State:** every binding names one combo, and dispatch is one exact lookup
  of `combo_string`'s output. A project that wants "**every** `alt+x` is a
  chord, swallow it whatever `x` is" has no sanctioned way to say so; it needs
  an entry per key, or it keeps that rule in a hook and tests the modifiers by
  hand. Found by the `keyboard` migration (2026-08-03), which moved its three
  named chords to shortcuts and kept `appChord` — its Alt-class rule — as a
  hook for exactly this reason.
- **The table is not sealed, though** (measured 2026-08-03):
  `Key.new_handler_table` sets no `__metatable`, so a project can reach the
  metatable and add an `__index`, and dispatch's plain lookup then consults it
  on a miss — a working wildcard, in three lines. It is undocumented, it would
  break the moment the table is sealed, and a reader would take it for a bug.
  Recorded because it shows the mechanism exists, **not** as an idiom.
- **A wildcard would have to answer more than it looks:** precedence against
  an exact binding, whether the matched trigger is passed to the handler, and
  the modifier's own press — holding Alt and pressing nothing else dispatches
  the combo **`alt+lalt`**, since `combo_string` prepends the held modifier to
  a trigger that *is* that modifier. A naive `^alt%+` pattern matches it.
- **Resolution:** owner ruled a sanctioned form — a trailing `*` binds the
  modifier class (`../decisions/input.md`, D-COMBO-SHAPE). `alt+*` is every Alt
  chord; exact bindings win, the class is consulted only on a miss, and it
  never matches the modifier's own press. The three questions above are
  answered by it: precedence is exact-first; the trigger is already the
  handler's first argument; and a class does not match when the trigger is
  itself a modifier. The unsealed-metatable route above is superseded — do
  not use it.
- **Still true, and now documented rather than implicit:** the class form is
  about a *modifier* class. Combos of ordinary keys (`a+b`) remain outside the
  grammar by design, since including held non-modifiers would make every
  binding conditional on nothing else being held. That case is a hook that
  asks the device for the rest of the chord (`doc/input_api.md`, "Choosing the
  mechanism").

### Combo-string dispatch allocates a table per call — RESOLVED 2026-08-16

- **Where:** `src/controller/controller.lua` — `combo_string` built a `parts`
  table and `table.concat`ed it on every call, on the per-keystroke dispatch
  path.
- **Resolved** (`737d8316`): it now accumulates the string directly, so no table
  is allocated. A reused module-level buffer was the other candidate and was
  **declined** — it trades the allocation for shared mutable state in a function
  that would then have to never be called re-entrantly.
- **What remains, and it is smaller:** `find_shortcut`
  (`src/controller/projectInputController.lua`) calls `combo_string` **twice** on
  a miss — once for the exact combo, once for the `'*'` class — so one event can
  ask the device six times instead of three. Reusing the first walk needs either
  a parameter on `combo_string`, cached state, or a second copy of D-COMBO-TABLES's
  precedence logic; all three were judged worse than the cost.
- **Revisit:** with the `'*'`-class lookup, if combo dispatch ever lands
  somewhere genuinely hot.

### `F.reset()` test helper exceeds the 14-line function-body limit (RESOLVED, 2026-07-31)

- **Where:** `tests/helpers/input_fixture.lua`, `F.reset()`.
- **State (old):** Around 18 code lines — native-slot restores plus several
  state-clearing assignments — against the project's 14-line function-body
  hard limit.
- **Resolution:** The native-slot restores the entry names are gone: the
  helper delegates to production teardown (`CC:stop_project_run()`) and clears
  only what production does not own. Nine code lines as of the widget-shown
  fix, which removed the last compensating assignment (`widget.shown = false`).
  Nothing to extract. **Re-counted 2026-09-03 at `FIX-02-05`: eleven**, not
  nine — the helper has grown three restores since (`love.update(1.0)`, and
  `clear()` on the editor's input and the widget). Still under the 14-line
  limit, so the resolution holds; the figure had drifted, which is the one
  numeric drift the verification pass found across 56 entries.

### `submit()`'s deliver-then-hide ordering forced example-side deferral of any reshow (RESOLVED by the input-API redesign)

- **Where:** `src/controller/userInputController.lua` — was `submit()` (calls
  `deliver(self, text)` then unconditionally `hide()`s); now `submit_flow`.
- **Old state:** `on_text_entered` fired while the widget was still active, and
  a trailing `hide()` ran right after (auto-close). A project wanting to "reshow with
  the same text on invalid input" could not call `compy.input.show{...}`
  synchronously from inside its own callback — a re-entry guard
  suppressed it, then `hide()` wiped it. One example project worked around
  this by deferring the reshow a frame.
- **Resolution:** Auto-close on submit is gone (D-NO-FW-TIER):
  `after_submit` DEFAULTS to a
  no-op and the widget stays open. A rejected validator locks the field with the
  rejected text still showing — there is nothing to reshow, so the one-frame
  deferral workaround this entry described no longer has a reason to exist.
- **Revisit:** None needed; carried here as resolved history, not deleted.

### `_generic_callback` re-resolves the callback precedence on every event (RESOLVED by the input-API redesign)

- **Where:** was `src/controller/projectInputController.lua`, `_generic_callback` — computed
  `compy_input[chan] or natives[event]` per dispatched event, then branched
  on whether a callback existed.
- **Old state:** The precedence (explicit `on_*` wins, else captured native, else
  noop) was fixed at `activate` but re-resolved on every dispatched event
  instead of once.
- **Resolution:** `_generic_callback` is gone. D-HOOKS-SEEDED
  replaced the two-store precedence rule with one table (`hooks[event]`), seeded once at
  `activate` (`seed_hooks`, `projectInputController.lua:43-49`) — there is
  no per-event resolution left to memoise; `dispatch` (`:74-86`) just reads
  `hooks[event]` directly.
- **Revisit:** None needed; carried here as resolved history, not deleted.

### Pointer delivery is an unstructured broadcast, not a chain (RESOLVED, 2026-08-03)

- **Resolution:** pointer joined the existing chain rather than getting a
  mirror of it (`../decisions/input.md`, D-ONE-LIFETIME). The gateway's pointer
  entries no longer deliver to the widget themselves; they hand the event to
  the active route like every other channel, and the widget is the chain's
  terminal. A pointer hook consumes on a truthy return, so a shown widget
  *can* now be starved of a click aimed past it — the capability this entry
  asked about.
- **What made it cheap in the end:** the owner's ruling that the
  keyboard/pointer split was self-inflicted rather than inherited (D-ROUTE-LIFETIME,
  amended). The consume contract itself cost nothing: measured across
  `life`, `sapper`, `tixy`, `paint` and `pong`, no project pointer handler
  returns a value, and the return was discarded in any case. So this was never
  the "two symmetrically mirrored chains" it was estimated as — one chain
  already existed and pointer simply entered it.
- **Still open, deliberately:** whether a shown widget should consume clicks
  **within its bounds** automatically. Nothing does bounds checks today; the
  chain gives a project the means to decide, which is a different answer from
  the framework deciding for it.
- **Also still open:** a pointer *combo* vocabulary (a modifier-only shortcut
  such as `ctrl` plus a button). Pointer has no shortcuts tier and enters the
  walk at the hook tier; D-ONE-LIFETIME records the question as not-decided.

### `UserInputController:keypressed` forked on `love.state.app_state == 'editor'` (RESOLVED — the `app_state` fork was removed, 2026-07-21)

- **Where:** was `src/controller/userInputController.lua:keypressed`, an
  `if love.state.app_state == 'editor' then … else … end` branch.
- **Old state:** A reusable input widget read global app-mode to change its own
  behaviour — both the editing keymap (order + Ctrl+D `modify`) and whether its
  Enter/Escape submit/cancel ran. Flagged by the owner (2026-07-20) as an
  abstraction leak: the widget could not be reasoned about — or migrated onto the
  new API by the editor later — without knowing it was "the editor." See
  `doc/development/decisions/input.md` D-NO-FW-TIER.
- **Resolution:** The branch is deleted; `keypressed` runs one uniform path. The
  two real differences moved to honest homes: (1) `modify` (Ctrl+D) is a
  per-instance `allow_duplicate_line` constructor flag, set only by the editor's input,
  mirroring `disable_selection`; (2) the editor consumes Enter/Escape **upstream**
  (`block_input()` in `EditorController:_normal_mode_keys`' `submit()`/`load()`),
  so the widget's uniform `submit_flow`/`cancel_flow` never runs for the keys the
  editor owns. No instance reads global mode. Suite green
  (`tests/input/input_widget_callbacks_spec.lua`, the `the same lifecycle on every route` group).
- **Revisit:** `allow_duplicate_line` is a one-off flag; the widget owning its own
  **combo table** (Ctrl+D and the lifecycle keys as registered combos an editor or
  project extends) is the better end-state the owner named — deferred with the
  console/editor migration (D-ROUTE-OWNS), not this pass. The former inline question
  at `:724` is retired (its concern is resolved
  in shape; the combo-table refinement is what remains).

### Comment wip-citation cleanup (RESOLVED, 2026-07-30)

Comments citing the feature's ephemeral wip tree instead of a canonical doc, in violation of
the `doc/development/conventions/code.md` "Comment References" rule. This entry recorded the
residue as two `src/controller/` comments; a pre-PR revalidation found **thirteen** comment
blocks across seven tracked files, four of them shipped examples under `src/examples/`.

All are rehomed: the controller comments to the `decisions/input.md` decisions they already
cited alongside the wip path, the examples to `doc/input_api.md`, "Submit lifecycle". Kept as
a resolved entry rather than deleted, because the undercount is the lesson — a debt row's
stated scope is a claim like any other, and this one was never re-measured after the tree
moved under it.

### An `update_prompt` endpoint was asked for and declined; `configure` already is one

- **Where:** `src/examples/balloons/terminal.lua` — an in-file remark asks the API to expose an
  *"update-prompt"* endpoint so a game can write its own welcome message when its mode switches.
- **Declined, 2026-08-11 (owner).** It is sugar over `compy.input.configure{ prompt = … }`, and a
  second path to a decorative change costs the surface's orthogonality, which is not ideal
  already. *At best it is a pattern to recommend, not a function to add.*
- **And the project already has it**, which is the part worth recording: `terminal_write(msg)` in
  that same file is one line over one `configure` call, exposed to the game as `write`. So the
  recommended shape is not hypothetical — it exists, in the example that asked for the endpoint.
- **The remark's other half — "three functions juggling each other" — is not the win it looks.**
  Two of the three are load-bearing: the handler slot is late-bound because `ui.lua` requires this
  file, and so activates the session, before `main.lua`'s router exists. Inlining the third
  (`deliver`, which joins submitted lines into the one string the game's handlers take) saves a
  function and costs the comment explaining why the join happens. Left alone deliberately.

### `userlove` does not convey its semantics (CLOSED — ruled to keep, 2026-08-03)

- **Ruling:** the name stays. Owner, 2026-08-03: *"I'd not rename userlove,
  its nice and makes no harm itself."* The rename was the last item of the
  deferred naming cluster; the rest of that cluster resolved by deletion
  rather than renaming (see the entries above).
- **What the reader needs instead, and now has in the code comment:**
  `userlove` is *a table indexed by love-event name holding the project's
  handlers*. Both callers pass one — `set_user_handlers` the sandboxed `love`
  table, `restore_user_handlers` the saved `Controller._userhandlers`. That
  second caller is why the once-proposed `project_love` was dropped: it would
  have been true at only one of the two entry points.
- **Kept as a closed entry rather than deleted** because the wrong candidate
  is the useful part of the record: anyone re-proposing `project_love` should
  find the reason it was refused.
- **Note (2026-08-03):** this entry used to also cover `forward_keypressed` /
  `forward_keyreleased` / `forward_textinput`. Those were **deleted, not
  renamed** — they implemented the console route's widget gate, which
  D-ROUTE-OWNS rules out ("widget visibility is state on the widget, never a
  routing condition"), and which was unreachable once the failed-run teardown
  was fixed. Its description here was also wrong on fact: it routed to the
  console route's active *widget*, not to "the currently-active keyboard
  route".

### The console's prompt is drawn under a project that never takes over `love.draw` (DISPUTABLE, ruled to keep 2026-08-07)

`ConsoleView:draw` paints the console's own input strip whenever the screen mode is not
`editor` (`src/view/consoleView.lua`, `drawConsole`). A project that replaces `love.draw`
never reaches that path — the gateway's draw wrapper calls the project's own draw instead
(`src/controller/controller.lua`, `set_love_update`). A project that draws **through the
console terminal** and defines no `love.draw` of its own does reach it, so the console's
prompt stays on screen for the whole run, inert: the input route belongs to the project, so
anything typed at that strip goes to the project, not to the prompt it appears to offer.

`src/examples/sapper` is the case in hand — it renders the minefield as terminal output and
binds only the derived clicks, so the strip sits under the game field for the entire session.
Surfaced by the owner's smoke test as *"any chance to not show inactive console input at the
bottom?"*.

**Ruled to keep as-is (owner, 2026-08-07):** the console's drawing logic is not to be
conditioned on what a project happens to draw, for the cosmetic benefit of one pen-and-paper
example. The gate would have to distinguish "a project owns the input route" from "the console
is interactive again" — `inspect` being the second — which puts project-lifecycle knowledge
into a view whose job is to paint the console.

**Cost of leaving it:** the strip reads as an available prompt while it is not one. **Cost of
fixing it:** a state test in the view, invisible to the suite — the input fixture stubs the
`view.view` module wholesale, so `ConsoleView:draw` is not exercised by any row, and the fix
would be verifiable only by a human smoke test. Revisit if a project owner asks.
